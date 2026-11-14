extends Node3D
class_name ProceduralWorldGenerator
## Deterministic, seed-driven linear segment composer. Segments extend along local -Z.
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
var _next_segment_offset: float = 0.0

func _ready() -> void:
	if generate_on_ready:
		generate_initial_segments()

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
		if seen_ids.has(definition.segment_id):
			errors.append("Duplicate segment_id '%s'." % String(definition.segment_id))
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
		if definition != null and definition.validate().is_empty():
			candidates.append(definition)
	if candidates.is_empty():
		push_error("ProceduralWorldGenerator has no valid segment definitions.")
		return null
	var selected: WorldSegmentDefinition = candidates[_rng.randi_range(0, candidates.size() - 1)]
	var instance: Node = selected.segment_scene.instantiate()
	var segment := instance as Node3D
	if segment == null:
		instance.free()
		push_error("Segment '%s' root must inherit Node3D." % String(selected.segment_id))
		return null
	segment.name = StringName("%s_%d" % [String(selected.segment_id), _generated_segments.size()])
	add_child(segment)
	segment.position = start_position + Vector3(0.0, 0.0, -_next_segment_offset)
	segment.set_meta("segment_id", selected.segment_id)
	segment.set_meta("theme_id", selected.theme_id)
	_generated_segments.append(segment)
	_generated_segment_ids.append(selected.segment_id)
	_next_segment_offset += selected.segment_length
	segment_spawned.emit(segment, selected)
	return segment

func clear_generated_segments() -> void:
	for segment: Node3D in _generated_segments:
		if is_instance_valid(segment):
			segment.queue_free()
	_generated_segments.clear()
	_generated_segment_ids.clear()
	_next_segment_offset = 0.0
	generation_reset.emit()

func get_generated_segment_count() -> int:
	return _generated_segments.size()

func get_generated_segment_ids() -> Array[StringName]:
	return _generated_segment_ids.duplicate()
