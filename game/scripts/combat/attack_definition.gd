extends Resource
class_name AttackDefinition
## Immutable-at-runtime data contract for one combat attack.

@export var attack_id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export_range(0.01, 10000.0, 0.1) var damage: float = 10.0
@export var damage_type: StringName = &"physical"
@export_range(0.0, 10.0, 0.01) var startup_seconds: float = 0.15
@export_range(0.01, 10.0, 0.01) var active_seconds: float = 0.2
@export_range(0.0, 10.0, 0.01) var recovery_seconds: float = 0.35
@export_range(0.0, 60.0, 0.01) var cooldown_seconds: float = 0.4
@export var tags: PackedStringArray = []


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if attack_id == &"":
		errors.append("attack_id is required.")
	if display_name.strip_edges().is_empty():
		errors.append("display_name is required.")
	if damage <= 0.0:
		errors.append("damage must be greater than zero.")
	if damage_type == &"":
		errors.append("damage_type is required.")
	if startup_seconds < 0.0:
		errors.append("startup_seconds cannot be negative.")
	if active_seconds <= 0.0:
		errors.append("active_seconds must be greater than zero.")
	if recovery_seconds < 0.0:
		errors.append("recovery_seconds cannot be negative.")
	if cooldown_seconds < 0.0:
		errors.append("cooldown_seconds cannot be negative.")
	return errors
