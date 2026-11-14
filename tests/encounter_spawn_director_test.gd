extends SceneTree
## RR-007 D4 tests for deterministic encounter budget and authored spawn anchors.
var failures: int = 0
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var segment_root := Node3D.new()
	var entry_socket := Marker3D.new()
	entry_socket.name = "EntrySocket"
	segment_root.add_child(entry_socket)
	entry_socket.owner = segment_root
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
		marker.position = Vector3(float(index) * 2.0, 0.0, -4.0)
		anchors.add_child(marker)
		marker.owner = segment_root
	var packed := PackedScene.new()
	_check(packed.pack(segment_root) == OK, "encounter fixture packs")
	segment_root.free()
	var definition := WorldSegmentDefinition.new()
	definition.segment_id = &"encounter_fixture"
	definition.theme_id = &"infected_city"
	definition.segment_scene = packed
	definition.encounter_spawn_socket_paths = [
		NodePath("EncounterSpawns/Spawn0"), NodePath("EncounterSpawns/Spawn1"),
		NodePath("EncounterSpawns/Spawn2"), NodePath("EncounterSpawns/Spawn3")
	]
	_check(definition.validate().is_empty(), "authored encounter spawn anchors validate")
	var generator := ProceduralWorldGenerator.new()
	generator.segment_definitions = [definition]
	generator.initial_segment_count = 1
	root.add_child(generator)
	await process_frame
	_check(generator.generate_initial_segments() == OK, "segment with encounter anchors generates")
	var segment := generator.get_child(0) as Node3D
	var profile := EncounterPacingProfile.new()
	var director := EncounterSpawnDirector.new()
	director.pacing_profile = profile
	director.world_seed = 991
	var plan_a := director.build_spawn_plan(segment, 2, 1)
	var plan_b := director.build_spawn_plan(segment, 2, 1)
	_check(plan_a.budget == 5, "difficulty budget scales with segment and player difficulty")
	_check(plan_a.spawn_points.size() == 2, "spawn plan respects budget cost and authored anchor count")
	_check(plan_a.spawn_points == plan_b.spawn_points, "same inputs produce identical spawn transforms")
	_check(plan_a.max_concurrent == profile.maximum_concurrent_enemies, "plan carries concurrency cap")
	if failures == 0:
		print("RR-007 D4 encounter pacing: PASS")
		quit(0)
	else:
		push_error("RR-007 D4 encounter pacing: %d failure(s)" % failures)
		quit(1)
func _check(condition: bool, description: String) -> void:
	if condition: print("PASS: %s" % description)
	else:
		failures += 1
		push_error("FAIL: %s" % description)
