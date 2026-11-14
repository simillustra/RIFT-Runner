extends Node
class_name CharacterAnimationController
## Presentation-only bridge from movement snapshots to the shared AnimationTree graph.
## This node never writes to CharacterMovementController or CharacterBody3D.

@export var movement_controller: CharacterMovementController
@export var animation_tree: AnimationTree
@export var animation_player: AnimationPlayer
@export var animation_profile: AnimationProfile
@export_range(0.0, 1.0, 0.01) var jump_start_hold_seconds: float = 0.12
@export_range(0.0, 1.0, 0.01) var landing_hold_seconds: float = 0.12
@export_range(0.05, 2.0, 0.01) var hit_react_default_seconds: float = 0.35

var _playback: AnimationNodeStateMachinePlayback
var _was_grounded: bool = false
var _has_grounded_sample: bool = false
var _jump_start_remaining: float = 0.0
var _landing_remaining: float = 0.0
var _hit_react_remaining: float = 0.0
var _current_state: StringName = &""
var _initialized: bool = false


func _ready() -> void:
	var errors := validate_configuration()
	if not errors.is_empty():
		push_error("CharacterAnimationController configuration invalid: %s" % "; ".join(errors))
		return

	var clip_names := animation_player.get_animation_list()
	errors = animation_profile.validate(clip_names)
	if not errors.is_empty():
		push_error("CharacterAnimationController profile invalid: %s" % "; ".join(errors))
		return

	animation_tree.tree_root = CharacterAnimationGraph.create_state_machine(animation_profile)
	if animation_tree.tree_root == null:
		push_error("CharacterAnimationController could not create its AnimationTree graph.")
		return
	animation_tree.active = true
	_initialized = true


func validate_configuration() -> PackedStringArray:
	var errors := PackedStringArray()
	if movement_controller == null:
		errors.append("movement_controller is required.")
	if animation_tree == null:
		errors.append("animation_tree is required.")
	if animation_player == null:
		errors.append("animation_player is required.")
	if animation_profile == null:
		errors.append("animation_profile is required.")
	if jump_start_hold_seconds < 0.0 or landing_hold_seconds < 0.0:
		errors.append("jump and landing hold durations cannot be negative.")
	if hit_react_default_seconds <= 0.0:
		errors.append("hit_react_default_seconds must be greater than zero.")
	return errors


## Called by combat/presentation systems; does not apply damage or alter gameplay state.
func play_hit_react(duration: float = -1.0) -> void:
	var requested_duration := hit_react_default_seconds if duration <= 0.0 else duration
	_hit_react_remaining = maxf(requested_duration, 0.0)


func _process(delta: float) -> void:
	update_animation(delta)


## Public update entry point keeps state selection deterministic and directly testable.
func update_animation(delta: float) -> void:
	if not _initialized or delta < 0.0:
		return
	if _playback == null:
		_playback = CharacterAnimationGraph.get_playback(animation_tree)
	if _playback == null:
		return

	var snapshot := movement_controller.get_animation_state()
	# The first observation establishes a baseline; it is not a landing/jump edge.
	if not _has_grounded_sample:
		_was_grounded = snapshot.is_grounded
		_has_grounded_sample = true
	var planar_speed := snapshot.planar_velocity.length()
	var move_direction := _get_actor_local_move_direction(snapshot)

	CharacterAnimationGraph.set_move_blend_position(animation_tree, move_direction)
	_update_playback_rate(planar_speed)

	var target_state := _select_state(snapshot, planar_speed, delta)
	_travel_if_needed(target_state)
	_was_grounded = snapshot.is_grounded


func _select_state(snapshot: CharacterAnimationState, planar_speed: float, delta: float) -> StringName:
	if _hit_react_remaining > 0.0:
		_hit_react_remaining = maxf(_hit_react_remaining - delta, 0.0)
		if _hit_react_remaining > 0.0:
			return CharacterAnimationGraph.STATE_HIT_REACT

	if not snapshot.is_grounded:
		_landing_remaining = 0.0
		if _was_grounded:
			_jump_start_remaining = jump_start_hold_seconds
			return CharacterAnimationGraph.STATE_JUMP_START
		if _jump_start_remaining > 0.0:
			_jump_start_remaining = maxf(_jump_start_remaining - delta, 0.0)
			if _jump_start_remaining > 0.0:
				return CharacterAnimationGraph.STATE_JUMP_START
		return CharacterAnimationGraph.STATE_RISING if snapshot.vertical_velocity > 0.0 else CharacterAnimationGraph.STATE_FALLING

	_jump_start_remaining = 0.0
	# Startup can report grounded only after the first physics floor sample.
	# That initialization edge is not a real landing transition.
	if not _was_grounded and not _current_state.is_empty():
		_landing_remaining = landing_hold_seconds
		return CharacterAnimationGraph.STATE_LANDING
	if _landing_remaining > 0.0:
		_landing_remaining = maxf(_landing_remaining - delta, 0.0)
		if _landing_remaining > 0.0:
			return CharacterAnimationGraph.STATE_LANDING

	if _current_state == CharacterAnimationGraph.STATE_MOVE:
		return CharacterAnimationGraph.STATE_IDLE if planar_speed <= animation_profile.idle_enter_speed else CharacterAnimationGraph.STATE_MOVE
	return CharacterAnimationGraph.STATE_IDLE if planar_speed <= animation_profile.idle_exit_speed else CharacterAnimationGraph.STATE_MOVE


func _get_actor_local_move_direction(snapshot: CharacterAnimationState) -> Vector2:
	if snapshot.planar_velocity.is_zero_approx():
		return Vector2.ZERO
	var local_velocity := snapshot.facing_basis.inverse() * snapshot.planar_velocity
	return Vector2(local_velocity.x, -local_velocity.z).limit_length(1.0)


func _update_playback_rate(planar_speed: float) -> void:
	if animation_player == null:
		return
	animation_player.speed_scale = 1.0 if planar_speed <= animation_profile.idle_exit_speed else animation_profile.get_playback_rate(planar_speed)


func _travel_if_needed(state_name: StringName) -> void:
	if state_name == _current_state:
		return
	_playback.travel(String(state_name))
	_current_state = state_name


func get_current_state() -> StringName:
	return _current_state
