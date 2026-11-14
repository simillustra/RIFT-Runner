extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_pointer_ownership_and_tap()
	await _test_double_and_triple_tap_conflicts()
	await _test_long_press_and_movement_cancel()
	await _test_hard_press_and_cancellation()
	await _test_invalid_configuration()
	if _failures == 0:
		print("PASS: RR-006 D4 tap/press gesture recognizer")
		quit(0)
	else:
		push_error("RR-006 D4 tap/press gesture failures: %d" % _failures)
		quit(1)


func _assert(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
	else:
		_failures += 1
		push_error("FAIL: %s" % label)


func _new_recognizer() -> TapPressGestureRecognizer:
	var recognizer := TapPressGestureRecognizer.new()
	recognizer.size = Vector2(300.0, 300.0)
	root.add_child(recognizer)
	return recognizer


func _test_pointer_ownership_and_tap() -> void:
	var recognizer := _new_recognizer()
	await process_frame
	var received: Array[MobileInputCommand] = []
	recognizer.command_emitted.connect(func(command: MobileInputCommand) -> void: received.append(command))
	_assert(recognizer.begin_pointer(1, Vector2(150.0, 150.0)), "touch inside recognizer acquires pointer")
	_assert(not recognizer.begin_pointer(2, Vector2(150.0, 150.0)), "second pointer cannot steal active press")
	_assert(not recognizer.update_pointer(2, Vector2(151.0, 150.0)), "non-owner pointer cannot update active press")
	recognizer.end_pointer(1)
	_assert(received.is_empty() and recognizer.get_pending_tap_count() == 1, "single tap waits for multi-tap conflict window")
	recognizer.advance_time(0.3)
	_assert(received.size() == 2 and received[0].action == MobileInputAction.Action.BASIC_ATTACK, "single tap resolves to configured action after timeout")
	_assert(received[0].phase == MobileInputAction.Phase.STARTED and received[1].phase == MobileInputAction.Phase.PERFORMED, "discrete tap emits ordered semantic phases")
	recognizer.queue_free()


func _test_double_and_triple_tap_conflicts() -> void:
	var recognizer := _new_recognizer()
	await process_frame
	var received: Array[MobileInputCommand] = []
	recognizer.command_emitted.connect(func(command: MobileInputCommand) -> void: received.append(command))
	for pointer in [10, 11]:
		recognizer.begin_pointer(pointer, Vector2(100.0, 100.0))
		recognizer.end_pointer(pointer)
		recognizer.advance_time(0.05)
	_assert(received.is_empty(), "double tap is not emitted before triple-tap window closes")
	recognizer.advance_time(0.3)
	_assert(received.size() == 2 and received[0].action == MobileInputAction.Action.DODGE, "two taps resolve once to double-tap action")
	received.clear()
	for pointer in [20, 21, 22]:
		recognizer.begin_pointer(pointer, Vector2(100.0, 100.0))
		recognizer.end_pointer(pointer)
		recognizer.advance_time(0.04)
	_assert(received.size() == 2 and received[0].action == MobileInputAction.Action.INTERACT, "third tap overrides double tap and emits triple-tap action")
	recognizer.queue_free()


func _test_long_press_and_movement_cancel() -> void:
	var recognizer := _new_recognizer()
	await process_frame
	var received: Array[MobileInputCommand] = []
	recognizer.command_emitted.connect(func(command: MobileInputCommand) -> void: received.append(command))
	recognizer.begin_pointer(30, Vector2(100.0, 100.0))
	recognizer.advance_time(0.6)
	recognizer.end_pointer(30)
	_assert(received.size() == 2 and received[0].action == MobileInputAction.Action.CANCEL, "long press fires once at configured duration and suppresses tap")
	received.clear()
	recognizer.begin_pointer(31, Vector2(100.0, 100.0))
	recognizer.update_pointer(31, Vector2(130.0, 100.0))
	recognizer.end_pointer(31)
	recognizer.advance_time(0.3)
	_assert(received.is_empty(), "movement beyond tap tolerance cancels press without emitting tap")
	recognizer.queue_free()


func _test_hard_press_and_cancellation() -> void:
	var recognizer := _new_recognizer()
	recognizer.gesture_profile.enable_hard_press = true
	await process_frame
	var received: Array[MobileInputCommand] = []
	recognizer.command_emitted.connect(func(command: MobileInputCommand) -> void: received.append(command))
	recognizer.begin_pointer(40, Vector2(100.0, 100.0))
	recognizer.update_pressure(40, 0.9)
	recognizer.end_pointer(40)
	_assert(received.size() == 2 and received[0].action == MobileInputAction.Action.PAUSE, "pressure-aware hard press emits configured action and suppresses tap")
	received.clear()
	recognizer.begin_pointer(41, Vector2(100.0, 100.0))
	recognizer.cancel_active_pointer()
	recognizer.advance_time(0.4)
	_assert(received.is_empty() and recognizer.get_pending_tap_count() == 0, "explicit cancellation clears active and pending gestures")
	recognizer.queue_free()


func _test_invalid_configuration() -> void:
	var recognizer := _new_recognizer()
	await process_frame
	recognizer.source_id = &""
	_assert(not recognizer.begin_pointer(50, Vector2(100.0, 100.0)), "empty source ID prevents pointer acquisition")
	recognizer.source_id = &"gesture_tap_press"
	recognizer.gesture_profile.long_press_seconds = 0.0
	_assert(not recognizer.is_enabled(), "invalid timing profile is rejected")
	recognizer.queue_free()
