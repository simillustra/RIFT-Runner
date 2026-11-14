extends Node
class_name EnemyAIController
## Deterministic local enemy state machine with encounter-scoped tactical coordination.
signal state_changed(previous_state: int, current_state: int)
signal target_changed(target: Node3D)
signal attack_requested

enum State { IDLE, ALERT, CHASE, ATTACK, STAGGERED, RETREAT, DEAD }

@export var health_component_path: NodePath = NodePath("../HealthComponent")
@export var enemy_combat_controller_path: NodePath = NodePath("../EnemyCombatController")
@export var combat_reaction_controller_path: NodePath = NodePath("../CombatReactionController")
@export var attack_executor_path: NodePath = NodePath("../AttackExecutor")
@export var squad_coordinator_path: NodePath
@export_range(0.5, 100.0, 0.1) var detection_range: float = 12.0
@export_range(0.5, 100.0, 0.1) var attack_range: float = 2.0
@export_range(0.5, 150.0, 0.1) var lose_target_range: float = 18.0
@export_range(0.05, 2.0, 0.01) var failed_attack_retry_seconds: float = 0.25
@export_range(0.0, 1.0, 0.01) var retreat_health_ratio: float = 0.3
@export_range(1.0, 40.0, 0.5) var retreat_distance: float = 8.0
@export_range(0.0, 5.0, 0.1) var retreat_recovery_seconds: float = 1.0
@export var retreat_enabled: bool = true

var current_state: int = State.IDLE
var target: Node3D
var assigned_tactical_role: int = EnemySquadCoordinator.TacticalRole.PURSUER
var _health: HealthComponent
var _combat: EnemyCombatController
var _reactions: CombatReactionController
var _executor: AttackExecutor
var _squad_coordinator: EnemySquadCoordinator
var _attack_slot_reserved: bool = false
var _attack_retry_remaining: float = 0.0
var _stagger_remaining: float = 0.0
var _state_before_stagger: int = State.IDLE
var _retreat_recovery_remaining: float = 0.0
var _retreat_used: bool = false

func _ready() -> void:
	_health = get_node_or_null(health_component_path) as HealthComponent
	_combat = get_node_or_null(enemy_combat_controller_path) as EnemyCombatController
	_reactions = get_node_or_null(combat_reaction_controller_path) as CombatReactionController
	_executor = get_node_or_null(attack_executor_path) as AttackExecutor
	_squad_coordinator = get_node_or_null(squad_coordinator_path) as EnemySquadCoordinator
	if _executor != null:
		_executor.attack_finished.connect(_on_attack_finished)
	if _reactions != null:
		_reactions.stagger_started.connect(_on_reaction_stagger_started)
		_reactions.death_presented.connect(set_dead)
	if _health != null:
		_health.died.connect(_on_health_died)
	else:
		push_warning("EnemyAIController requires a HealthComponent at '%s'." % health_component_path)

func reset_for_spawn() -> void:
	_release_attack_slot()
	if is_instance_valid(_squad_coordinator):
		_squad_coordinator.release_member_claims(get_parent() as Node3D)
	target = null
	_attack_retry_remaining = 0.0
	_stagger_remaining = 0.0
	_state_before_stagger = State.IDLE
	_retreat_recovery_remaining = 0.0
	_retreat_used = false
	_transition_to(State.IDLE)

func assign_squad_coordinator(coordinator: EnemySquadCoordinator, engagement_policy: int = 0) -> void:
	var actor := get_parent() as Node3D
	if is_instance_valid(_squad_coordinator) and _squad_coordinator != coordinator and actor != null:
		_squad_coordinator.unregister_member(actor)
	_squad_coordinator = coordinator
	if is_instance_valid(_squad_coordinator) and actor != null:
		assigned_tactical_role = _squad_coordinator.register_member(actor, engagement_policy)
	else:
		assigned_tactical_role = EnemySquadCoordinator.TacticalRole.PURSUER

func has_squad_coordinator() -> bool:
	return is_instance_valid(_squad_coordinator)

func get_squad_coordinator() -> EnemySquadCoordinator:
	return _squad_coordinator if is_instance_valid(_squad_coordinator) else null

func set_target(next_target: Node3D) -> void:
	if current_state == State.DEAD or not is_instance_valid(next_target):
		return
	if target == next_target:
		return
	_release_tactical_target_claims()
	if _executor != null:
		_executor.cancel_attack()
	target = next_target
	target_changed.emit(target)
	if current_state == State.IDLE:
		_transition_to(State.ALERT)

func clear_target() -> void:
	var actor := get_parent() as Node3D
	var has_claims := is_instance_valid(_squad_coordinator) and actor != null and _squad_coordinator.has_member_claims(actor)
	if target == null and not _attack_slot_reserved and not has_claims:
		return
	_release_tactical_target_claims()
	if _executor != null:
		_executor.cancel_attack()
	target = null
	target_changed.emit(null)
	if current_state != State.DEAD and current_state != State.STAGGERED:
		_transition_to(State.IDLE)

func set_staggered(staggered: bool, duration_seconds: float = 0.0) -> void:
	if current_state == State.DEAD:
		return
	if staggered:
		if current_state != State.STAGGERED:
			_state_before_stagger = current_state
		_stagger_remaining = maxf(duration_seconds, 0.0)
		_release_attack_slot()
		if _executor != null:
			_executor.cancel_attack()
		_transition_to(State.STAGGERED)
	elif current_state == State.STAGGERED:
		_stagger_remaining = 0.0
		var resume_state := _state_before_stagger
		if resume_state == State.DEAD or resume_state == State.STAGGERED:
			resume_state = State.ALERT if is_instance_valid(target) else State.IDLE
		if resume_state != State.RETREAT and is_instance_valid(target):
			resume_state = State.ALERT
		_transition_to(resume_state)

func set_dead() -> void:
	if current_state == State.DEAD:
		return
	_release_tactical_target_claims()
	var actor := get_parent() as Node3D
	if is_instance_valid(_squad_coordinator) and actor != null:
		_squad_coordinator.unregister_member(actor)
	if _executor != null:
		_executor.cancel_attack()
	target = null
	target_changed.emit(null)
	_transition_to(State.DEAD)

func complete_retreat() -> void:
	if current_state != State.RETREAT:
		return
	var actor := get_parent() as Node3D
	if is_instance_valid(_squad_coordinator) and actor != null and is_instance_valid(target):
		_squad_coordinator.set_member_retreating(actor, target, false)
	_retreat_recovery_remaining = retreat_recovery_seconds
	_transition_to(State.ALERT)
	if _retreat_recovery_remaining <= 0.0 and is_instance_valid(target):
		_transition_to(State.CHASE)

func update_decision(delta: float) -> void:
	if delta <= 0.0 or current_state == State.DEAD:
		return
	if current_state == State.STAGGERED:
		_stagger_remaining = maxf(_stagger_remaining - delta, 0.0)
		if _stagger_remaining <= 0.0:
			set_staggered(false)
		return
	if current_state == State.RETREAT:
		if not is_instance_valid(target):
			clear_target()
			return
		if _get_target_distance() >= retreat_distance:
			complete_retreat()
		return
	if _retreat_recovery_remaining > 0.0:
		_retreat_recovery_remaining = maxf(_retreat_recovery_remaining - delta, 0.0)
		if _retreat_recovery_remaining <= 0.0 and is_instance_valid(target):
			_transition_to(State.CHASE)
		return
	_attack_retry_remaining = maxf(_attack_retry_remaining - delta, 0.0)
	if is_instance_valid(_health) and _health.is_dead:
		set_dead()
		return
	if not is_instance_valid(target):
		clear_target()
		return
	if retreat_enabled and not _retreat_used and is_instance_valid(_health) and _health.get_health_ratio() <= retreat_health_ratio:
		_begin_retreat()
		return
	var distance := _get_target_distance()
	if distance > lose_target_range:
		clear_target()
		return
	if distance > detection_range:
		if current_state != State.IDLE:
			_transition_to(State.ALERT)
		return
	if distance <= attack_range:
		_transition_to(State.ATTACK)
		_try_request_attack()
	else:
		_transition_to(State.CHASE)

func _physics_process(delta: float) -> void:
	update_decision(delta)

func _begin_retreat() -> void:
	_retreat_used = true
	_release_attack_slot()
	if _executor != null:
		_executor.cancel_attack()
	var actor := get_parent() as Node3D
	if is_instance_valid(_squad_coordinator) and actor != null and is_instance_valid(target):
		_squad_coordinator.release_target_claim(actor)
		_squad_coordinator.set_member_retreating(actor, target, true)
	_transition_to(State.RETREAT)

func _get_target_distance() -> float:
	var actor := get_parent() as Node3D
	if actor == null or not is_instance_valid(target):
		return INF
	return actor.global_position.distance_to(target.global_position)

func _try_request_attack() -> void:
	if _attack_retry_remaining > 0.0 or _combat == null:
		return
	if is_instance_valid(_squad_coordinator) and not _attack_slot_reserved:
		if not _squad_coordinator.request_attack_slot(get_parent() as Node3D, target):
			_attack_retry_remaining = failed_attack_retry_seconds
			return
		_attack_slot_reserved = true
	var result := _combat.request_attack()
	if result == OK:
		attack_requested.emit()
		_attack_retry_remaining = 0.25
	else:
		_release_attack_slot()
		_attack_retry_remaining = failed_attack_retry_seconds

func _on_attack_finished(_definition: AttackDefinition) -> void:
	_release_attack_slot()

func _release_attack_slot() -> void:
	if is_instance_valid(_squad_coordinator):
		_squad_coordinator.release_attack_slot(get_parent() as Node3D)
	_attack_slot_reserved = false

func _release_tactical_target_claims() -> void:
	if is_instance_valid(_squad_coordinator):
		_squad_coordinator.release_member_claims(get_parent() as Node3D)
	_attack_slot_reserved = false

func _transition_to(next_state: int) -> void:
	if current_state == next_state:
		return
	var previous_state := current_state
	current_state = next_state
	state_changed.emit(previous_state, current_state)

func _on_health_died(_source: Node) -> void:
	set_dead()

func _on_reaction_stagger_started(duration: float) -> void:
	set_staggered(true, duration)
