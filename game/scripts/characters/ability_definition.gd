extends Resource
class_name AbilityDefinition
## Descriptive ability metadata only. Execution belongs to a future ability system.

@export var ability_id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export_range(0.0, 600.0, 0.1) var cooldown_seconds: float = 0.0
@export_range(0.0, 600.0, 0.1) var duration_seconds: float = 0.0
@export var tags: PackedStringArray = []


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if ability_id == &"":
		errors.append("ability_id is required.")
	if display_name.strip_edges().is_empty():
		errors.append("display_name is required.")
	if cooldown_seconds < 0.0:
		errors.append("cooldown_seconds cannot be negative.")
	if duration_seconds < 0.0:
		errors.append("duration_seconds cannot be negative.")
	return errors
