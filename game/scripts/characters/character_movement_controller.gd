extends Node
class_name CharacterMovementController
## Deterministic RR-003 movement component for CharacterActor.

signal grounded_changed(is_grounded: bool)
signal lane_changed(lane_index: int)
signal stagger_started(duration: float)
signal stagger_ended

enum MovementMode { LANE, FREE }

@export var movement_mode: MovementMode = MovementMode.LANE
@export_range(1, 9, 2) var lane_count: int = 3
@export_range(0.5, 10.0, 0.1) var lane_width: float = 2.0
@export_range(0.1, 30.0, 0.1) var acceleration: float = 18.0
@export_range(0.1, 40.0, 0.1) var braking: float = 24.0
@export_range(0.1, 30.0, 0.1) var lateral_speed: float = 10.0
@export_range(0.1, 20.0, 0.1) var jump_velocity: float = 6.5
@export_range(0.1, 40.0, 0.1) var gravity: float = 18.0
@export_range(1.0, 40.0, 0.1) var combat_impulse_decay: float = 14.0

var lane_index: int = 1
var is_grounded: bool = false
var is_dead: bool = false
var _move_intent: Vector2 = Vector2.ZERO
var _jump_requested: bool = false
var _camera_basis: Basis = Basis.IDENTITY
var _actor: CharacterBody3D
var _combat_impulse: Vector3 = Vector3.ZERO
var _stagger_remaining: float = 0.0
var _is_operational: bool = false
var _ownership_warning_emitted: bool = false


func _ready() -> void:
	_actor = get_parent() as CharacterBody3D
	if _actor == null:
		push_warning("CharacterMovementController disabled: it must be a direct child of CharacterBody3D.")
		return
	var errors: PackedStringArray = validate_configuration()
	if not errors.is_empty():
		push_warning("CharacterMovementController disabled by invalid configuration: %s" % "; ".join(errors))
		return
	lane_index = int(lane_count / 2)
	_is_operational = true


## Returns actionable configuration errors without mutating controller state.
func validate_configuration() -> PackedStringArray:
	var errors := PackedStringArray()
	if movement_mode != MovementMode.LANE and movement_mode != MovementMode.FREE:
		errors.append("movement_mode must be LANE or FREE.")
	if lane_count < 1 or lane_count % 2 == 0:
		errors.append("lane_count must be a positive odd number.")
	if not is_finite(lane_width) or lane_width <= 0.0:
		errors.append("lane_width must be finite and greater than zero.")
	if not is_finite(acceleration) or acceleration <= 0.0:
		errors.append("acceleration must be finite and greater than zero.")
	if not is_finite(braking) or braking <= 0.0:
		errors.append("braking must be finite and greater than zero.")
	if not is_finite(lateral_speed) or lateral_speed <= 0.0:
		errors.append("lateral_speed must be finite and greater than zero.")
	if not is_finite(jump_velocity) or jump_velocity <= 0.0:
		errors.append("jump_velocity must be finite and greater than zero.")
	if not is_finite(gravity) or gravity <= 0.0:
		errors.append("gravity must be finite and greater than zero.")
	if not is_finite(combat_impulse_decay) or combat_impulse_decay <= 0.0:
		errors.append("combat_impulse_decay must be finite and greater than zero.")
	return errors


func is_operational() -> bool:
	return _is_operational and _has_valid_actor_ownership()


func _has_valid_actor_ownership() -> bool:
	return is_instance_valid(_actor) and get_parent() == _actor


func get_animation_state() -> CharacterAnimationState:
	if not is_operational():
		return CharacterAnimationState.new(Vector3.ZERO, 0.0, is_grounded, movement_mode, Basis.IDENTITY)
	var planar_velocity := Vector3(_actor.velocity.x, 0.0, _actor.velocity.z)
	return CharacterAnimationState.new(planar_velocity, _actor.velocity.y, is_grounded, movement_mode, _actor.global_transform.basis)


func set_move_intent(intent: Vector2) -> void:
	_move_intent = intent.limit_length(1.0)


func set_camera_basis(camera_basis: Basis) -> void:
	_camera_basis = camera_basis


func request_jump() -> void:
	if not is_dead and _stagger_remaining <= 0.0:
		_jump_requested = true


func request_lane_change(direction: int) -> void:
	if is_dead or _stagger_remaining > 0.0 or movement_mode != MovementMode.LANE or direction == 0:
		return
	var next_lane := clampi(lane_index + signi(direction), 0, lane_count - 1)
	if next_lane != lane_index:
		lane_index = next_lane
		lane_changed.emit(lane_index)


## Adds a world-space combat impulse and temporarily suppresses locomotion intent.
func apply_combat_impulse(impulse: Vector3, stagger_seconds: float) -> void:
	if is_dead or not is_operational():
		return
	_combat_impulse += Vector3(impulse.x, 0.0, impulse.z)
	_stagger_remaining = maxf(_stagger_remaining, maxf(stagger_seconds, 0.0))
	if stagger_seconds > 0.0:
		_jump_requested = false
		stagger_started.emit(_stagger_remaining)


func set_dead() -> void:
	is_dead = true
	_stagger_remaining = 0.0
	_combat_impulse = Vector3.ZERO
	_move_intent = Vector2.ZERO
	_jump_requested = false
	if is_operational():
		_actor.velocity = Vector3.ZERO


func get_stagger_remaining() -> float:
	return _stagger_remaining


func get_combat_impulse() -> Vector3:
	return _combat_impulse


func _physics_process(delta: float) -> void:
	physics_step(delta)


## Invalid/non-positive time steps and invalid ownership are safe no-ops.
func physics_step(delta: float) -> void:
	if not is_finite(delta) or delta <= 0.0 or is_dead or not _is_operational:
		return
	if not _has_valid_actor_ownership():
		_is_operational = false
		if not _ownership_warning_emitted:
			push_warning("CharacterMovementController disabled: its CharacterBody3D owner is no longer its direct parent.")
			_ownership_warning_emitted = true
		return
	var was_grounded := is_grounded
	is_grounded = _actor.is_on_floor()
	if is_grounded and _actor.velocity.y < 0.0:
		_actor.velocity.y = 0.0
	if not is_grounded:
		_actor.velocity.y -= gravity * delta

	# Jump requests are consumed on the next physics tick. Only a grounded
	# character may launch; airborne requests are discarded (no double jump).
	if _jump_requested:
		if is_grounded:
			_actor.velocity.y = jump_velocity
		_jump_requested = false

	if _stagger_remaining > 0.0:
		_stagger_remaining = maxf(_stagger_remaining - delta, 0.0)
		_actor.velocity.x = _combat_impulse.x
		_actor.velocity.z = _combat_impulse.z
		_combat_impulse = _combat_impulse.move_toward(Vector3.ZERO, combat_impulse_decay * delta)
		_actor.move_and_slide()
		is_grounded = _actor.is_on_floor()
		if _stagger_remaining <= 0.0:
			stagger_ended.emit()
		if was_grounded != is_grounded:
			grounded_changed.emit(is_grounded)
		return

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
	_actor.velocity.x += _combat_impulse.x
	_actor.velocity.z += _combat_impulse.z
	_combat_impulse = _combat_impulse.move_toward(Vector3.ZERO, combat_impulse_decay * delta)
	_actor.move_and_slide()
	is_grounded = _actor.is_on_floor()
	if was_grounded != is_grounded:
		grounded_changed.emit(is_grounded)


func _get_run_speed() -> float:
	var character_actor := _actor as CharacterActor
	if character_actor != null and character_actor.definition != null and character_actor.definition.stats != null:
		return character_actor.definition.stats.movement_speed
	return 5.0
