extends Node3D
class_name ProceduralWorldGenerator
## Deterministic segment composer. Each new entry socket aligns to the previous exit.
signal segment_spawned(segment: Node3D, definition: WorldSegmentDefinition)
signal generation_reset
@export var segment_definitions: Array[WorldSegmentDefinition] = []
@export_range(1, 100, 1) var initial_segment_count: int = 5
@export var world_seed: int = 1
@export var start_position: Vector3 = Vector3.ZERO
@export var generate_on_ready: bool = false
var _rng := RandomNumberGenerator.new()
var _generated_segments: Array[Node3D] = []
var _generated_segment_ids: Array[StringName] = []
var _last_definition: WorldSegmentDefinition
var _last_exit_socket: Marker3D

func _ready() -> void:
	if generate_on_ready: generate_initial_segments()

func set_world_seed(seed_value: int) -> void:
	world_seed = seed_value
	_rng.seed = world_seed

func validate_configuration() -> PackedStringArray:
	var errors := PackedStringArray()
	if segment_definitions.is_empty(): errors.append("At least one segment definition is required.")
	if initial_segment_count < 1: errors.append("initial_segment_count must be at least one.")
	var seen_ids: Dictionary = {}
	for definition: WorldSegmentDefinition in segment_definitions:
		if definition == null:
			errors.append("segment_definitions must not contain null entries.")
			continue
		for definition_error: String in definition.validate():
			errors.append("%s: %s" % [String(definition.segment_id), definition_error])
		if seen_ids.has(definition.segment_id): errors.append("Duplicate segment_id '%s'." % String(definition.segment_id))
		seen_ids[definition.segment_id] = true
	return errors

func generate_initial_segments() -> Error:
	var errors := validate_configuration()
	if not errors.is_empty():
		push_error("ProceduralWorldGenerator configuration is invalid: %s" % "; ".join(errors))
		return ERR_INVALID_DATA
	clear_generated_segments()
	_rng.seed = world_seed
	for _index: int in range(initial_segment_count):
		if append_next_segment() == null:
			clear_generated_segments()
			return ERR_CANT_CREATE
	return OK

func append_next_segment() -> Node3D:
	var candidates: Array[WorldSegmentDefinition] = []
	for definition: WorldSegmentDefinition in segment_definitions:
		if definition != null and definition.validate().is_empty() and definition.can_follow(_last_definition):
			candidates.append(definition)
	if candidates.is_empty():
		push_error("No valid segment definition is connector-compatible with the previous segment.")
		return null
	var selected: WorldSegmentDefinition = candidates[_rng.randi_range(0, candidates.size() - 1)]
	var instance: Node = selected.segment_scene.instantiate()
	var segment := instance as Node3D
	if segment == null:
		instance.free()
		push_error("Segment '%s' root must inherit Node3D." % String(selected.segment_id))
		return null
	var entry := segment.get_node_or_null(selected.entry_socket_path) as Marker3D
	var exit_socket := segment.get_node_or_null(selected.exit_socket_path) as Marker3D
	if entry == null or exit_socket == null:
		instance.free()
		push_error("Segment '%s' is missing its configured Marker3D sockets." % String(selected.segment_id))
		return null
	segment.name = StringName("%s_%d" % [String(selected.segment_id), _generated_segments.size()])
	add_child(segment)
	if _last_exit_socket == null:
		segment.global_transform = global_transform * Transform3D(Basis.IDENTITY, start_position)
	else:
		var entry_in_root := segment.global_transform.affine_inverse() * entry.global_transform
		segment.global_transform = _last_exit_socket.global_transform * entry_in_root.affine_inverse()
	segment.set_meta("segment_id", selected.segment_id)
	segment.set_meta("theme_id", selected.theme_id)
	_generated_segments.append(segment)
	_generated_segment_ids.append(selected.segment_id)
	_last_definition = selected
	_last_exit_socket = exit_socket
	segment_spawned.emit(segment, selected)
	return segment

func clear_generated_segments() -> void:
	for segment: Node3D in _generated_segments:
		if is_instance_valid(segment): segment.queue_free()
	_generated_segments.clear()
	_generated_segment_ids.clear()
	_last_definition = null
	_last_exit_socket = null
	generation_reset.emit()

func get_generated_segment_count() -> int:
	return _generated_segments.size()

func get_generated_segment_ids() -> Array[StringName]:
	return _generated_segment_ids.duplicate()

func get_last_exit_socket() -> Marker3D:
	return _last_exit_socket
