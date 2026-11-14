extends SceneTree
## RR-007 D1 tests for segment validation, placement and seeded reproducibility.
var failures: int = 0
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var scene_a := _make_segment_scene()
	var scene_b := _make_segment_scene()
	var definition_a := _make_definition(&"city_a", &"infected_city", 30.0, scene_a)
	var definition_b := _make_definition(&"city_b", &"infected_city", 45.0, scene_b)
	_check(definition_a.validate().is_empty(), "valid segment definition passes validation")
	var invalid := WorldSegmentDefinition.new()
	_check(not invalid.validate().is_empty(), "incomplete segment definition is rejected")
	var first := ProceduralWorldGenerator.new()
	first.segment_definitions = [definition_a, definition_b]
	first.initial_segment_count = 8
	first.world_seed = 77123
	root.add_child(first)
	await process_frame
	_check(first.generate_initial_segments() == OK, "generator creates initial segment sequence")
	_check(first.get_generated_segment_count() == 8, "generator creates requested segment count")
	var first_ids := first.get_generated_segment_ids()
	_check(first_ids.size() == 8, "generated segment identifiers are exposed")
	var first_positions: Array[Vector3] = []
	for child: Node in first.get_children():
		var segment := child as Node3D
		if segment != null:
			first_positions.append(segment.position)
	_check(first_positions.size() == 8, "all generated segments are placed")
	for index: int in range(1, first_positions.size()):
		_check(first_positions[index].z < first_positions[index - 1].z, "segments extend forward along local negative Z")
	first.clear_generated_segments()
	_check(first.get_generated_segment_count() == 0, "clear removes generated segment tracking")
	_check(first.generate_initial_segments() == OK, "same seed can regenerate a sequence")
	_check(first.get_generated_segment_ids() == first_ids, "same seed produces the same segment sequence")
	var second := ProceduralWorldGenerator.new()
	second.segment_definitions = [definition_a, definition_b]
	second.initial_segment_count = 8
	second.world_seed = 77123
	root.add_child(second)
	await process_frame
	_check(second.generate_initial_segments() == OK, "second generator creates seeded sequence")
	_check(second.get_generated_segment_ids() == first_ids, "independent generators reproduce the same seeded sequence")
	if failures == 0:
		print("RR-007 D1 procedural world generator: PASS")
		quit(0)
	else:
		push_error("RR-007 D1 procedural world generator: %d failure(s)" % failures)
		quit(1)
func _make_segment_scene() -> PackedScene:
	var segment_root := Node3D.new()
	var packed := PackedScene.new()
	var result := packed.pack(segment_root)
	segment_root.free()
	assert(result == OK)
	return packed
func _make_definition(identifier: StringName, theme: StringName, length: float, scene: PackedScene) -> WorldSegmentDefinition:
	var definition := WorldSegmentDefinition.new()
	definition.segment_id = identifier
	definition.theme_id = theme
	definition.segment_length = length
	definition.segment_scene = scene
	return definition
func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		failures += 1
		push_error("FAIL: %s" % description)
