extends Resource
class_name WorldSegmentDefinition
## Authored modular world segment contract with connection, gameplay and encounter sockets.
@export var segment_id: StringName
@export var theme_id: StringName
@export_range(1.0, 1000.0, 0.1) var segment_length: float = 40.0
@export var segment_scene: PackedScene
@export var entry_socket_path: NodePath = NodePath("EntrySocket")
@export var exit_socket_path: NodePath = NodePath("ExitSocket")
@export var entry_connector_id: StringName = &"standard"
@export var exit_connector_id: StringName = &"standard"
@export_range(0.1, 100.0, 0.1) var entry_width: float = 4.0
@export_range(0.1, 100.0, 0.1) var exit_width: float = 4.0
@export_range(0.1, 100.0, 0.1) var entry_height: float = 4.0
@export_range(0.1, 100.0, 0.1) var exit_height: float = 4.0
@export var obstacle_socket_paths: Array[NodePath] = []
@export var traversal_socket_paths: Array[NodePath] = []
@export var hazard_socket_paths: Array[NodePath] = []
@export var encounter_spawn_socket_paths: Array[NodePath] = []

func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if segment_id == &"": errors.append("segment_id must not be empty.")
	if theme_id == &"": errors.append("theme_id must not be empty.")
	if segment_length <= 0.0: errors.append("segment_length must be greater than zero.")
	if segment_scene == null:
		errors.append("segment_scene must be assigned.")
	else:
		var instance := segment_scene.instantiate()
		var root := instance as Node3D
		if root == null:
			errors.append("segment_scene root must inherit Node3D.")
		else:
			if root.get_node_or_null(entry_socket_path) is not Marker3D: errors.append("entry_socket_path must resolve to a Marker3D.")
			if root.get_node_or_null(exit_socket_path) is not Marker3D: errors.append("exit_socket_path must resolve to a Marker3D.")
			_validate_paths(root, obstacle_socket_paths, "obstacle", errors)
			_validate_paths(root, traversal_socket_paths, "traversal", errors)
			_validate_paths(root, hazard_socket_paths, "hazard", errors)
			_validate_paths(root, encounter_spawn_socket_paths, "encounter spawn", errors)
		instance.free()
	if entry_connector_id == &"": errors.append("entry_connector_id must not be empty.")
	if exit_connector_id == &"": errors.append("exit_connector_id must not be empty.")
	if entry_width <= 0.0 or exit_width <= 0.0: errors.append("Socket widths must be greater than zero.")
	if entry_height <= 0.0 or exit_height <= 0.0: errors.append("Socket heights must be greater than zero.")
	return errors

func can_follow(previous: WorldSegmentDefinition, tolerance: float = 0.01) -> bool:
	if previous == null: return true
	return previous.exit_connector_id == entry_connector_id and absf(previous.exit_width - entry_width) <= tolerance and absf(previous.exit_height - entry_height) <= tolerance

func get_placement_sockets(segment_root: Node3D, category: StringName) -> Array[Marker3D]:
	var paths: Array[NodePath] = []
	match category:
		&"obstacle": paths = obstacle_socket_paths
		&"traversal": paths = traversal_socket_paths
		&"hazard": paths = hazard_socket_paths
		_: return []
	return _resolve_paths(segment_root, paths)

func get_encounter_spawn_sockets(segment_root: Node3D) -> Array[Marker3D]:
	return _resolve_paths(segment_root, encounter_spawn_socket_paths)

func _resolve_paths(segment_root: Node3D, paths: Array[NodePath]) -> Array[Marker3D]:
	var sockets: Array[Marker3D] = []
	if segment_root == null or not is_instance_valid(segment_root): return sockets
	for path: NodePath in paths:
		var socket := segment_root.get_node_or_null(path) as Marker3D
		if socket != null: sockets.append(socket)
	return sockets

func _validate_paths(root: Node3D, paths: Array[NodePath], category: String, errors: PackedStringArray) -> void:
	for path: NodePath in paths:
		if path.is_empty() or root.get_node_or_null(path) is not Marker3D:
			errors.append("%s socket path '%s' must resolve to a Marker3D." % [category, String(path)])
