extends SceneTree
## RR-007/008 D5.4 end-to-end streaming, encounter, squad and recycle validation.
var failures: int = 0
var spawned_events: int = 0
var released_events: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var segment_root := Node3D.new()
	var entry := Marker3D.new()
	entry.name = "EntrySocket"
	segment_root.add_child(entry)
	entry.owner = segment_root
	var exit_socket := Marker3D.new()
	exit_socket.name = "ExitSocket"
	exit_socket.position = Vector3(0.0, 0.0, -40.0)
	segment_root.add_child(exit_socket)
	exit_socket.owner = segment_root
	var anchors := Node3D.new()
	anchors.name = "EncounterSpawns"
	segment_root.add_child(anchors)
	anchors.owner = segment_root
	for index: int in range(4):
		var marker := Marker3D.new()
		marker.name = "Spawn%d" % index
		marker.position = Vector3(float(index) * 2.0, 0.0, -5.0)
		anchors.add_child(marker)
		marker.owner = segment_root
	var packed := PackedScene.new()
	_check(packed.pack(segment_root) == OK, "authored segment fixture packs")
	segment_root.free()

	var segment_definition := WorldSegmentDefinition.new()
	segment_definition.segment_id = &"d54_integration_segment"
	segment_definition.theme_id = &"infected_city"
	segment_definition.segment_scene = packed
	segment_definition.entry_socket_path = NodePath("EntrySocket")
	segment_definition.exit_socket_path = NodePath("ExitSocket")
	segment_definition.encounter_spawn_socket_paths = [
		NodePath("EncounterSpawns/Spawn0"), NodePath("EncounterSpawns/Spawn1"),
		NodePath("EncounterSpawns/Spawn2"), NodePath("EncounterSpawns/Spawn3")
	]
	_check(segment_definition.validate().is_empty(), "segment definition and all encounter anchors validate: %s" % str(segment_definition.validate()))

	var enemy_definition := EnemySpawnDefinition.new()
	enemy_definition.definition_id = &"d54_integration_enemy"
	enemy_definition.enemy_scene = load("res://game/scenes/combat/enemy_combatant.tscn") as PackedScene
	enemy_definition.archetype_profile = EnemyArchetypeProfile.new()
	enemy_definition.archetype_profile.archetype_id = &"d54_pursuer"
	_check(enemy_definition.validate().is_empty(), "enemy definition validates")

	var generator := ProceduralWorldGenerator.new()
	generator.segment_definitions = [segment_definition]
	generator.initial_segment_count = 3
	generator.world_seed = 20261114
	generator.segments_behind = 0
	generator.segments_ahead = 2
	generator.max_pooled_segments = 3
	root.add_child(generator)

	var spawner := EncounterRuntimeSpawner.new()
	var director := EncounterSpawnDirector.new()
	director.pacing_profile = EncounterPacingProfile.new()
	spawner.spawn_director = director
	spawner.spawn_definitions = [enemy_definition]
	spawner.max_pooled_enemies = 8
	generator.add_child(spawner)
	spawner.enemy_spawned.connect(_on_enemy_spawned)
	spawner.encounter_released.connect(_on_encounter_released)
	await process_frame

	var start_usec := Time.get_ticks_usec()
	_check(generator.generate_initial_segments() == OK, "world generation succeeds")
	var generation_usec := Time.get_ticks_usec() - start_usec
	_check(generator.get_generated_segment_count() == 3, "initial streaming window contains three segments")
	_check(spawner.get_active_enemy_count() > 0, "encounter plans materialize live enemies")
	_check(spawner.get_active_enemy_count() <= 12, "active enemy count respects authored encounter caps")

	var segment := generator.get_generated_segment(0)
	var encounter := spawner.get_encounter_root(segment)
	_check(encounter != null, "generated segment owns its encounter runtime")
	var coordinator: EnemySquadCoordinator
	var enemy: Node3D
	if encounter != null:
		coordinator = encounter.get_node_or_null("EnemySquadCoordinator") as EnemySquadCoordinator
		for child: Node in encounter.get_children():
			if child is CharacterBody3D:
				enemy = child as Node3D
				break
	_check(coordinator != null, "runtime encounter creates one shared squad coordinator")
	_check(enemy != null, "runtime encounter contains an enemy actor")
	if enemy != null:
		var ai := enemy.get_node_or_null("EnemyAIController") as EnemyAIController
		var health := enemy.get_node_or_null("HealthComponent") as HealthComponent
		_check(ai != null and ai.has_squad_coordinator(), "spawned enemy is registered with squad coordination")
		_check(health != null and health.apply_damage(1.0) > 0.0, "spawned enemy accepts combat damage")

	var player := Node3D.new()
	root.add_child(player)
	player.global_position = Vector3(0.0, 0.0, -100.0)
	var stream_start_usec := Time.get_ticks_usec()
	generator.stream_around_player(player)
	var stream_usec := Time.get_ticks_usec() - stream_start_usec
	_check(generator.get_generated_segment_count() == 3, "streaming keeps the active segment window bounded")
	_check(generator.get_pooled_segment_count() <= generator.max_pooled_segments, "segment pool stays within configured capacity")
	_check(released_events >= 1, "recycling releases the old encounter")
	_check(spawned_events > 0, "streamed segments activate encounter spawning")
	_check(spawner.get_active_enemy_count() <= 12, "streamed world keeps active enemy population bounded")
	_check(spawner.get_pooled_enemy_count() <= spawner.max_pooled_enemies, "enemy pool stays within configured capacity")

	print("PERF D5.4 CI-host diagnostic: initial_generation_us=%d stream_cycle_us=%d" % [generation_usec, stream_usec])
	print("PERF D5.4 counts: active_segments=%d pooled_segments=%d active_enemies=%d pooled_enemies=%d" % [
		generator.get_generated_segment_count(), generator.get_pooled_segment_count(),
		spawner.get_active_enemy_count(), spawner.get_pooled_enemy_count()
	])
	generator.clear_generated_segments()
	_check(spawner.get_active_enemy_count() == 0, "generation reset releases all active encounter ownership")
	_check(spawner.get_pooled_enemy_count() == 0, "generation reset disposes pooled enemies")
	player.queue_free()
	generator.queue_free()
	director.free()
	await process_frame
	if failures == 0:
		print("RR-007/008 D5.4 integration validation: PASS")
		quit(0)
	else:
		push_error("RR-007/008 D5.4 integration validation: %d failure(s)" % failures)
		quit(1)

func _on_enemy_spawned(_enemy: Node3D, _definition: EnemySpawnDefinition, _segment: Node3D) -> void:
	spawned_events += 1

func _on_encounter_released(_segment: Node3D, _pooled_count: int) -> void:
	released_events += 1

func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		failures += 1
		push_error("FAIL: %s" % description)
