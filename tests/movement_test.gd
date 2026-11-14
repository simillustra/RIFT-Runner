extends SceneTree
## RR-003 regression and RR-004 D1 movement snapshot contract tests.

var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene := load("res://game/scenes/characters/character_actor.tscn") as PackedScene
	_check(scene != null, "character actor scene loads")
	if scene == null:
		quit(1)
		return
	var actor := scene.instantiate() as CharacterActor
	_check(actor != null, "character actor instantiates")
	if actor == null:
		quit(1)
		return
	actor.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(actor)
	await process_frame
	var controller := actor.get_node_or_null("MovementController") as CharacterMovementController
	_check(controller != null, "movement controller is attached")
	if controller != null:
		_check(controller.validate_configuration().is_empty(), "default configuration validates")
		_check(controller.lane_count == 3, "default lane count is three")
		controller.request_lane_change(1)
		_check(controller.lane_index == 2, "lane selection advances")
		controller.request_lane_change(1)
		_check(controller.lane_index == 2, "lane selection clamps at boundary")
		controller.request_lane_change(-1)
		_check(controller.lane_index == 1, "lane selection returns to center")
		controller.set_move_intent(Vector2.ONE)
		_check(is_equal_approx(controller._move_intent.length(), 1.0), "movement intent is normalized")
		controller.request_jump()
		_check(controller._jump_requested, "jump request is queued")

		actor.velocity = Vector3(3.0, 4.5, -6.0)
		actor.rotation.y = PI / 2.0
		var snapshot := controller.get_animation_state()
		_check(snapshot is CharacterAnimationState, "animation snapshot has the typed state contract")
		_check(snapshot.planar_velocity.is_equal_approx(Vector3(3.0, 0.0, -6.0)), "snapshot exposes planar velocity without vertical component")
		_check(is_equal_approx(snapshot.vertical_velocity, 4.5), "snapshot exposes vertical velocity")
		_check(snapshot.is_grounded == controller.is_grounded, "snapshot exposes grounded state")
		_check(snapshot.movement_mode == CharacterMovementController.MovementMode.LANE, "snapshot exposes movement mode")
		_check(snapshot.facing_basis.is_equal_approx(actor.global_transform.basis), "snapshot exposes actor facing basis")

		snapshot.planar_velocity = Vector3.ZERO
		snapshot.vertical_velocity = 0.0
		var second_snapshot := controller.get_animation_state()
		_check(second_snapshot.planar_velocity.is_equal_approx(Vector3(3.0, 0.0, -6.0)), "snapshot is detached from actor movement")
		_check(is_equal_approx(actor.velocity.y, 4.5), "snapshot mutation cannot change actor velocity")

	actor.queue_free()
	await process_frame
	if failures == 0:
		print("RR-003/RR-004 D1 movement state tests: PASS")
		quit(0)
	else:
		push_error("RR-003/RR-004 D1 movement state tests: %d failure(s)" % failures)
		quit(1)


func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		failures += 1
		push_error("FAIL: %s" % description)
