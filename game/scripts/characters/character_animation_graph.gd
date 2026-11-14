extends RefCounted
class_name CharacterAnimationGraph
## Builds and validates the shared RR-004 locomotion AnimationTree graph.
## This class configures presentation resources only; it never mutates movement.

const PLAYBACK_PARAMETER_PATH: StringName = &"parameters/playback"
const MOVE_BLEND_PARAMETER_PATH: StringName = &"parameters/Move/blend_position"

const STATE_IDLE: StringName = &"Idle"
const STATE_MOVE: StringName = &"Move"
const STATE_JUMP_START: StringName = &"JumpStart"
const STATE_RISING: StringName = &"Rising"
const STATE_FALLING: StringName = &"Falling"
const STATE_LANDING: StringName = &"Landing"
const STATE_HIT_REACT: StringName = &"HitReact"

const MOVE_BLEND_IDLE_POINT := Vector2.ZERO
const MOVE_BLEND_FORWARD_POINT := Vector2(0.0, 1.0)
const MOVE_BLEND_BACKWARD_POINT := Vector2(0.0, -1.0)
const MOVE_BLEND_LEFT_POINT := Vector2(-1.0, 0.0)
const MOVE_BLEND_RIGHT_POINT := Vector2(1.0, 0.0)

static func create_state_machine(profile: AnimationProfile) -> AnimationNodeStateMachine:
	if profile == null:
		push_error("CharacterAnimationGraph requires a valid AnimationProfile.")
		return null
	var machine := AnimationNodeStateMachine.new()
	machine.resource_name = "Locomotion"
	machine.initial_node = STATE_IDLE
	machine.add_node(STATE_IDLE, _animation_node(profile.get_clip(&"idle")), Vector2(0.0, 0.0))
	machine.add_node(STATE_MOVE, _create_move_blend_space(profile), Vector2(240.0, 0.0))
	machine.add_node(STATE_JUMP_START, _animation_node(profile.get_clip(&"jump_start")), Vector2(0.0, 180.0))
	machine.add_node(STATE_RISING, _animation_node(profile.get_clip(&"rising")), Vector2(180.0, 180.0))
	machine.add_node(STATE_FALLING, _animation_node(profile.get_clip(&"falling")), Vector2(360.0, 180.0))
	machine.add_node(STATE_LANDING, _animation_node(profile.get_clip(&"landing")), Vector2(360.0, 360.0))
	machine.add_node(STATE_HIT_REACT, _animation_node(profile.get_clip(&"hit_react")), Vector2(600.0, 0.0))
	_add_transition(machine, STATE_IDLE, STATE_MOVE)
	_add_transition(machine, STATE_MOVE, STATE_IDLE)
	_add_transition(machine, STATE_IDLE, STATE_JUMP_START)
	_add_transition(machine, STATE_MOVE, STATE_JUMP_START)
	_add_transition(machine, STATE_JUMP_START, STATE_RISING)
	_add_transition(machine, STATE_RISING, STATE_FALLING)
	_add_transition(machine, STATE_FALLING, STATE_LANDING)
	_add_transition(machine, STATE_LANDING, STATE_IDLE)
	_add_transition(machine, STATE_LANDING, STATE_MOVE)
	_add_transition(machine, STATE_IDLE, STATE_HIT_REACT)
	_add_transition(machine, STATE_MOVE, STATE_HIT_REACT)
	_add_transition(machine, STATE_HIT_REACT, STATE_IDLE)
	_add_transition(machine, STATE_HIT_REACT, STATE_MOVE)
	return machine

static func validate_state_machine(machine: AnimationNodeStateMachine) -> PackedStringArray:
	var errors := PackedStringArray()
	if machine == null:
		errors.append("Animation state machine is null.")
		return errors
	var required_nodes: Array[StringName] = [STATE_IDLE, STATE_MOVE, STATE_JUMP_START, STATE_RISING, STATE_FALLING, STATE_LANDING, STATE_HIT_REACT]
	for state_name: StringName in required_nodes:
		if not machine.has_node(state_name):
			errors.append("Animation state machine is missing state %s." % String(state_name))
	var move_node := machine.get_node(STATE_MOVE) as AnimationNodeBlendSpace2D
	if move_node == null:
		errors.append("Move state must use AnimationNodeBlendSpace2D.")
	elif move_node.get_blend_point_count() != 5:
		errors.append("Move BlendSpace2D must define exactly five directional/idle points.")
	if machine.initial_node != STATE_IDLE:
		errors.append("Animation state machine initial node must be Idle.")
	return errors

static func get_playback(tree: AnimationTree) -> AnimationNodeStateMachinePlayback:
	if tree == null or not tree.active:
		return null
	return tree.get(String(PLAYBACK_PARAMETER_PATH)) as AnimationNodeStateMachinePlayback

static func set_move_blend_position(tree: AnimationTree, direction: Vector2) -> bool:
	if tree == null or not tree.active:
		return false
	tree.set(String(MOVE_BLEND_PARAMETER_PATH), direction.limit_length(1.0))
	return true

static func _create_move_blend_space(profile: AnimationProfile) -> AnimationNodeBlendSpace2D:
	var blend_space := AnimationNodeBlendSpace2D.new()
	blend_space.resource_name = "Move"
	blend_space.min_space = Vector2(-1.0, -1.0)
	blend_space.max_space = Vector2(1.0, 1.0)
	blend_space.snap = Vector2(0.05, 0.05)
	blend_space.add_blend_point(_animation_node(profile.get_clip(&"idle")), MOVE_BLEND_IDLE_POINT)
	blend_space.add_blend_point(_animation_node(profile.get_clip(&"move")), MOVE_BLEND_FORWARD_POINT)
	blend_space.add_blend_point(_animation_node(profile.get_clip(&"move")), MOVE_BLEND_BACKWARD_POINT)
	blend_space.add_blend_point(_animation_node(profile.get_clip(&"move")), MOVE_BLEND_LEFT_POINT)
	blend_space.add_blend_point(_animation_node(profile.get_clip(&"move")), MOVE_BLEND_RIGHT_POINT)
	return blend_space

static func _animation_node(clip_name: StringName) -> AnimationNodeAnimation:
	var animation_node := AnimationNodeAnimation.new()
	animation_node.animation = clip_name
	return animation_node

static func _add_transition(machine: AnimationNodeStateMachine, from_state: StringName, to_state: StringName) -> void:
	var transition := AnimationNodeStateMachineTransition.new()
	transition.xfade_time = 0.12
	machine.add_transition(from_state, to_state, transition)