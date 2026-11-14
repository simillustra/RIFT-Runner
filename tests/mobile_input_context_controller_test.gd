extends SceneTree
## RR-006 D6 mode, context, settings and accessibility regression tests.

const HERO_PATH: String = "res://game/resources/characters/heroes/vanguard.tres"
const TEST_SETTINGS_PATH: String = "user://rr006_d6_test_settings.cfg"
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

	var manager := MobileInputContextController.new()
	manager.router_path = NodePath("../MobileInputRouter")
	manager.settings_file_path = TEST_SETTINGS_PATH
	actor.add_child(manager)
	await process_frame
	var router := actor.get_node("MobileInputRouter") as MobileInputRouter
	var movement := actor.get_node("MovementController") as CharacterMovementController
	movement.movement_mode = CharacterMovementController.MovementMode.FREE

	var joystick := VirtualJoystick.new()
	joystick.size = Vector2(160.0, 160.0)
	manager.add_child(joystick)
	_check(manager.register_control(joystick, MobileInputAction.Mode.GUIDED) == OK, "guided control registers")
	var freehand := FreeHandGestureRecognizer.new()
	freehand.size = Vector2(320.0, 320.0)
	freehand.gesture_profile = FreeHandGestureProfile.new()
	manager.add_child(freehand)
	_check(manager.register_control(freehand, MobileInputAction.Mode.FREE_HAND) == OK, "free-hand control registers")
	var tap := TapPressGestureRecognizer.new()
	tap.size = Vector2(320.0, 320.0)
	tap.gesture_profile = TapPressGestureProfile.new()
	manager.add_child(tap)
	_check(manager.register_control(tap, MobileInputAction.Mode.FREE_HAND) == OK, "tap/press control registers")
	await process_frame

	_check(joystick.visible and not freehand.visible and not tap.visible, "guided mode exposes only guided recognizers")
	_check(joystick.begin_pointer(1, Vector2(80.0, 80.0)), "guided joystick acquires pointer")
	joystick.update_pointer(1, Vector2(144.0, 80.0))
	_check(not movement._move_intent.is_zero_approx(), "guided joystick routes movement intent")
	_check(manager.set_control_mode(MobileInputAction.Mode.FREE_HAND) == OK, "mode switches to free-hand")
	_check(movement._move_intent.is_zero_approx() and not joystick.has_active_pointer(), "mode switch cancels old pointer and neutralizes movement")
	_check(not joystick.visible and freehand.visible and tap.visible, "free-hand mode exposes free-hand recognizers only")
	_check(router.gameplay_input_enabled, "gameplay router re-enables after atomic mode transition")

	_check(freehand.begin_pointer(2, Vector2(100.0, 100.0)), "free-hand recognizer acquires pointer")
	_check(manager.set_context(MobileInputContextController.Context.DIALOG) == OK, "dialog context activates")
	_check(not router.gameplay_input_enabled, "dialog context suppresses gameplay routing")
	_check(not freehand.has_active_pointer() and not freehand.visible and not tap.visible, "context transition cancels and hides gameplay recognizers")
	var blocked := _command(MobileInputAction.Action.PAUSE, &"blocked", 1, MobileInputAction.Mode.FREE_HAND)
	_check(router.route_command(blocked) == ERR_UNAVAILABLE, "router rejects commands while dialog is active")
	_check(manager.set_context(MobileInputContextController.Context.GAMEPLAY) == OK, "gameplay context restores")
	_check(router.gameplay_input_enabled and freehand.visible and tap.visible, "gameplay context restores active-mode controls")

	var preferences := MobileInputSettings.new()
	preferences.joystick_side = MobileInputSettings.JoystickSide.LEFT
	preferences.joystick_scale = 1.35
	preferences.joystick_deadzone = 0.18
	preferences.gesture_sensitivity = 1.2
	preferences.long_press_seconds = 0.7
	preferences.multi_tap_window_seconds = 0.4
	preferences.high_contrast_controls = true
	_check(manager.update_settings(preferences) == OK, "valid accessibility settings are accepted")
	_check(is_equal_approx(joystick.base_radius, 86.4) and is_equal_approx(joystick.deadzone, 0.18), "joystick scale and deadzone are applied")
	_check(joystick.base_color.r < 0.1 and joystick.knob_color.r > 0.9, "high-contrast joystick palette is applied")
	_check(is_equal_approx((tap.gesture_profile as TapPressGestureProfile).long_press_seconds, 0.7), "press timing preference is applied")
	_check(manager.save_settings() == OK, "settings persist to ConfigFile")
	preferences.joystick_scale = 0.8
	_check(manager.update_settings(preferences) == OK, "settings can be changed before reload")
	_check(manager.load_settings() == OK, "saved settings reload")
	_check(is_equal_approx(manager.settings.joystick_scale, 1.35) and manager.settings.joystick_side == MobileInputSettings.JoystickSide.LEFT, "saved settings values round-trip")
	_check(is_equal_approx(joystick.base_radius, 86.4), "reloaded settings are reapplied to registered controls")
	var invalid := MobileInputSettings.new()
	invalid.joystick_scale = 4.0
	_check(manager.update_settings(invalid) == ERR_INVALID_DATA, "invalid accessibility settings are rejected")
	_check(manager.set_control_mode(99) == ERR_INVALID_PARAMETER, "invalid control mode is rejected")
	_check(manager.set_context(99) == ERR_INVALID_PARAMETER, "invalid gameplay context is rejected")

	manager.unregister_control(joystick)
	_check(not joystick.visible, "unregister removes control from mode management")
	actor.queue_free()
	await process_frame
	var absolute_path := ProjectSettings.globalize_path(TEST_SETTINGS_PATH)
	if FileAccess.file_exists(TEST_SETTINGS_PATH):
		DirAccess.remove_absolute(absolute_path)
	if failures == 0:
		print("PASS: RR-006 D6 context, mode and accessibility tests")
		quit(0)
	else:
		push_error("RR-006 D6 failures: %d" % failures)
		quit(1)


func _command(action: int, source: StringName, sequence: int, mode: int) -> MobileInputCommand:
	var command := MobileInputCommand.new()
	command.action = action
	command.phase = MobileInputAction.Phase.PERFORMED
	command.mode = mode
	command.source_id = source
	command.sequence_id = sequence
	return command


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
	else:
		failures += 1
		push_error("FAIL: %s" % label)
