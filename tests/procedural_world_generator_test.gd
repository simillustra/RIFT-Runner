extends SceneTree
## RR-007 D3 tests for connector alignment and obstacle/traversal/hazard sockets.
var failures: int = 0
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var definition_a := _make_definition(&"city_a", 30.0, _make_segment_scene(30.0))
	var definition_b := _make_definition(&"city_b", 45.0, _make_segment_scene(45.0))
	definition_a.obstacle_socket_paths = [NodePath("ObstacleSockets/Obstacle01")]
	definition_a.traversal_socket_paths = [NodePath("TraversalSockets/Traversal01")]
	definition_a.hazard_socket_paths = [NodePath("HazardSockets/Hazard01")]
	_check(definition_a.validate().is_empty(), "segment with connection and placement sockets validates")
	_check(definition_b.can_follow(definition_a), "matching connector profile is compatible")
	var incompatible := _make_definition(&"alien_gate", 35.0, _make_segment_scene(35.0))
	incompatible.entry_connector_id = &"wide_gate"
	_check(not incompatible.can_follow(definition_a), "mismatched connector profile is rejected")
	var invalid := WorldSegmentDefinition.new()
	_check(not invalid.validate().is_empty(), "incomplete segment definition is rejected")
	var first := ProceduralWorldGenerator.new()
	first.segment_definitions = [definition_a, definition_b]
	first.initial_segment_count = 8
	first.world_seed = 77123
	root.add_child(first)
	await process_frame
	_check(first.generate_initial_segments() == OK, "generator creates initial socket-aligned sequence")
	_check(first.get_generated_segment_count() == 8, "generator creates requested segment count")
	var first_ids := first.get_generated_segment_ids()
	var generated: Array[Node3D] = []
	for child: Node in first.get_children():
		var segment := child as Node3D
		if segment != null and segment.has_meta("segment_id"): generated.append(segment)
	_check(generated.size() == 8, "all generated segments are placed")
	for index: int in range(1, generated.size()):
		var previous_exit := generated[index - 1].get_node("ExitSocket") as Marker3D
		var current_entry := generated[index].get_node("EntrySocket") as Marker3D
		_check(previous_exit.global_transform.is_equal_approx(current_entry.global_transform), "adjacent segment sockets align exactly")
	var obstacle_sockets := first.get_placement_sockets(generated[0], &"obstacle")
	var traversal_sockets := first.get_placement_sockets(generated[0], &"traversal")
	var hazard_sockets := first.get_placement_sockets(generated[0], &"hazard")
	_check(obstacle_sockets.size() == 1, "obstacle placement socket is discoverable")
	_check(traversal_sockets.size() == 1, "traversal placement socket is discoverable")
	_check(hazard_sockets.size() == 1, "hazard placement socket is discoverable")
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
	var incompatible_only := ProceduralWorldGenerator.new()
	incompatible_only.segment_definitions = [incompatible]
	incompatible_only.initial_segment_count = 2
	root.add_child(incompatible_only)
	await process_frame
	_check(incompatible_only.generate_initial_segments() != OK, "generation fails safely when no compatible continuation exists")
	if failures == 0:
		print("RR-007 D3 placement sockets: PASS")
		quit(0)
	else:
		push_error("RR-007 D3 placement sockets: %d failure(s)" % failures)
		quit(1)
func _make_segment_scene(length: float) -> PackedScene:
	var root_node := Node3D.new()
	var entry := Marker3D.new()
	entry.name = "EntrySocket"
	root_node.add_child(entry)
	entry.owner = root_node
	var exit_socket := Marker3D.new()
	exit_socket.name = "ExitSocket"
	exit_socket.position = Vector3(0.0, 0.0, -length)
	root_node.add_child(exit_socket)
	exit_socket.owner = root_node
	for socket_group: String in ["ObstacleSockets", "TraversalSockets", "HazardSockets"]:
		var group_node := Node3D.new()
		group_node.name = socket_group
		root_node.add_child(group_node)
		group_node.owner = root_node
		var marker := Marker3D.new()
		marker.name = socket_group.trim_suffix("Sockets").trim_suffix("s") + "01"
		group_node.add_child(marker)
		marker.owner = root_node
	var packed := PackedScene.new()
	var result := packed.pack(root_node)
	root_node.free()
	assert(result == OK)
	return packed
func _make_definition(identifier: StringName, length: float, scene: PackedScene) -> WorldSegmentDefinition:
	var definition := WorldSegmentDefinition.new()
	definition.segment_id = identifier
	definition.theme_id = &"infected_city"
	definition.segment_length = length
	definition.segment_scene = scene
	return definition
func _check(condition: bool, description: String) -> void:
	if condition: print("PASS: %s" % description)
	else:
		failures += 1
		push_error("FAIL: %s" % description)
