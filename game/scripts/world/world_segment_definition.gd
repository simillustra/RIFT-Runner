extends Resource
class_name WorldSegmentDefinition
## Authored modular world segment contract used by deterministic generation.
@export var segment_id: StringName
@export var theme_id: StringName
@export_range(1.0, 1000.0, 0.1) var segment_length: float = 40.0
@export var segment_scene: PackedScene

func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if segment_id == &"": errors.append("segment_id must not be empty.")
	if theme_id == &"": errors.append("theme_id must not be empty.")
	if segment_length <= 0.0: errors.append("segment_length must be greater than zero.")
	if segment_scene == null: errors.append("segment_scene must be assigned.")
	return errors
