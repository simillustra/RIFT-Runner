extends SceneTree
## RR-007 D5.1 tests for bounded streaming, pooling, and safe cleanup.
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var definition := _make_definition(&"stream_test", 30.0)
	var generator := ProceduralWorldGenerator.new()
	generator.segment_definitions = [definition]
	generator.initial_segment_count = 4
	generator.world_seed = 9001
	generator.segments_behind = 1
	generator.segments_ahead = 2
	generator.max_pooled_segments = 4
	root.add_child(generator)
	await process_frame
	_check(generator.generate_initial_segments() == OK, "initial segment window generates")
	_check(generator.get_generated_segment_count() == 4, "initial window has four segments")
	var first_segment := _find_segment(generator, 0)
	var first_instance_id := first_segment.get_instance_id()
	var player := Node3D.new()
	root.add_child(player)
	player.global_position = Vector3(0.0, 0.0, -105.0)
	generator.stream_around_player(player)
	_check(generator.get_generated_segment_count() == 4, "streaming maintains bounded active window")
	_check(generator.get_generated_segment_ids().size() == 4, "active segment index remains synchronized")
	_check(_contains_instance(generator, first_instance_id), "pooled segment instance is reused for the same definition")
	_check(generator.get_pooled_segment_count() == 0, "reused instances leave the pool")
	var active_before := generator.get_generated_segment_count()
	player.global_position = Vector3(0.0, 0.0, -100000.0)
	generator.stream_around_player(player)
	_check(generator.get_generated_segment_count() <= active_before, "streaming stops safely when no compatible continuation exists")
	generator.clear_generated_segments()
	_check(generator.get_generated_segment_count() == 0, "clear removes active segment tracking")
	_check(generator.get_pooled_segment_count() == 0, "clear disposes pooled instances")
	player.queue_free()
	generator.queue_free()
	if failures == 0:
		print("RR-007 D5.1 runtime streaming and pooling: PASS")
		quit(0)
	else:
		push_error("RR-007 D5.1 runtime streaming and pooling: %d failure(s)" % failures)
		quit(1)

func _make_definition(identifier: StringName, length: float) -> WorldSegmentDefinition:
	var scene_root := Node3D.new()
	var entry := Marker3D.new()
	entry.name = "EntrySocket"
	scene_root.add_child(entry)
	entry.owner = scene_root
	var exit_socket := Marker3D.new()
	exit_socket.name = "ExitSocket"
	exit_socket.position = Vector3(0.0, 0.0, -length)
	scene_root.add_child(exit_socket)
	exit_socket.owner = scene_root
	var packed := PackedScene.new()
	var pack_result := packed.pack(scene_root)
	scene_root.free()
	assert(pack_result == OK)
	var definition := WorldSegmentDefinition.new()
	definition.segment_id = identifier
	definition.theme_id = &"stream_test"
	definition.segment_length = length
	definition.segment_scene = packed
	return definition

func _find_segment(generator: ProceduralWorldGenerator, index: int) -> Node3D:
	var segments: Array[Node3D] = []
	for child: Node in generator.get_children():
		var segment := child as Node3D
		if segment != null and segment.has_meta("segment_definition"):
			segments.append(segment)
	return segments[index] if index < segments.size() else null

func _contains_instance(generator: ProceduralWorldGenerator, instance_id: int) -> bool:
	for child: Node in generator.get_children():
		if child.get_instance_id() == instance_id:
			return true
	return false

func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		failures += 1
		push_error("FAIL: %s" % description)
