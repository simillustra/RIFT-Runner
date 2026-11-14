extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var joystick := VirtualJoystick.new()
	root.add_child(joystick)
	joystick.size = Vector2(160.0, 160.0)
	await process_frame
	_test_pointer_ownership(joystick)
	_test_deadzone_and_normalization(joystick)
	_test_clamping_and_direction(joystick)
	_test_cancel_and_sequence(joystick)
	_test_invalid_configuration(joystick)
	joystick.queue_free()
	await process_frame
	if _failures == 0:
		print("PASS: RR-006 D2 virtual joystick")
		quit(0)
	else:
		push_error("RR-006 D2 virtual joystick failures: %d" % _failures)
		quit(1)


func _assert(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
	else:
		_failures += 1
		push_error("FAIL: %s" % label)


func _test_pointer_ownership(joystick: VirtualJoystick) -> void:
	_assert(joystick.begin_pointer(4, Vector2(80.0, 80.0)), "pointer inside control acquires joystick")
	_assert(not joystick.begin_pointer(5, Vector2(80.0, 80.0)), "second pointer cannot steal active joystick")
	_assert(not joystick.update_pointer(5, Vector2(140.0, 80.0)), "non-owner pointer cannot update joystick")
	_assert(joystick.end_pointer(4), "owner pointer can release joystick")
	_assert(not joystick.has_active_pointer(), "release clears pointer ownership")


func _test_deadzone_and_normalization(joystick: VirtualJoystick) -> void:
	joystick.begin_pointer(1, Vector2(80.0, 80.0))
	joystick.update_pointer(1, Vector2(84.0, 80.0))
	_assert(joystick.get_output_vector().is_zero_approx(), "deadzone suppresses small accidental movement")
	joystick.update_pointer(1, Vector2(120.0, 80.0))
	_assert(is_equal_approx(joystick.get_output_vector().length(), 1.0), "full-radius input produces unit magnitude")
	joystick.end_pointer(1)


func _test_clamping_and_direction(joystick: VirtualJoystick) -> void:
	joystick.begin_pointer(2, Vector2(80.0, 80.0))
	joystick.update_pointer(2, Vector2(1000.0, 80.0))
	var right := joystick.get_output_vector()
	_assert(right.x > 0.99 and absf(right.y) < 0.001, "rightward drag maps to positive X and clamps at radius")
	joystick.update_pointer(2, Vector2(80.0, 0.0))
	var up := joystick.get_output_vector()
	_assert(up.y > 0.99 and absf(up.x) < 0.001, "upward screen drag maps to positive gameplay Y")
	joystick.end_pointer(2)


func _test_cancel_and_sequence(joystick: VirtualJoystick) -> void:
	var received: Array[MobileInputCommand] = []
	joystick.command_emitted.connect(func(command: MobileInputCommand) -> void: received.append(command))
	joystick.begin_pointer(7, Vector2(80.0, 80.0))
	joystick.update_pointer(7, Vector2(120.0, 80.0))
	joystick.cancel_active_pointer()
	var valid := received.size() == 3
	if valid:
		valid = received[0].phase == MobileInputAction.Phase.STARTED
		valid = valid and received[1].phase == MobileInputAction.Phase.PERFORMED
		valid = valid and received[2].phase == MobileInputAction.Phase.CANCELED
		valid = valid and received[2].vector.is_zero_approx()
		valid = valid and received[0].sequence_id < received[1].sequence_id and received[1].sequence_id < received[2].sequence_id
	_assert(valid, "joystick emits validated STARTED/PERFORMED/CANCELED commands with increasing sequence IDs")


func _test_invalid_configuration(joystick: VirtualJoystick) -> void:
	joystick.source_id = &""
	_assert(not joystick.begin_pointer(9, Vector2(80.0, 80.0)), "empty source ID disables pointer acquisition")
	joystick.source_id = &"joystick_primary"
