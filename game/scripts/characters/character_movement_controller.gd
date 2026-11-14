extends Node
class_name CharacterMovementController
## Deterministic RR-003 movement component for CharacterActor.

signal grounded_changed(is_grounded: bool)
signal lane_changed(lane_index: int)

enum MovementMode { LANE, FREE }

@export var movement_mode: MovementMode = MovementMode.LANE
@export_range(1, 9, 2) var lane_count: int = 3
@export_range(0.5, 10.0, 0.1) var lane_width: float = 2.0
@export_range(0.1, 30.0, 0.1) var acceleration: float = 18.0
@export_range(0.1, 40.0, 0.1) var braking: float = 24.0
@export_range(0.1, 30.0, 0.1) var lateral_speed: float = 10.0
@export_range(0.1, 20.0, 0.1) var jump_velocity: float = 6.5
@export_range(0.1, 40.0, 0.1) var gravity: float = 18.0

var lane_index: int = 1
var is_grounded: bool = false
var _move_intent: Vector2 = Vector2.ZERO
var _jump_requested: bool = false
var _camera_basis: Basis = Basis.IDENTITY
var _actor: CharacterBody3D


func _ready() -> void:
	_actor = get_parent() as CharacterBody3D
	if _actor == null:
		push_error("CharacterMovementController must be a child of CharacterBody3D.")
		return
	var errors: PackedStringArray = validate_configuration()
	if not errors.is_empty():
		push_error("Invalid movement configuration: %s" % "; ".join(errors))
		return
	lane_index = int(lane_count / 2)


func validate_configuration() -> PackedStringArray:
	var errors := PackedStringArray()
	if lane_count < 1 or lane_count % 2 == 0:
		errors.append("lane_count must be a positive odd number.")
	if lane_width <= 0.0:
		errors.append("lane_width must be greater than zero.")
	if acceleration <= 0.0 or braking <= 0.0 or lateral_speed <= 0.0:
		errors.append("acceleration, braking and lateral_speed must be greater than zero.")
	if jump_velocity <= 0.0 or gravity <= 0.0:
		errors.append("jump_velocity and gravity must be greater than zero.")
	return errors


## Returns a detached snapshot for animation/presentation consumers.
## The snapshot is observational: mutating it cannot change movement or actor state.
func get_animation_state() -> CharacterAnimationState:
	if _actor == null:
		return CharacterAnimationState.new(
			Vector3.ZERO,
			0.0,
			is_grounded,
			movement_mode,
			Basis.IDENTITY
		)
	var planar_velocity := Vector3(_actor.velocity.x, 0.0, _actor.velocity.z)
	return CharacterAnimationState.new(
		planar_velocity,
		_actor.velocity.y,
		is_grounded,
		movement_mode,
		_actor.global_transform.basis
	)


func set_move_intent(intent: Vector2) -> void:
	_move_intent = intent.limit_length(1.0)


func set_camera_basis(camera_basis: Basis) -> void:
	_camera_basis = camera_basis


func request_jump() -> void:
	_jump_requested = true


func request_lane_change(direction: int) -> void:
	if movement_mode != MovementMode.LANE or direction == 0:
		return
	var next_lane := clampi(lane_index + signi(direction), 0, lane_count - 1)
	if next_lane != lane_index:
		lane_index = next_lane
		lane_changed.emit(lane_index)


func _physics_process(delta: float) -> void:
	physics_step(delta)


func physics_step(delta: float) -> void:
	if _actor == null or delta <= 0.0:
		return
	var was_grounded := is_grounded
	is_grounded = _actor.is_on_floor()
	if is_grounded and _actor.velocity.y < 0.0:
		_actor.velocity.y = 0.0
	if _jump_requested and is_grounded:
		_actor.velocity.y = jump_velocity
		is_grounded = false
	_jump_requested = false
	if not is_grounded:
		_actor.velocity.y -= gravity * delta

	var speed := _get_run_speed()
	if movement_mode == MovementMode.LANE:
		var center_lane := int(lane_count / 2)
		var target_x := float(lane_index - center_lane) * lane_width
		var next_x := move_toward(_actor.global_position.x, target_x, lateral_speed * delta)
		_actor.velocity.x = (next_x - _actor.global_position.x) / delta
		_actor.velocity.z = -speed
	else:
		var local_direction := Vector3(_move_intent.x, 0.0, -_move_intent.y)
		var world_direction := _camera_basis * local_direction
		world_direction.y = 0.0
		world_direction = world_direction.normalized()
		var target_velocity := world_direction * speed
		var rate := acceleration if not world_direction.is_zero_approx() else braking
		_actor.velocity.x = move_toward(_actor.velocity.x, target_velocity.x, rate * delta)
		_actor.velocity.z = move_toward(_actor.velocity.z, target_velocity.z, rate * delta)

	_actor.move_and_slide()
	is_grounded = _actor.is_on_floor()
	if was_grounded != is_grounded:
		grounded_changed.emit(is_grounded)


func _get_run_speed() -> float:
	var character_actor := _actor as CharacterActor
	if character_actor != null and character_actor.definition != null:
		if character_actor.definition.stats != null:
			return character_actor.definition.stats.movement_speed
	return 5.0
