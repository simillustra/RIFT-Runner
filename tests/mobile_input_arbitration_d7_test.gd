extends SceneTree
const HERO := "res://game/resources/characters/heroes/vanguard.tres"
var failures := 0
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var actor := (load("res://game/scenes/characters/character_actor.tscn") as PackedScene).instantiate() as CharacterActor
	actor.definition = load(HERO) as CharacterDefinition
	actor.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(actor)
	await process_frame
	var router := actor.get_node("MobileInputRouter") as MobileInputRouter
	var movement := actor.get_node("MovementController") as CharacterMovementController
	movement.movement_mode = CharacterMovementController.MovementMode.FREE
	_check(router.set_source_priority(&"joystick", 100) == OK and router.set_source_priority(&"gesture", 80) == OK, "priorities configure")
	_check(_move(router, &"gesture", 1, 2, Vector2.LEFT) == OK and _move(router, &"joystick", 1, 2, Vector2.RIGHT) == OK, "concurrent sources accepted")
	_check(router.get_active_move_source() == &"joystick" and movement._move_intent == Vector2.RIGHT, "higher priority wins")
	_check(_move(router, &"gesture", 2, 2, Vector2.UP) == OK and movement._move_intent == Vector2.RIGHT, "suppressed source updates safely")
	_check(_move(router, &"joystick", 2, 3) == OK and router.get_active_move_source() == &"gesture" and movement._move_intent == Vector2.UP, "cancel promotes fallback")
	_check(_move(router, &"gesture", 3, 3) == OK and movement._move_intent.is_zero_approx(), "last cancel neutralizes")
	_check(router.set_source_priority(&"alpha", 20) == OK and router.set_source_priority(&"beta", 20) == OK, "tie priorities configure")
	_check(_move(router, &"beta", 1, 2, Vector2.DOWN) == OK and _move(router, &"alpha", 1, 2, Vector2.LEFT) == OK and router.get_active_move_source() == &"alpha", "lexical tie-break is arrival-order independent")
	router.release_source(&"alpha")
	_check(router.get_active_move_source() == &"beta", "release promotes next source")
	router.clear_all_input()
	_check(movement._move_intent.is_zero_approx() and router.get_active_move_sources().is_empty(), "clear all resets movement")
	var executor := actor.get_node("AttackExecutor") as AttackExecutor
	var combat := actor.get_node("HeroCombatController") as HeroCombatController
	_check(combat.execute_basic_attack() == OK, "attack fixture locks executor")
	var buffered: Array[int] = [0]
	router.command_buffered.connect(func(_c: MobileInputCommand, _t: float) -> void: buffered[0] += 1)
	var attack := _command(MobileInputAction.Action.BASIC_ATTACK, &"tap", 1)
	_check(router.route_command(attack) == OK and buffered[0] == 1 and router.get_buffered_command_count() == 1, "busy discrete action is buffered")
	executor.cancel_attack()
	router.advance_input_time(0.01)
	_check(router.get_buffered_command_count() == 0 and executor.is_attack_active(), "buffer dispatches when available")
	executor.cancel_attack()
	_check(combat.execute_basic_attack() == OK, "expiry fixture locks executor")
	var expired: Array[int] = [0]
	router.command_buffer_expired.connect(func(_c: MobileInputCommand) -> void: expired[0] += 1)
	_check(router.route_command(_command(MobileInputAction.Action.BASIC_ATTACK, &"expiry", 1)) == OK and router.get_buffered_command_count() == 1, "second action buffered")
	router.advance_input_time(0.19)
	_check(expired[0] == 1 and router.get_buffered_command_count() == 0, "buffer expires on deterministic clock")
	executor.cancel_attack()
	_check(_move(router, &"life", 1, 2, Vector2.RIGHT) == OK, "lifecycle source active")
	router.set_gameplay_input_enabled(false)
	_check(movement._move_intent.is_zero_approx() and router.get_active_move_sources().is_empty() and router.get_buffered_command_count() == 0, "context disable clears active and buffered input")
	_check(router.route_command(_command(MobileInputAction.Action.PAUSE, &"blocked", 1)) == ERR_UNAVAILABLE, "disabled router rejects")
	router.set_gameplay_input_enabled(true)
	_check(_move(router, &"reuse", 1, 2, Vector2.RIGHT) == OK, "source starts")
	router.release_source(&"reuse")
	_check(_move(router, &"reuse", 1, 2, Vector2.LEFT) == OK, "release resets sequence watermark")
	router.clear_all_input()
	actor.queue_free()
	await process_frame
	if failures == 0: print("PASS: RR-006 D7"); quit(0)
	else: push_error("RR-006 D7 failures: %d" % failures); quit(1)
func _move(r: MobileInputRouter, s: StringName, seq: int, phase: int, v: Vector2 = Vector2.ZERO) -> Error:
	var c := _command(MobileInputAction.Action.MOVE, s, seq)
	c.phase = phase
	c.vector = v
	return r.route_command(c)
func _command(a: int, s: StringName, seq: int) -> MobileInputCommand:
	var c := MobileInputCommand.new()
	c.action = a
	c.phase = MobileInputAction.Phase.PERFORMED
	c.mode = MobileInputAction.Mode.GUIDED
	c.source_id = s
	c.sequence_id = seq
	return c
func _check(ok: bool, label: String) -> void:
	if ok: print("PASS: %s" % label)
	else: failures += 1; push_error("FAIL: %s" % label)
