extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_action_names()
	_test_modes_and_phases()
	_test_valid_movement_commands()
	_test_invalid_movement_vectors()
	_test_strength_validation()
	_test_action_payload_validation()
	_test_enum_and_lifecycle_validation()
	if _failures == 0:
		print("PASS: RR-006 D1 mobile input contract")
		quit(0)
	else:
		push_error("RR-006 D1 mobile input contract failures: %d" % _failures)
		quit(1)


func _assert(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
	else:
		_failures += 1
		push_error("FAIL: %s" % label)


func _command(action: int = MobileInputAction.Action.MOVE) -> MobileInputCommand:
	var command := MobileInputCommand.new()
	command.action = action
	return command


func _test_action_names() -> void:
	var expected := [
		&"move", &"jump", &"lane_left", &"lane_right", &"dodge",
		&"basic_attack", &"ability_primary", &"ability_secondary",
		&"interact", &"pause", &"cancel",
	]
	var all_match := true
	for index in range(expected.size()):
		if MobileInputAction.action_name(index) != expected[index]:
			all_match = false
	_assert(all_match, "all semantic actions have stable names")
	_assert(MobileInputAction.action_name(999) == &"unknown", "unknown action is explicit")


func _test_modes_and_phases() -> void:
	var command := _command()
	command.mode = MobileInputAction.Mode.GUIDED
	command.phase = MobileInputAction.Phase.STARTED
	var guided_valid := command.is_valid()
	command.mode = MobileInputAction.Mode.FREE_HAND
	command.phase = MobileInputAction.Phase.CANCELED
	_assert(guided_valid and command.is_valid(), "guided/free-hand modes and command phases are valid")


func _test_valid_movement_commands() -> void:
	var command := _command()
	command.vector = Vector2.ZERO
	var neutral_valid := command.is_valid()
	command.vector = Vector2(0.6, 0.8)
	_assert(neutral_valid and command.is_valid(), "zero and unit-length movement vectors are valid")


func _test_invalid_movement_vectors() -> void:
	var command := _command()
	command.vector = Vector2(1.01, 0.0)
	var over_length_rejected := not command.is_valid()
	command.vector = Vector2(INF, 0.0)
	var infinite_rejected := not command.is_valid()
	command.vector = Vector2(NAN, 0.0)
	_assert(over_length_rejected and infinite_rejected and not command.is_valid(), "over-length and non-finite movement vectors are rejected")


func _test_strength_validation() -> void:
	var command := _command()
	command.strength = 0.0
	var zero_valid := command.is_valid()
	command.strength = 1.0
	var one_valid := command.is_valid()
	command.strength = 1.01
	var over_rejected := not command.is_valid()
	command.strength = NAN
	_assert(zero_valid and one_valid and over_rejected and not command.is_valid(), "strength is finite and bounded to [0, 1]")


func _test_action_payload_validation() -> void:
	var command := _command(MobileInputAction.Action.BASIC_ATTACK)
	var attack_valid := command.is_valid()
	command.vector = Vector2.RIGHT
	var non_move_vector_rejected := not command.is_valid()
	command = _command(MobileInputAction.Action.ABILITY_PRIMARY)
	var missing_ability_rejected := not command.is_valid()
	command.ability_id = &"bulwark"
	_assert(attack_valid and non_move_vector_rejected and missing_ability_rejected and command.is_valid(), "non-move payload and ability ID rules are enforced")


func _test_enum_and_lifecycle_validation() -> void:
	var command := _command()
	command.action = 999
	var invalid_action_rejected := not command.is_valid()
	command = _command()
	command.phase = 999
	var invalid_phase_rejected := not command.is_valid()
	command = _command()
	command.mode = 999
	var invalid_mode_rejected := not command.is_valid()
	command = _command()
	command.sequence_id = -1
	var negative_sequence_rejected := not command.is_valid()
	command = _command()
	command.source_id = &""
	_assert(invalid_action_rejected and invalid_phase_rejected and invalid_mode_rejected and negative_sequence_rejected and not command.is_valid(), "invalid enums and lifecycle metadata are rejected")
