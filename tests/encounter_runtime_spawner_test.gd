extends SceneTree
## RR-007 D5.3 tests for plan-to-runtime enemy spawning and segment recycling.
var failures: int = 0

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
	var packed_segment := PackedScene.new()
	_check(packed_segment.pack(segment_root) == OK, "segment fixture packs")
	segment_root.free()

	var segment_definition := WorldSegmentDefinition.new()
	segment_definition.segment_id = &"runtime_spawn_fixture"
	segment_definition.theme_id = &"infected_city"
	segment_definition.segment_scene = packed_segment
	segment_definition.encounter_spawn_socket_paths = [
		NodePath("EncounterSpawns/Spawn0"), NodePath("EncounterSpawns/Spawn1"),
		NodePath("EncounterSpawns/Spawn2"), NodePath("EncounterSpawns/Spawn3")
	]
	var archetype := EnemyArchetypeProfile.new()
	archetype.archetype_id = &"fixture_pursuer"
	var enemy_definition := EnemySpawnDefinition.new()
	enemy_definition.definition_id = &"fixture_enemy"
	enemy_definition.enemy_scene = load("res://game/scenes/combat/enemy_combatant.tscn") as PackedScene
	enemy_definition.archetype_profile = archetype
	_check(enemy_definition.validate().is_empty(), "enemy scene and archetype definition validate")

	var generator := ProceduralWorldGenerator.new()
	generator.segment_definitions = [segment_definition]
	generator.initial_segment_count = 1
	generator.world_seed = 4455
	root.add_child(generator)
	var spawner := EncounterRuntimeSpawner.new()
	var director := EncounterSpawnDirector.new()
	director.pacing_profile = EncounterPacingProfile.new()
	director.pacing_profile.base_budget = 4
	spawner.spawn_director = director
	spawner.spawn_definitions = [enemy_definition]
	generator.add_child(spawner)
	await process_frame

	_check(generator.generate_initial_segments() == OK, "segment with authored encounter anchors generates")
	var segment := generator.get_generated_segment(0)
	_check(spawner.get_active_enemy_count(segment) == 2, "spawn plan instantiates enemies within budget and concurrency cap")
	var encounter := spawner.get_encounter_root(segment)
	_check(encounter != null, "spawned enemies belong to a segment-scoped encounter")
	var coordinator: EnemySquadCoordinator
	var first_enemy: Node3D = null
	if encounter != null:
		coordinator = encounter.get_node_or_null("EnemySquadCoordinator") as EnemySquadCoordinator
		for child: Node in encounter.get_children():
			if child is CharacterBody3D:
				first_enemy = child as Node3D
				break
	_check(coordinator != null, "encounter creates one shared squad coordinator")
	_check(first_enemy != null, "runtime enemy scene is instantiated")
	if first_enemy != null:
		var ai := first_enemy.get_node_or_null("EnemyAIController") as EnemyAIController
		var applied := first_enemy.get_node_or_null("EnemyArchetypeController") as EnemyArchetypeController
		_check(ai != null and ai.has_squad_coordinator(), "spawned AI receives encounter squad coordinator")
		_check(applied != null and applied.profile == archetype, "spawned enemy receives authored archetype profile")
		var health := first_enemy.get_node_or_null("HealthComponent") as HealthComponent
		_check(health != null and health.apply_damage(1000.0) > 0.0, "spawned enemy can enter the death state")

	spawner.release_segment(segment)
	await process_frame
	_check(spawner.get_active_enemy_count() == 0, "recycling segment releases active encounter")
	_check(spawner.get_pooled_enemy_count() == 2, "recycled enemies enter bounded pool")
	generator.segment_spawned.emit(segment, segment_definition)
	_check(spawner.get_active_enemy_count(segment) == 2, "subsequent encounter reuses pooled enemy instances")
	_check(spawner.get_pooled_enemy_count() == 0, "reused enemies leave the pool")
	var reused_encounter := spawner.get_encounter_root(segment)
	var reused_enemy: Node3D
	if reused_encounter != null:
		for child: Node in reused_encounter.get_children():
			if child is CharacterBody3D:
				reused_enemy = child as Node3D
				break
	if reused_enemy != null:
		var reused_health := reused_enemy.get_node_or_null("HealthComponent") as HealthComponent
		var reused_ai := reused_enemy.get_node_or_null("EnemyAIController") as EnemyAIController
		var reused_reactions := reused_enemy.get_node_or_null("CombatReactionController") as CombatReactionController
		_check(reused_health != null and not reused_health.is_dead and is_equal_approx(reused_health.current_health, reused_health.max_health), "pooled enemy health resets before reuse")
		_check(reused_ai != null and reused_ai.current_state == EnemyAIController.State.IDLE, "pooled enemy AI resets before reuse")
		_check(reused_reactions != null and not reused_reactions.is_dead(), "pooled enemy death presentation resets before reuse")
	generator.clear_generated_segments()
	await process_frame
	_check(spawner.get_pooled_enemy_count() == 0, "generation reset disposes pooled enemies")
	generator.queue_free()
	director.free()
	await process_frame
	if failures == 0:
		print("RR-007 D5.3 runtime encounter spawning: PASS")
		quit(0)
	else:
		push_error("RR-007 D5.3 runtime encounter spawning: %d failure(s)" % failures)
		quit(1)

func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		failures += 1
		push_error("FAIL: %s" % description)
