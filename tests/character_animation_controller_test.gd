extends SceneTree
## RR-004 D4 runtime controller state-selection and presentation tests.

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var profile := load("res://game/resources/animation_profiles/base_humanoid_profile.tres") as AnimationProfile
	_check(profile != null, "base AnimationProfile loads")
	if profile == null:
		quit(1)
		return

	var actor := CharacterBody3D.new()
	actor.name = "AnimationActorFixture"
	root.add_child(actor)
	var movement := CharacterMovementController.new()
	movement.name = "MovementController"
	actor.add_child(movement)

	var player := AnimationPlayer.new()
	player.name = "AnimationPlayer"
	actor.add_child(player)
	var library := AnimationLibrary.new()
	for clip_name: StringName in [&"idle", &"move", &"rising", &"falling", &"landing"]:
		library.add_animation(clip_name, Animation.new())
	player.add_animation_library(&"", library)

	var tree := AnimationTree.new()
	tree.name = "AnimationTree"
	tree.anim_player = NodePath("../AnimationPlayer")
	actor.add_child(tree)

	var controller := CharacterAnimationController.new()
	controller.name = "AnimationController"
	controller.movement_controller = movement
	controller.animation_tree = tree
	controller.animation_player = player
	controller.animation_profile = profile
	actor.add_child(controller)
	await process_frame
	await process_frame

	_check(controller._initialized, "controller initializes with valid movement, profile and animation resources")
	_check(tree.active, "controller activates its AnimationTree")
	_check(CharacterAnimationGraph.get_playback(tree) != null, "controller exposes the D3 state-machine playback")

	movement.is_grounded = true
	actor.velocity = Vector3.ZERO
	controller.update_animation(0.016)
	_check(controller.get_current_state() == CharacterAnimationGraph.STATE_IDLE, "stationary grounded actor selects Idle")

	actor.velocity = Vector3(0.0, 0.0, -5.0)
	controller.update_animation(0.016)
	_check(controller.get_current_state() == CharacterAnimationGraph.STATE_MOVE, "grounded movement selects Move")
	_check(is_equal_approx(player.speed_scale, profile.get_playback_rate(5.0)), "movement speed drives bounded profile playback rate")

	movement.is_grounded = false
	actor.velocity.y = 6.0
	controller.update_animation(0.016)
	_check(controller.get_current_state() == CharacterAnimationGraph.STATE_JUMP_START, "grounded-to-airborne edge selects JumpStart")
	controller.update_animation(0.20)
	_check(controller.get_current_state() == CharacterAnimationGraph.STATE_RISING, "positive vertical velocity selects Rising after jump-start hold")

	actor.velocity.y = -2.0
	controller.update_animation(0.016)
	_check(controller.get_current_state() == CharacterAnimationGraph.STATE_FALLING, "negative vertical velocity selects Falling")

	movement.is_grounded = true
	actor.velocity = Vector3.ZERO
	controller.update_animation(0.016)
	_check(controller.get_current_state() == CharacterAnimationGraph.STATE_LANDING, "airborne-to-grounded edge selects Landing")
	controller.update_animation(0.20)
	_check(controller.get_current_state() == CharacterAnimationGraph.STATE_IDLE, "landing hold returns grounded stationary actor to Idle")

	controller.play_hit_react(0.25)
	controller.update_animation(0.016)
	_check(controller.get_current_state() == CharacterAnimationGraph.STATE_HIT_REACT, "external hit-react request selects HitReact")
	controller.update_animation(0.30)
	_check(controller.get_current_state() == CharacterAnimationGraph.STATE_IDLE, "expired hit-react returns to locomotion")

	_check(CharacterAnimationGraph.set_move_blend_position(tree, Vector2.ZERO), "controller leaves centralized blend parameter writable")
	actor.queue_free()
	await process_frame
	if failures == 0:
		print("RR-004 D4 CharacterAnimationController tests: PASS")
		quit(0)
	else:
		push_error("RR-004 D4 CharacterAnimationController tests: %d failure(s)" % failures)
		quit(1)

func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		failures += 1
		push_error("FAIL: %s" % description)
