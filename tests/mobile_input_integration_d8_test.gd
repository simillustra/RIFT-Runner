extends SceneTree
## RR-006 D8 end-to-end recognizer -> context -> router -> gameplay integration.

const HERO_PATH: String = "res://game/resources/characters/heroes/vanguard.tres"
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var actor_scene := load("res://game/scenes/characters/character_actor.tscn") as PackedScene
	var actor := actor_scene.instantiate() as CharacterActor
	actor.definition = load(HERO_PATH) as CharacterDefinition
	actor.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(actor)
	await process_frame

	var router := actor.get_node("MobileInputRouter") as MobileInputRouter
	var manager := actor.get_node("MobileInputContextController") as MobileInputContextController
	var movement := actor.get_node("MovementController") as CharacterMovementController
	var combat := actor.get_node("HeroCombatController") as HeroCombatController
	movement.movement_mode = CharacterMovementController.MovementMode.FREE

	var joystick := VirtualJoystick.new()
	joystick.size = Vector2(160.0, 160.0)
	manager.add_child(joystick)
	_check(manager.register_control(joystick, MobileInputAction.Mode.GUIDED) == OK, "guided joystick registers with context manager")
	await process_frame
	_check(joystick.visible, "guided joystick is visible in guided gameplay context")
	_check(joystick.begin_pointer(11, Vector2(80.0, 80.0)), "joystick acquires touch pointer")
	_check(joystick.update_pointer(11, Vector2(144.0, 80.0)), "joystick updates touch pointer")
	_check(movement._move_intent.x > 0.9 and is_zero_approx(movement._move_intent.y), "joystick command reaches movement authority")
	_check(joystick.end_pointer(11) and movement._move_intent.is_zero_approx(), "joystick release neutralizes movement through router")

	var swipe_profile := FreeHandGestureProfile.new()
	swipe_profile.up_action = MobileInputAction.Action.JUMP
	var freehand := FreeHandGestureRecognizer.new()
	freehand.size = Vector2(320.0, 320.0)
	freehand.gesture_profile = swipe_profile
	manager.add_child(freehand)
	_check(manager.register_control(freehand, MobileInputAction.Mode.FREE_HAND) == OK, "free-hand recognizer registers")
	var tap_profile := TapPressGestureProfile.new()
	tap_profile.tap_action = MobileInputAction.Action.BASIC_ATTACK
	var tap := TapPressGestureRecognizer.new()
	tap.size = Vector2(320.0, 320.0)
	tap.gesture_profile = tap_profile
	manager.add_child(tap)
	_check(manager.register_control(tap, MobileInputAction.Mode.FREE_HAND) == OK, "tap/press recognizer registers")
	await process_frame

	_check(manager.set_control_mode(MobileInputAction.Mode.FREE_HAND) == OK, "switch to free-hand mode succeeds")
	_check(not joystick.visible and freehand.visible and tap.visible, "only free-hand recognizers are active")
	_check(freehand.begin_pointer(12, Vector2(160.0, 180.0)), "swipe recognizer acquires pointer")
	_check(freehand.update_pointer(12, Vector2(160.0, 90.0)), "swipe recognizer tracks direction")
	_check(freehand.end_pointer(12), "swipe recognizer completes gesture")
	_check(movement._jump_requested, "swipe semantic command reaches jump request API")
	movement._jump_requested = false

	_check(tap.begin_pointer(13, Vector2(160.0, 160.0)), "tap recognizer acquires pointer")
	_check(tap.end_pointer(13), "tap recognizer records tap")
	tap.advance_time(tap.gesture_profile.multi_tap_window_seconds + 0.01)
	var executor := actor.get_node("AttackExecutor") as AttackExecutor
	_check(not executor.is_ready() and executor.active_definition == actor.definition.basic_attack, "resolved tap dispatches basic attack through combat authority")
	executor.cancel_attack()

	var active_move := MobileInputCommand.new()
	active_move.action = MobileInputAction.Action.MOVE
	active_move.phase = MobileInputAction.Phase.PERFORMED
	active_move.mode = MobileInputAction.Mode.FREE_HAND
	active_move.vector = Vector2.LEFT
	active_move.strength = 1.0
	active_move.source_id = &"integration_lifecycle"
	active_move.sequence_id = 1
	_check(router.route_command(active_move) == OK, "router accepts active free-hand movement source")
	_check(manager.set_context(MobileInputContextController.Context.DIALOG) == OK, "dialog context transition succeeds")
	_check(movement._move_intent.is_zero_approx() and router.get_active_move_sources().is_empty(), "context transition cancels controls and clears movement")
	_check(not freehand.visible and not tap.visible and not router.gameplay_input_enabled, "dialog suppresses recognizers and gameplay router")
	_check(manager.set_context(MobileInputContextController.Context.GAMEPLAY) == OK, "gameplay context restores")
	_check(router.gameplay_input_enabled and freehand.visible and tap.visible, "gameplay input is restored after dialog")

	manager.unregister_control(joystick)
	manager.unregister_control(freehand)
	manager.unregister_control(tap)
	actor.queue_free()
	await process_frame

	if failures == 0:
		print("PASS: RR-006 D8 end-to-end integration")
		quit(0)
	else:
		push_error("RR-006 D8 integration failures: %d" % failures)
		quit(1)

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
	else:
		failures += 1
		push_error("FAIL: %s" % label)
