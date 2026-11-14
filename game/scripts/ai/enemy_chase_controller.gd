extends Node
class_name EnemyChaseController
## Local chase steering. Uses NavigationAgent3D when configured, otherwise direct steering.
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
	if _actor == null: push_warning("EnemyChaseController parent must be CharacterBody3D.")
	if _ai == null: push_warning("EnemyChaseController requires EnemyAIController.")

func _physics_process(delta: float) -> void:
	update_steering(delta)

func update_steering(delta: float) -> Vector3:
	if delta <= 0.0 or _actor == null or _ai == null: return Vector3.ZERO
	if not is_instance_valid(_ai.target) or _ai.current_state == EnemyAIController.State.DEAD or _ai.current_state == EnemyAIController.State.STAGGERED:
		_brake(delta)
		return Vector3.ZERO
	var target_position := _ai.target.global_position
	if _ai.current_state == EnemyAIController.State.RETREAT:
		var away := _actor.global_position - target_position
		away.y = 0.0
		away = away.normalized() if away.length_squared() > 0.0001 else -_actor.global_transform.basis.z
		_face_direction(away, delta)
		var retreat_velocity := away * move_speed
		_apply_horizontal_velocity(retreat_velocity, delta)
		return retreat_velocity
	if _ai.current_state != EnemyAIController.State.CHASE:
		_brake(delta)
		return Vector3.ZERO
	var offset := target_position - _actor.global_position
	offset.y = 0.0
	var distance := offset.length()
	if distance <= preferred_attack_distance + stopping_tolerance:
		_face_direction(offset, delta)
		if engagement_policy == EnemyArchetypeProfile.EngagementPolicy.SKIRMISHER and distance > 0.1:
			var tangent := Vector3(-offset.z, 0.0, offset.x).normalized()
			var desired_strafe := tangent * move_speed * strafe_speed_ratio
			_apply_horizontal_velocity(desired_strafe, delta)
			return desired_strafe
		_brake(delta)
		return Vector3.ZERO
	_repath_remaining -= delta
	var direction := Vector3.ZERO
	if _agent != null and _agent.get_navigation_map().is_valid():
		if _repath_remaining <= 0.0:
			_agent.target_position = target_position
			_repath_remaining = navigation_repath_seconds
		if not _agent.is_navigation_finished():
			var next_position := _agent.get_next_path_position()
			direction = next_position - _actor.global_position
			direction.y = 0.0
	else:
		direction = offset
	if direction.length_squared() > 0.0001:
		direction = direction.normalized()
		_face_direction(direction, delta)
	var desired := direction * move_speed
	_apply_horizontal_velocity(desired, delta)
	return desired

func _apply_horizontal_velocity(desired: Vector3, delta: float) -> void:
	var horizontal := Vector3(_actor.velocity.x, 0.0, _actor.velocity.z)
	horizontal = horizontal.move_toward(desired, acceleration * delta)
	_actor.velocity.x = horizontal.x
	_actor.velocity.z = horizontal.z
	_actor.move_and_slide()

func _brake(delta: float) -> void:
	if _actor == null: return
	_apply_horizontal_velocity(Vector3.ZERO, delta)

func _face_direction(direction: Vector3, delta: float) -> void:
	if direction.length_squared() <= 0.0001: return
	var desired_yaw := atan2(-direction.x, -direction.z)
	_actor.rotation.y = lerp_angle(_actor.rotation.y, desired_yaw, clampf(turn_speed * delta, 0.0, 1.0))
