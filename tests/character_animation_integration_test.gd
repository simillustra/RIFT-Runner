extends SceneTree
## RR-004 D5 scene integration and no-rig fallback tests.

var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var actor_scene := load("res://game/scenes/characters/character_actor.tscn") as PackedScene
	_check(actor_scene != null, "base CharacterActor scene resource loads")
	if actor_scene == null:
		quit(1)
		return

	var fallback_actor := actor_scene.instantiate() as CharacterActor
	root.add_child(fallback_actor)
	await process_frame
	var fallback_integration := fallback_actor.get_node("AnimationIntegration") as CharacterAnimationIntegration
	var fallback_movement := fallback_actor.get_node("MovementController") as CharacterMovementController
	_check(fallback_integration != null, "base actor contains optional animation integration adapter")
	_check(fallback_integration != null and not fallback_integration.is_integration_enabled(), "actor without a rig disables animation integration")
	_check(fallback_movement != null, "actor without a rig retains its movement controller")
	_check(fallback_actor.is_inside_tree(), "actor without a rig remains loadable")
	fallback_actor.queue_free()
	await process_frame

	var animated_actor := actor_scene.instantiate() as CharacterActor
	var movement := animated_actor.get_node("MovementController") as CharacterMovementController
	movement.set_physics_process(false)
	movement.is_grounded = true
	var player := AnimationPlayer.new()
	player.name = "AnimationPlayer"
	var library := AnimationLibrary.new()
	for clip_name: StringName in [&"idle", &"move", &"rising", &"falling", &"landing"]:
		library.add_animation(clip_name, Animation.new())
	player.add_animation_library(&"", library)
	animated_actor.add_child(player)
	var tree := AnimationTree.new()
	tree.name = "AnimationTree"
	tree.anim_player = NodePath("../AnimationPlayer")
	animated_actor.add_child(tree)
	root.add_child(animated_actor)
	await process_frame
	await process_frame

	var integration := animated_actor.get_node("AnimationIntegration") as CharacterAnimationIntegration
	var controller := integration.get_runtime_controller() if integration != null else null
	_check(integration != null and integration.is_integration_enabled(), "animation integration enables when rig dependencies exist")
	_check(controller != null and controller._initialized, "integration creates an initialized D4 controller")
	_check(tree.active, "integrated AnimationTree is activated")
	if controller != null:
		var velocity_before := animated_actor.velocity
		controller.update_animation(0.016)
		_check(controller.get_current_state() == CharacterAnimationGraph.STATE_IDLE, "integrated controller samples the movement snapshot")
		_check(animated_actor.velocity == velocity_before, "animation integration never mutates actor velocity")
	_check(movement.is_grounded, "animation integration never mutates grounded state")
	animated_actor.queue_free()
	await process_frame

	if failures == 0:
		print("RR-004 D5 CharacterAnimationIntegration tests: PASS")
		quit(0)
	else:
		push_error("RR-004 D5 CharacterAnimationIntegration tests: %d failure(s)" % failures)
		quit(1)


func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		failures += 1
		push_error("FAIL: %s" % description)
