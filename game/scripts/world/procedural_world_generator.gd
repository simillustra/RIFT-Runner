extends Node3D
class_name ProceduralWorldGenerator
## Deterministic segment composer with bounded runtime streaming and definition-aware pooling.

signal segment_spawned(segment: Node3D, definition: WorldSegmentDefinition)
signal segment_recycled(segment: Node3D, definition: WorldSegmentDefinition)
signal generation_reset
signal streaming_updated(player_segment_index: int, active_segment_count: int, pooled_segment_count: int)

@export var segment_definitions: Array[WorldSegmentDefinition] = []
@export_range(1, 100, 1) var initial_segment_count: int = 5
@export var world_seed: int = 1
@export var start_position: Vector3 = Vector3.ZERO
@export var generate_on_ready: bool = false
@export_group("Runtime streaming")
@export var streaming_enabled: bool = false
@export var player_path: NodePath
@export_range(0, 8, 1) var segments_behind: int = 2
@export_range(1, 16, 1) var segments_ahead: int = 5
@export_range(0, 32, 1) var max_pooled_segments: int = 8

var _rng := RandomNumberGenerator.new()
var _generated_segments: Array[Node3D] = []
var _generated_segment_ids: Array[StringName] = []
var _last_definition: WorldSegmentDefinition
var _last_exit_socket: Marker3D
var _pool_root: Node3D
var _pool_by_definition: Dictionary = {}
var _pooled_segment_count: int = 0

func _ready() -> void:
	_ensure_pool_root()
	if generate_on_ready:
		generate_initial_segments()

func _physics_process(_delta: float) -> void:
	if not streaming_enabled or player_path.is_empty():
		return
	var player := get_node_or_null(player_path) as Node3D
	if player != null:
		stream_around_player(player)

func set_world_seed(seed_value: int) -> void:
	world_seed = seed_value
	_rng.seed = world_seed

func validate_configuration() -> PackedStringArray:
	var errors := PackedStringArray()
	if segment_definitions.is_empty():
		errors.append("At least one segment definition is required.")
	if initial_segment_count < 1:
		errors.append("initial_segment_count must be at least one.")
	if segments_ahead < 1:
		errors.append("segments_ahead must be at least one.")
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
		if definition != null and definition.validate().is_empty() and definition.can_follow(_last_definition):
			candidates.append(definition)
	if candidates.is_empty():
		push_error("No valid segment definition is connector-compatible with the previous segment.")
		return null
	var selected: WorldSegmentDefinition = candidates[_rng.randi_range(0, candidates.size() - 1)]
	var segment := _acquire_segment(selected)
	if segment == null:
		return null
	var entry := segment.get_node_or_null(selected.entry_socket_path) as Marker3D
	var exit_socket := segment.get_node_or_null(selected.exit_socket_path) as Marker3D
	if entry == null or exit_socket == null:
		_discard_segment(segment)
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
	segment.set_meta("segment_definition", selected)
	_generated_segments.append(segment)
	_generated_segment_ids.append(selected.segment_id)
	_last_definition = selected
	_last_exit_socket = exit_socket
	if bool(segment.get_meta("_pool_reused", false)):
		if segment.has_method("reset_from_pool"):
			segment.call("reset_from_pool")
		segment.remove_meta("_pool_reused")
	if segment.has_method("on_segment_activated"):
		segment.call("on_segment_activated")
	segment_spawned.emit(segment, selected)
	return segment

## Keeps a bounded window around the segment nearest to the player.
## Call explicitly in tests/tools, or enable streaming_enabled + player_path at runtime.
func stream_around_player(player: Node3D) -> void:
	if player == null or not is_instance_valid(player) or _generated_segments.is_empty():
		return
	var player_index := _find_nearest_segment_index(player.global_position)
	if player_index < 0:
		return
	while player_index > segments_behind and not _generated_segments.is_empty():
		_recycle_oldest_segment()
		player_index -= 1
	while _generated_segments.size() <= player_index + segments_ahead:
		if append_next_segment() == null:
			break
	streaming_updated.emit(player_index, _generated_segments.size(), _pooled_segment_count)

func clear_generated_segments() -> void:
	for segment: Node3D in _generated_segments:
		if is_instance_valid(segment):
			_discard_segment(segment)
	_generated_segments.clear()
	_generated_segment_ids.clear()
	_last_definition = null
	_last_exit_socket = null
	_clear_pool()
	generation_reset.emit()

func get_generated_segment_count() -> int:
	return _generated_segments.size()

func get_generated_segment_ids() -> Array[StringName]:
	return _generated_segment_ids.duplicate()

func get_last_exit_socket() -> Marker3D:
	return _last_exit_socket

func get_pooled_segment_count() -> int:
	return _pooled_segment_count

func get_placement_sockets(segment: Node3D, category: StringName) -> Array[Marker3D]:
	var definition := _get_segment_definition(segment)
	if definition == null:
		return []
	return definition.get_placement_sockets(segment, category)

func get_encounter_spawn_sockets(segment: Node3D) -> Array[Marker3D]:
	var definition := _get_segment_definition(segment)
	if definition == null:
		return []
	return definition.get_encounter_spawn_sockets(segment)

func _find_nearest_segment_index(world_position: Vector3) -> int:
	var nearest_index := -1
	var nearest_distance_squared := INF
	for index: int in range(_generated_segments.size()):
		var segment := _generated_segments[index]
		if not is_instance_valid(segment):
			continue
		var definition := _get_segment_definition(segment)
		if definition == null:
			continue
		var entry := segment.get_node_or_null(definition.entry_socket_path) as Marker3D
		var exit_socket := segment.get_node_or_null(definition.exit_socket_path) as Marker3D
		if entry == null or exit_socket == null:
			continue
		var midpoint := (entry.global_position + exit_socket.global_position) * 0.5
		var distance_squared := world_position.distance_squared_to(midpoint)
		if distance_squared < nearest_distance_squared:
			nearest_distance_squared = distance_squared
			nearest_index = index
	return nearest_index

func _recycle_oldest_segment() -> void:
	if _generated_segments.is_empty():
		return
	var segment := _generated_segments.pop_front()
	_generated_segment_ids.pop_front()
	if not is_instance_valid(segment):
		return
	var definition := _get_segment_definition(segment)
	if definition == null:
		_discard_segment(segment)
		return
	if segment.has_method("prepare_for_pool"):
		segment.call("prepare_for_pool")
	if not segment.has_meta("_pool_original_process_mode"):
		segment.set_meta("_pool_original_process_mode", segment.process_mode)
		segment.set_meta("_pool_original_process_enabled", segment.is_processing())
		segment.set_meta("_pool_original_physics_enabled", segment.is_physics_processing())
	if segment.get_parent() != null:
		segment.get_parent().remove_child(segment)
	segment.process_mode = Node.PROCESS_MODE_DISABLED
	segment.set_process(false)
	segment.set_physics_process(false)
	segment.visible = false
	segment.transform = Transform3D.IDENTITY
	var key: StringName = definition.segment_id
	if _pooled_segment_count >= max_pooled_segments:
		segment.queue_free()
	else:
		_ensure_pool_root()
		_pool_root.add_child(segment)
		var bucket: Array = _pool_by_definition.get(key, [])
		bucket.append(segment)
		_pool_by_definition[key] = bucket
		_pooled_segment_count += 1
	segment_recycled.emit(segment, definition)

func _acquire_segment(definition: WorldSegmentDefinition) -> Node3D:
	_ensure_pool_root()
	var key: StringName = definition.segment_id
	var bucket: Array = _pool_by_definition.get(key, [])
	if not bucket.is_empty():
		var segment := bucket.pop_back() as Node3D
		_pool_by_definition[key] = bucket
		_pooled_segment_count -= 1
		_pool_root.remove_child(segment)
		segment.process_mode = int(segment.get_meta("_pool_original_process_mode", Node.PROCESS_MODE_INHERIT))
		segment.visible = true
		segment.set_process(bool(segment.get_meta("_pool_original_process_enabled", true)))
		segment.set_physics_process(bool(segment.get_meta("_pool_original_physics_enabled", true)))
		segment.set_meta("_pool_reused", true)
		return segment
	var instance := definition.segment_scene.instantiate()
	var segment := instance as Node3D
	if segment == null:
		instance.free()
		push_error("Segment '%s' root must inherit Node3D." % String(definition.segment_id))
		return null
	return segment

func _discard_segment(segment: Node3D) -> void:
	if segment == null or not is_instance_valid(segment):
		return
	if segment.get_parent() != null:
		segment.get_parent().remove_child(segment)
	segment.free()

func _clear_pool() -> void:
	if _pool_root != null and is_instance_valid(_pool_root):
		for child: Node in _pool_root.get_children():
			_pool_root.remove_child(child)
			child.free()
	_pool_by_definition.clear()
	_pooled_segment_count = 0

func _ensure_pool_root() -> void:
	if _pool_root != null and is_instance_valid(_pool_root):
		return
	_pool_root = Node3D.new()
	_pool_root.name = "SegmentPool"
	add_child(_pool_root)

func _get_segment_definition(segment: Node3D) -> WorldSegmentDefinition:
	if segment == null or not is_instance_valid(segment):
		return null
	var definition := segment.get_meta("segment_definition", null) as WorldSegmentDefinition
	if definition != null:
		return definition
	var segment_id: StringName = segment.get_meta("segment_id", &"")
	for candidate: WorldSegmentDefinition in segment_definitions:
		if candidate != null and candidate.segment_id == segment_id:
			return candidate
	return null
