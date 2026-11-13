extends Resource
class_name CharacterStats
## Data-only baseline attributes. Movement/combat systems consume these later.

@export_range(1.0, 10000.0, 1.0) var max_health: float = 100.0
@export_range(0.0, 1000.0, 0.1) var movement_speed: float = 5.0
@export_range(0.0, 1000.0, 0.1) var attack_power: float = 10.0
@export_range(0.0, 1000.0, 0.1) var defense: float = 5.0


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if max_health <= 0.0:
		errors.append("max_health must be greater than zero.")
	if movement_speed < 0.0:
		errors.append("movement_speed cannot be negative.")
	if attack_power < 0.0:
		errors.append("attack_power cannot be negative.")
	if defense < 0.0:
		errors.append("defense cannot be negative.")
	return errors
