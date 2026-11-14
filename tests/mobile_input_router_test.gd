extends SceneTree
## RR-006 D5 action routing and hero capability validation.

const HERO_PATHS: Array[String] = [
	"res://game/resources/characters/heroes/vanguard.tres",
	"res://game/resources/characters/heroes/phantom.tres",
	"res://game/resources/characters/heroes/cipher.tres",
]
const HERO_ABILITY_IDS: Array[StringName] = [&"bulwark", &"phase_shift", &"overclock"]
var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for index: int in range(HERO_PATHS.size()):
		await _test_hero_routing(HERO_PATHS[index], HERO_ABILITY_IDS[index])
	await _test_validation_and_context()
	if failures == 0:
		print("PASS: RR-006 D5 gameplay action router")
		quit(0)
	else:
		push_error("RR-006 D5 action router failures: %d" % failures)
		quit(1)


func _test_hero_routing(path: String, expected_ability: StringName) -> void:
	var scene := load("res://game/scenes/characters/character_actor.tscn") as PackedScene
	var definition := load(path) as CharacterDefinition
	_check(scene != null and definition != null, "%s hero and actor scene load" % String(expected_ability))
	if scene == null or definition == null:
		return
	var actor := scene.instantiate() as CharacterActor
	actor.definition = definition
	actor.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(actor)
	await process_frame
	var router := actor.get_node("MobileInputRouter") as MobileInputRouter
	var movement := actor.get_node("MovementController") as CharacterMovementController
	var combat := actor.get_node("HeroCombatController") as HeroCombatController
	_check(router != null and router.is_action_supported(MobileInputAction.Action.BASIC_ATTACK), "%s exposes configured basic attack capability" % String(expected_ability))
	_check(router.is_action_supported(MobileInputAction.Action.ABILITY_PRIMARY), "%s exposes its assigned primary ability" % String(expected_ability))
	_check(not router.is_action_supported(MobileInputAction.Action.ABILITY_SECONDARY), "%s does not expose an unassigned secondary ability" % String(expected_ability))

	movement.movement_mode = CharacterMovementController.MovementMode.FREE
	var move := _command(MobileInputAction.Action.MOVE, MobileInputAction.Phase.STARTED, &"test_move", 1)
	_check(router.route_command(move) == OK, "MOVE STARTED claims its source")
	move = _command(MobileInputAction.Action.MOVE, MobileInputAction.Phase.PERFORMED, &"test_move", 2)
	move.vector = Vector2(0.6, 0.8)
	_check(router.route_command(move) == OK and movement._move_intent.is_equal_approx(Vector2(0.6, 0.8)), "MOVE PERFORMED reaches movement controller")
	var competing := _command(MobileInputAction.Action.MOVE, MobileInputAction.Phase.PERFORMED, &"other_source", 1)
	competing.vector = Vector2.RIGHT
	_check(router.route_command(competing) == ERR_BUSY, "second movement source cannot overwrite active owner before D7 arbitration")
	var release := _command(MobileInputAction.Action.MOVE, MobileInputAction.Phase.CANCELED, &"test_move", 3)
	_check(router.route_command(release) == OK and movement._move_intent.is_zero_approx(), "MOVE CANCELED neutralizes only its owning source")

	var jump := _command(MobileInputAction.Action.JUMP, MobileInputAction.Phase.PERFORMED, &"jump", 1)
	_check(router.route_command(jump) == OK and movement._jump_requested, "JUMP dispatches to movement request API")
	movement._jump_requested = false
	movement.movement_mode = CharacterMovementController.MovementMode.LANE
	var lane := _command(MobileInputAction.Action.LANE_LEFT, MobileInputAction.Phase.PERFORMED, &"lane", 1)
	_check(router.route_command(lane) == OK and movement.lane_index == 0, "lane action dispatches in lane mode")
	_check(not router.is_action_supported(MobileInputAction.Action.MOVE), "free-vector MOVE is rejected in lane mode")

	var attack := _command(MobileInputAction.Action.BASIC_ATTACK, MobileInputAction.Phase.PERFORMED, &"attack", 1)
	_check(router.route_command(attack) == OK and combat != null, "BASIC_ATTACK dispatches to HeroCombatController")
	combat.get_node("../AttackExecutor").cancel_attack()

	var ability := _command(MobileInputAction.Action.ABILITY_PRIMARY, MobileInputAction.Phase.PERFORMED, &"ability", 1)
	ability.ability_id = expected_ability
	_check(router.route_command(ability) == OK and combat.is_ability_active(expected_ability), "primary ability dispatches only to the active hero's configured ability")
	var mismatch := _command(MobileInputAction.Action.ABILITY_PRIMARY, MobileInputAction.Phase.PERFORMED, &"ability_mismatch", 1)
	mismatch.ability_id = &"not_owned"
	_check(router.route_command(mismatch) == ERR_DOES_NOT_EXIST, "unowned ability ID is rejected")
	var unsupported := _command(MobileInputAction.Action.DODGE, MobileInputAction.Phase.PERFORMED, &"dodge", 1)
	_check(router.route_command(unsupported) == ERR_UNAVAILABLE, "reserved DODGE is explicitly unsupported")
	actor.queue_free()
	await process_frame


func _test_validation_and_context() -> void:
	var scene := load("res://game/scenes/characters/character_actor.tscn") as PackedScene
	var actor := scene.instantiate() as CharacterActor
	actor.definition = load(HERO_PATHS[0]) as CharacterDefinition
	actor.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(actor)
	await process_frame
	var router := actor.get_node("MobileInputRouter") as MobileInputRouter
	var pause_count := 0
	router.pause_requested.connect(func() -> void: pause_count += 1)
	var pause := _command(MobileInputAction.Action.PAUSE, MobileInputAction.Phase.PERFORMED, &"pause", 1)
	_check(router.route_command(pause) == OK and pause_count == 1, "PAUSE emits an integration signal for game-state owner")
	var interact := _command(MobileInputAction.Action.INTERACT, MobileInputAction.Phase.PERFORMED, &"interact", 1)
	_check(router.route_command(interact) == ERR_UNAVAILABLE, "INTERACT is rejected without an interaction owner")
	var duplicate := _command(MobileInputAction.Action.PAUSE, MobileInputAction.Phase.PERFORMED, &"pause", 1)
	_check(router.route_command(duplicate) == ERR_INVALID_DATA, "duplicate source sequence is rejected")
	router.set_gameplay_input_enabled(false)
	var blocked := _command(MobileInputAction.Action.PAUSE, MobileInputAction.Phase.PERFORMED, &"pause", 2)
	_check(router.route_command(blocked) == ERR_UNAVAILABLE, "disabled gameplay context rejects commands")
	actor.queue_free()
	await process_frame


func _command(action: int, phase: int, source: StringName, sequence: int) -> MobileInputCommand:
	var command := MobileInputCommand.new()
	command.action = action
	command.phase = phase
	command.mode = MobileInputAction.Mode.GUIDED
	command.source_id = source
	command.sequence_id = sequence
	command.strength = 1.0
	return command


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
	else:
		failures += 1
		push_error("FAIL: %s" % label)
