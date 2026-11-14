extends SceneTree
## RR-007 D5.4 repeatable CI-host microbenchmark for generation and bounded streaming.
## Timings are diagnostic only; device acceptance requires Android/iOS profiling.
const ITERATIONS: int = 20
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var definition := _make_definition()
	var generator := ProceduralWorldGenerator.new()
	generator.segment_definitions = [definition]
	generator.initial_segment_count = 5
	generator.world_seed = 20261114
	generator.segments_behind = 1
	generator.segments_ahead = 3
	generator.max_pooled_segments = 4
	root.add_child(generator)
	await process_frame
	var player := Node3D.new()
	root.add_child(player)
	var generation_samples: Array[int] = []
	var streaming_samples: Array[int] = []
	for iteration: int in range(ITERATIONS):
		generator.world_seed = 20261114 + iteration
		var start := Time.get_ticks_usec()
		var result := generator.generate_initial_segments()
		generation_samples.append(Time.get_ticks_usec() - start)
		_check(result == OK, "benchmark iteration %d generates initial segments" % iteration)
		player.global_position = Vector3(0.0, 0.0, -125.0)
		start = Time.get_ticks_usec()
		generator.stream_around_player(player)
		streaming_samples.append(Time.get_ticks_usec() - start)
		_check(generator.get_generated_segment_count() <= generator.initial_segment_count + generator.segments_ahead, "benchmark active segment count remains bounded")
		_check(generator.get_pooled_segment_count() <= generator.max_pooled_segments, "benchmark segment pool remains bounded")
		generator.clear_generated_segments()
	var generation_sorted := generation_samples.duplicate()
	var streaming_sorted := streaming_samples.duplicate()
	generation_sorted.sort()
	streaming_sorted.sort()
	print("PERF D5.4 CI-host us: generation_avg=%d generation_p95=%d streaming_avg=%d streaming_p95=%d iterations=%d" % [
		_average(generation_samples), _percentile95(generation_sorted),
		_average(streaming_samples), _percentile95(streaming_sorted), ITERATIONS
	])
	player.queue_free()
	generator.queue_free()
	await process_frame
	if failures == 0:
		print("RR-007 D5.4 performance smoke: PASS (diagnostic timings; not a device baseline)")
		quit(0)
	else:
		push_error("RR-007 D5.4 performance smoke: %d failure(s)" % failures)
		quit(1)

func _make_definition() -> WorldSegmentDefinition:
	var scene_root := Node3D.new()
	var entry := Marker3D.new()
	entry.name = "EntrySocket"
	scene_root.add_child(entry)
	entry.owner = scene_root
	var exit_socket := Marker3D.new()
	exit_socket.name = "ExitSocket"
	exit_socket.position = Vector3(0.0, 0.0, -40.0)
	scene_root.add_child(exit_socket)
	exit_socket.owner = scene_root
	var packed := PackedScene.new()
	var packed_result := packed.pack(scene_root)
	scene_root.free()
	assert(packed_result == OK)
	var result := WorldSegmentDefinition.new()
	result.segment_id = &"d54_perf_segment"
	result.theme_id = &"infected_city"
	result.segment_scene = packed
	return result

func _average(values: Array[int]) -> int:
	var total := 0
	for value: int in values:
		total += value
	return int(round(float(total) / float(maxi(values.size(), 1))))

func _percentile95(sorted_values: Array[int]) -> int:
	if sorted_values.is_empty():
		return 0
	var index := clampi(int(ceil(float(sorted_values.size()) * 0.95)) - 1, 0, sorted_values.size() - 1)
	return sorted_values[index]

func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		failures += 1
		push_error("FAIL: %s" % description)
