extends Resource
class_name WorldSegmentDefinition
## Authored modular world segment contract with compatible entry/exit sockets.
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
			if root.get_node_or_null(entry_socket_path) is not Marker3D:
				errors.append("entry_socket_path must resolve to a Marker3D.")
			if root.get_node_or_null(exit_socket_path) is not Marker3D:
				errors.append("exit_socket_path must resolve to a Marker3D.")
		instance.free()
	if entry_connector_id == &"": errors.append("entry_connector_id must not be empty.")
	if exit_connector_id == &"": errors.append("exit_connector_id must not be empty.")
	if entry_width <= 0.0 or exit_width <= 0.0: errors.append("Socket widths must be greater than zero.")
	if entry_height <= 0.0 or exit_height <= 0.0: errors.append("Socket heights must be greater than zero.")
	return errors

func can_follow(previous: WorldSegmentDefinition, tolerance: float = 0.01) -> bool:
	if previous == null:
		return true
	return previous.exit_connector_id == entry_connector_id and absf(previous.exit_width - entry_width) <= tolerance and absf(previous.exit_height - entry_height) <= tolerance
