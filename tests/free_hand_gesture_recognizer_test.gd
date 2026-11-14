extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_pointer_ownership()
	await _test_directional_swipes()
	await _test_threshold_and_dominant_axis()
	await _test_continuous_drag()
	await _test_cancellation_and_configuration()
	if _failures == 0:
		print("PASS: RR-006 D3 free-hand gesture recognizer")
		quit(0)
	else:
		push_error("RR-006 D3 free-hand gesture failures: %d" % _failures)
		quit(1)


func _assert(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
	else:
		_failures += 1
		push_error("FAIL: %s" % label)


func _new_recognizer() -> FreeHandGestureRecognizer:
	var recognizer := FreeHandGestureRecognizer.new()
	recognizer.size = Vector2(300.0, 300.0)
	root.add_child(recognizer)
	return recognizer


func _test_pointer_ownership() -> void:
	var recognizer := _new_recognizer()
	await process_frame
	_assert(recognizer.begin_pointer(1, Vector2(150.0, 150.0)), "pointer inside free-hand region acquires recognizer")
	_assert(not recognizer.begin_pointer(2, Vector2(150.0, 150.0)), "second pointer cannot steal active gesture")
	_assert(not recognizer.update_pointer(2, Vector2(240.0, 150.0)), "non-owner pointer cannot alter gesture")
	recognizer.end_pointer(1)
	_assert(not recognizer.has_active_pointer(), "pointer release clears gesture ownership")
	recognizer.queue_free()


func _test_directional_swipes() -> void:
	var recognizer := _new_recognizer()
	await process_frame
	var received: Array[MobileInputCommand] = []
	recognizer.command_emitted.connect(func(command: MobileInputCommand) -> void: received.append(command))
	var directions := [
		{"pointer": 10, "end": Vector2(70.0, 150.0), "action": MobileInputAction.Action.LANE_LEFT},
		{"pointer": 11, "end": Vector2(230.0, 150.0), "action": MobileInputAction.Action.LANE_RIGHT},
		{"pointer": 12, "end": Vector2(150.0, 70.0), "action": MobileInputAction.Action.JUMP},
		{"pointer": 13, "end": Vector2(150.0, 230.0), "action": MobileInputAction.Action.DODGE},
	]
	var all_mapped := true
	for item in directions:
		recognizer.begin_pointer(item.pointer, Vector2(150.0, 150.0))
		recognizer.update_pointer(item.pointer, item.end)
		recognizer.end_pointer(item.pointer)
		var count := received.size()
		if count < 2 or received[count - 1].action != item.action or received[count - 2].action != item.action:
			all_mapped = false
	_assert(all_mapped, "four cardinal swipes map through configurable action bindings")
	var valid_phases := received.size() == 8
	for index in range(0, received.size(), 2):
		valid_phases = valid_phases and received[index].phase == MobileInputAction.Phase.STARTED
		valid_phases = valid_phases and received[index + 1].phase == MobileInputAction.Phase.PERFORMED
		valid_phases = valid_phases and received[index].sequence_id < received[index + 1].sequence_id
		valid_phases = valid_phases and received[index].mode == MobileInputAction.Mode.FREE_HAND
	_assert(valid_phases, "swipes emit ordered FREE_HAND STARTED/PERFORMED command pairs")
	recognizer.queue_free()


func _test_threshold_and_dominant_axis() -> void:
	var recognizer := _new_recognizer()
	await process_frame
	var received: Array[MobileInputCommand] = []
	recognizer.command_emitted.connect(func(command: MobileInputCommand) -> void: received.append(command))
	recognizer.begin_pointer(20, Vector2(150.0, 150.0))
	recognizer.update_pointer(20, Vector2(190.0, 150.0))
	recognizer.end_pointer(20)
	_assert(received.is_empty(), "movement below swipe threshold is ignored")
	recognizer.begin_pointer(21, Vector2(150.0, 150.0))
	recognizer.update_pointer(21, Vector2(225.0, 205.0))
	recognizer.end_pointer(21)
	_assert(received.size() == 2 and received[0].action == MobileInputAction.Action.LANE_RIGHT, "diagonal swipe resolves to dominant horizontal axis")
	recognizer.queue_free()


func _test_continuous_drag() -> void:
	var recognizer := _new_recognizer()
	recognizer.gesture_profile = FreeHandGestureProfile.new()
	recognizer.gesture_profile.recognition_mode = FreeHandGestureProfile.RecognitionMode.CONTINUOUS_DRAG
	await process_frame
	var received: Array[MobileInputCommand] = []
	recognizer.command_emitted.connect(func(command: MobileInputCommand) -> void: received.append(command))
	recognizer.begin_pointer(30, Vector2(150.0, 150.0))
	recognizer.update_pointer(30, Vector2(155.0, 150.0))
	var below_activation := received.is_empty()
	recognizer.update_pointer(30, Vector2(210.0, 150.0))
	var first_vector := recognizer.get_output_vector()
	recognizer.update_pointer(30, Vector2(150.0, 30.0))
	var second_vector := recognizer.get_output_vector()
	recognizer.end_pointer(30)
	var valid := received.size() == 3
	if valid:
		valid = received[0].phase == MobileInputAction.Phase.STARTED
		valid = valid and received[1].phase == MobileInputAction.Phase.PERFORMED
		valid = valid and received[2].phase == MobileInputAction.Phase.CANCELED
		valid = valid and received[2].vector.is_zero_approx()
		valid = valid and received[0].mode == MobileInputAction.Mode.FREE_HAND
	_assert(below_activation, "drag activation threshold suppresses small motion")
	_assert(first_vector.x > 0.4 and absf(first_vector.y) < 0.001, "drag maps screen-right to positive X")
	_assert(second_vector.y > 0.9 and absf(second_vector.x) < 0.001, "drag maps screen-up to positive gameplay Y")
	_assert(valid, "continuous drag emits MOVE STARTED/PERFORMED/CANCELED lifecycle")
	recognizer.queue_free()


func _test_cancellation_and_configuration() -> void:
	var recognizer := _new_recognizer()
	recognizer.gesture_profile = FreeHandGestureProfile.new()
	recognizer.gesture_profile.recognition_mode = FreeHandGestureProfile.RecognitionMode.CONTINUOUS_DRAG
	await process_frame
	var received: Array[MobileInputCommand] = []
	recognizer.command_emitted.connect(func(command: MobileInputCommand) -> void: received.append(command))
	recognizer.begin_pointer(40, Vector2(150.0, 150.0))
	recognizer.update_pointer(40, Vector2(200.0, 150.0))
	recognizer.cancel_active_pointer()
	var canceled := received.size() == 2 and received[1].phase == MobileInputAction.Phase.CANCELED
	_assert(canceled and not recognizer.has_active_pointer(), "explicit cancellation neutralizes drag and releases pointer")
	recognizer.source_id = &""
	_assert(not recognizer.begin_pointer(41, Vector2(150.0, 150.0)), "empty source ID disables gesture acquisition")
	recognizer.source_id = &"gesture_free_hand"
	recognizer.gesture_profile.drag_full_scale_distance_px = 4.0
	recognizer.gesture_profile.drag_deadzone_px = 6.0
	_assert(not recognizer.is_enabled(), "invalid drag scale profile is rejected")
	recognizer.queue_free()
