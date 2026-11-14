extends Node
class_name EnemyChaseController
## Local steering toward a coordinated approach slot, or away from a target while retreating.
@export var enemy_ai_controller_path: NodePath = NodePath("../EnemyAIController")
@export var navigation_agent_path: NodePath = NodePath("../NavigationAgent3D")
@export_range(0.1, 20.0, 0.1) var move_speed: float = 3.5
@export_range(0.1, 10.0, 0.1) var preferred_attack_distance: float = 1.6
@export_range(0.0, 20.0, 0.1) var stopping_tolerance: float = 0.25
@export_range(0.1, 20.0, 0.1) var acceleration: float = 12.0
@export_range(0.1, 30.0, 0.1) var turn_speed: float = 10.0
@export_range(0.02, 1.0, 0.01) var navigation_repath_seconds: float = 0.2
@export var engagement_policy: EnemyArchetypeProfile.EngagementPolicy = EnemyArchetypeProfile.EngagementPolicy.PURSUER
@export_range(0.0, 1.0, 0.05) var strafe_speed_ratio: float = 0.45

var _actor: CharacterBody3D
var _ai: EnemyAIController
var _agent: NavigationAgent3D
var _repath_remaining: float = 0.0

func _ready() -> void:
	_actor = get_parent() as CharacterBody3D
	_ai = get_node_or_null(enemy_ai_controller_path) as EnemyAIController
	_agent = get_node_or_null(navigation_agent_path) as NavigationAgent3D
	if _actor == null:
		push_warning("EnemyChaseController parent must be CharacterBody3D.")
	if _ai == null:
		push_warning("EnemyChaseController requires EnemyAIController.")

func _physics_process(delta: float) -> void:
	update_steering(delta)

func update_steering(delta: float) -> Vector3:
	if delta <= 0.0 or _actor == null or _ai == null:
		return Vector3.ZERO
	if not is_instance_valid(_ai.target):
		_brake(delta)
		return Vector3.ZERO
	if _ai.current_state == EnemyAIController.State.RETREAT:
		return _retreat_steering(delta)
	if _ai.current_state != EnemyAIController.State.CHASE:
		_brake(delta)
		return Vector3.ZERO
	var destination := _ai.target.global_position
	if _ai.has_squad_coordinator():
		var coordinator := _get_coordinator()
		if coordinator != null:
			destination = coordinator.get_approach_position(_actor, _ai.target, _ai.assigned_tactical_role, preferred_attack_distance)
	return _steer_to_destination(destination, delta)

func _retreat_steering(delta: float) -> Vector3:
	var away := _actor.global_position - _ai.target.global_position
	away.y = 0.0
	var distance := away.length()
	if distance >= _ai.retreat_distance:
		_brake(delta)
		_ai.complete_retreat()
		return Vector3.ZERO
	if away.length_squared() < 0.0001:
		away = Vector3.BACK
	var desired := away.normalized() * move_speed
	_face_direction(desired, delta)
	_apply_horizontal_velocity(desired, delta)
	return desired

func _steer_to_destination(destination: Vector3, delta: float) -> Vector3:
	var offset := destination - _actor.global_position
	offset.y = 0.0
	if offset.length() <= stopping_tolerance:
		_brake(delta)
		return Vector3.ZERO
	_repath_remaining -= delta
	var direction := Vector3.ZERO
	if _agent != null and _agent.get_navigation_map().is_valid():
		if _repath_remaining <= 0.0:
			_agent.target_position = destination
			_repath_remaining = navigation_repath_seconds
		if not _agent.is_navigation_finished():
			direction = _agent.get_next_path_position() - _actor.global_position
			direction.y = 0.0
	else:
		direction = offset
	if direction.length_squared() > 0.0001:
		direction = direction.normalized()
		_face_direction(direction, delta)
	var desired := direction * move_speed
	_apply_horizontal_velocity(desired, delta)
	return desired

func _get_coordinator() -> EnemySquadCoordinator:
	return _ai.get_squad_coordinator() if _ai != null else null

func _apply_horizontal_velocity(desired: Vector3, delta: float) -> void:
	var horizontal := Vector3(_actor.velocity.x, 0.0, _actor.velocity.z)
	horizontal = horizontal.move_toward(desired, acceleration * delta)
	_actor.velocity.x = horizontal.x
	_actor.velocity.z = horizontal.z
	_actor.move_and_slide()

func _brake(delta: float) -> void:
	_apply_horizontal_velocity(Vector3.ZERO, delta)

func _face_direction(direction: Vector3, delta: float) -> void:
	if direction.length_squared() <= 0.0001:
		return
	var desired_yaw := atan2(-direction.x, -direction.z)
	_actor.rotation.y = lerp_angle(_actor.rotation.y, desired_yaw, clampf(turn_speed * delta, 0.0, 1.0))
