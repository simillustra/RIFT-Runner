extends SceneTree
## RR-004 D3 AnimationTree graph and parameter-path tests.

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var profile := load("res://game/resources/animation_profiles/base_humanoid_profile.tres") as AnimationProfile
	_check(profile != null, "base AnimationProfile loads")
	if profile == null:
		quit(1)
		return
	var machine := CharacterAnimationGraph.create_state_machine(profile)
	_check(machine != null, "state machine graph is created")
	var graph_errors := CharacterAnimationGraph.validate_state_machine(machine)
	_check(graph_errors.is_empty(), "state machine graph passes structural validation")
	var move_node := machine.get_node(CharacterAnimationGraph.STATE_MOVE) as AnimationNodeBlendSpace2D
	_check(move_node != null, "Move state uses AnimationNodeBlendSpace2D")
	if move_node != null:
		_check(move_node.get_blend_point_count() == 5, "Move blend space has idle and four directional points")
		_check(move_node.get_blend_point_position(0).is_equal_approx(Vector2.ZERO), "blend point zero is idle center")
	_check(machine.initial_node == String(CharacterAnimationGraph.STATE_IDLE), "Idle is the initial state")
	_check(machine.has_node(CharacterAnimationGraph.STATE_JUMP_START), "JumpStart state exists")
	_check(machine.has_node(CharacterAnimationGraph.STATE_RISING), "Rising state exists")
	_check(machine.has_node(CharacterAnimationGraph.STATE_FALLING), "Falling state exists")
	_check(machine.has_node(CharacterAnimationGraph.STATE_LANDING), "Landing state exists")
	_check(machine.has_node(CharacterAnimationGraph.STATE_HIT_REACT), "HitReact state exists")
	var actor_root := Node.new()
	actor_root.name = "AnimationFixture"
	root.add_child(actor_root)
	var player := AnimationPlayer.new()
	player.name = "AnimationPlayer"
	actor_root.add_child(player)
	var library := AnimationLibrary.new()
	var clip_names := PackedStringArray()
	for clip_value: Variant in profile.state_clips.values():
		var clip_name := StringName(clip_value)
		if clip_name == &"" or clip_names.has(String(clip_name)):
			continue
		clip_names.append(String(clip_name))
		library.add_animation(clip_name, Animation.new())
	player.add_animation_library(&"", library)
	var tree := AnimationTree.new()
	tree.name = "AnimationTree"
	tree.anim_player = NodePath("../AnimationPlayer")
	tree.tree_root = machine
	actor_root.add_child(tree)
	tree.active = true
	await process_frame
	var playback := CharacterAnimationGraph.get_playback(tree)
	_check(playback != null, "centralized playback parameter resolves to state-machine playback")
	_check(CharacterAnimationGraph.set_move_blend_position(tree, Vector2(0.5, 0.75)), "centralized blend parameter can be set")
	var blend_value: Vector2 = tree.get(String(CharacterAnimationGraph.MOVE_BLEND_PARAMETER_PATH))
	_check(blend_value.is_equal_approx(Vector2(0.5, 0.75)), "blend parameter retains actor-local direction")
	_check(CharacterAnimationGraph.get_playback(null) == null, "null AnimationTree safely returns no playback")
	_check(not CharacterAnimationGraph.set_move_blend_position(null, Vector2.ONE), "null AnimationTree safely rejects blend update")
	actor_root.queue_free()
	await process_frame
	if failures == 0:
		print("RR-004 D3 AnimationTree graph tests: PASS")
		quit(0)
	else:
		push_error("RR-004 D3 AnimationTree graph tests: %d failure(s)" % failures)
		quit(1)

func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		failures += 1
		push_error("FAIL: %s" % description)