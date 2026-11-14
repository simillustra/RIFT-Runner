extends SceneTree
## RR-006 D8 repeatable headless throughput diagnostic; timings are not device claims.

const HERO_PATH: String = "res://game/resources/characters/heroes/vanguard.tres"
const BATCH_COUNT: int = 100
const COMMANDS_PER_BATCH: int = 100
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var actor := (load("res://game/scenes/characters/character_actor.tscn") as PackedScene).instantiate() as CharacterActor
	actor.definition = load(HERO_PATH) as CharacterDefinition
	actor.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(actor)
	await process_frame
	var router := actor.get_node("MobileInputRouter") as MobileInputRouter
	var movement := actor.get_node("MovementController") as CharacterMovementController
	movement.movement_mode = CharacterMovementController.MovementMode.FREE

	var batch_samples: Array[int] = []
	var sequence: int = 0
	var total_commands: int = BATCH_COUNT * COMMANDS_PER_BATCH
	for batch in range(BATCH_COUNT):
		var started := Time.get_ticks_usec()
		for index in range(COMMANDS_PER_BATCH):
			sequence += 1
			var command := MobileInputCommand.new()
			command.action = MobileInputAction.Action.MOVE
			command.phase = MobileInputAction.Phase.PERFORMED
			command.mode = MobileInputAction.Mode.FREE_HAND
			command.vector = Vector2(0.6, 0.8)
			command.strength = 1.0
			command.source_id = &"d8_perf_source"
			command.sequence_id = sequence
			var result := router.route_command(command)
			if result != OK:
				failures += 1
		batch_samples.append(Time.get_ticks_usec() - started)

	batch_samples.sort()
	var total_usec: int = 0
	for sample in batch_samples:
		total_usec += sample
	var average_batch_usec: float = float(total_usec) / float(batch_samples.size())
	var p95_index: int = mini(batch_samples.size() - 1, int(ceil(float(batch_samples.size()) * 0.95)) - 1)
	var p95_batch_usec: int = batch_samples[p95_index]
	print("RR-006 D8 headless diagnostic: %d commands; avg batch=%0.2f us; p95 batch=%d us; batch size=%d" % [total_commands, average_batch_usec, p95_batch_usec, COMMANDS_PER_BATCH])
	_check(failures == 0, "all semantic commands route without errors")
	_check(router.get_buffered_command_count() == 0, "continuous movement never enters discrete action buffer")
	_check(router.get_active_move_source() == &"d8_perf_source", "movement source remains stable across throughput sample")
	router.clear_all_input()
	actor.queue_free()
	await process_frame
	if failures == 0:
		print("PASS: RR-006 D8 headless throughput diagnostic")
		quit(0)
	else:
		push_error("RR-006 D8 performance diagnostic routing failures: %d" % failures)
		quit(1)

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
	else:
		failures += 1
		push_error("FAIL: %s" % label)
