extends SceneTree
## RR-003 movement configuration and intent smoke tests.

var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: PackedScene = load("res://game/scenes/characters/character_actor.tscn") as PackedScene
	_check(scene != null, "character actor scene loads for movement")
	if scene == null:
		quit(1)
		return
	var actor: CharacterActor = scene.instantiate() as CharacterActor
	_check(actor != null, "character actor instantiates")
	if actor == null:
		quit(1)
		return
	var controller: CharacterMovementController = actor.get_node_or_null("MovementController") as CharacterMovementController
	_check(controller != null, "movement controller is attached to actor")
	if controller != null:
		_check(controller.validate_configuration().is_empty(), "default movement configuration validates")
		_check(controller.lane_count == 3, "default lane count is three")
		controller.request_lane_change(1)
		_check(controller.lane_index == 2, "lane change advances one lane")
		controller.request_lane_change(1)
		_check(controller.lane_index == 2, "lane change clamps at right boundary")
		controller.request_lane_change(-1)
		_check(controller.lane_index == 1, "lane change returns toward center")
		controller.set_move_intent(Vector2(1.0, 1.0))
		_check(is_equal_approx(controller._move_intent.length(), 1.0), "movement intent is normalized")
		controller.request_jump()
		_check(controller._jump_requested, "jump request is queued for physics tick")
	actor.free()
	if failures == 0:
		print("RR-003 movement tests: PASS")
		quit(0)
	else:
		push_error("RR-003 movement tests: %d failure(s)" % failures)
		quit(1)


func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		failures += 1
		push_error("FAIL: %s" % description)
