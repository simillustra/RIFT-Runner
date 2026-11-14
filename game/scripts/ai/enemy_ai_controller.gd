extends Node
class_name EnemyAIController
## Deterministic local enemy state machine. Perception and locomotion are injected in later milestones.
signal state_changed(previous_state: int, current_state: int)
signal target_changed(target: Node3D)
signal attack_requested
enum State { IDLE, ALERT, CHASE, ATTACK, STAGGERED, DEAD }
@export var health_component_path: NodePath = NodePath("../HealthComponent")
@export var enemy_combat_controller_path: NodePath = NodePath("../EnemyCombatController")
@export var combat_reaction_controller_path: NodePath = NodePath("../CombatReactionController")
@export var attack_executor_path: NodePath = NodePath("../AttackExecutor")
@export var squad_coordinator_path: NodePath
@export_range(0.5, 100.0, 0.1) var detection_range: float = 12.0
@export_range(0.5, 100.0, 0.1) var attack_range: float = 2.0
@export_range(0.5, 150.0, 0.1) var lose_target_range: float = 18.0
@export_range(0.05, 2.0, 0.01) var failed_attack_retry_seconds: float = 0.25
var current_state: int = State.IDLE
var target: Node3D
var _health: HealthComponent
var _combat: EnemyCombatController
var _reactions: CombatReactionController
var _executor: AttackExecutor
var _squad_coordinator: EnemySquadCoordinator
var _attack_slot_reserved: bool = false
var _attack_retry_remaining: float = 0.0
var _stagger_remaining: float = 0.0

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
	if _health == null:
		push_warning("EnemyAIController requires a HealthComponent at '%s'." % health_component_path)
	else:
		_health.died.connect(_on_health_died)
	if attack_range > detection_range:
		push_warning("EnemyAIController attack_range should not exceed detection_range.")
	if lose_target_range < detection_range:
		push_warning("EnemyAIController lose_target_range should be at least detection_range.")

func assign_squad_coordinator(coordinator: EnemySquadCoordinator) -> void:
	if _attack_slot_reserved:
		_release_attack_slot()
	_squad_coordinator = coordinator

func has_squad_coordinator() -> bool:
	return is_instance_valid(_squad_coordinator)

func set_target(next_target: Node3D) -> void:
	if current_state == State.DEAD or not is_instance_valid(next_target):
		return
	if target == next_target:
		return
	_release_attack_slot()
	if _executor != null:
		_executor.cancel_attack()
	target = next_target
	target_changed.emit(target)
	if current_state == State.IDLE:
		_transition_to(State.ALERT)

func clear_target() -> void:
	if target == null:
		return
	_release_attack_slot()
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
		_stagger_remaining = maxf(duration_seconds, 0.0)
		_release_attack_slot()
		if _executor != null:
			_executor.cancel_attack()
		_transition_to(State.STAGGERED)
	elif current_state == State.STAGGERED:
		_stagger_remaining = 0.0
		_transition_to(State.ALERT if is_instance_valid(target) else State.IDLE)

func set_dead() -> void:
	if current_state == State.DEAD:
		return
	_release_attack_slot()
	if _executor != null:
		_executor.cancel_attack()
	target = null
	target_changed.emit(null)
	_transition_to(State.DEAD)

## Public deterministic decision step, also called by _physics_process.
func update_decision(delta: float) -> void:
	if delta <= 0.0 or current_state == State.DEAD:
		return
	if current_state == State.STAGGERED:
		if _stagger_remaining > 0.0:
			_stagger_remaining = maxf(_stagger_remaining - delta, 0.0)
			if _stagger_remaining <= 0.0:
				set_staggered(false)
		return
	_attack_retry_remaining = maxf(_attack_retry_remaining - delta, 0.0)
	if is_instance_valid(_health) and _health.is_dead:
		set_dead()
		return
	if not is_instance_valid(target):
		clear_target()
		return
	var distance := _get_target_distance()
	if distance > lose_target_range:
		clear_target()
		return
	if distance > detection_range:
		if current_state == State.IDLE:
			return
		_transition_to(State.ALERT)
		return
	if distance <= attack_range:
		_transition_to(State.ATTACK)
		_try_request_attack()
	else:
		_transition_to(State.CHASE)

func _physics_process(delta: float) -> void:
	update_decision(delta)

func _get_target_distance() -> float:
	var actor := get_parent() as Node3D
	if actor == null or not is_instance_valid(target):
		return INF
	return actor.global_position.distance_to(target.global_position)

func _try_request_attack() -> void:
	if _attack_retry_remaining > 0.0 or _combat == null:
		return
	if _squad_coordinator != null and not _attack_slot_reserved:
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
	if not _attack_slot_reserved:
		return
	if _squad_coordinator != null:
		_squad_coordinator.release_attack_slot(get_parent() as Node3D)
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
