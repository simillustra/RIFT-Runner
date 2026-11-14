extends Resource
class_name EnemyArchetypeProfile
## Data-only tuning and engagement policy for a local enemy archetype.
enum EngagementPolicy { PURSUER, SKIRMISHER, RANGED }
@export var archetype_id: StringName = &"infected_grunt"
@export_range(0.5, 100.0, 0.1) var detection_range: float = 12.0
@export_range(0.5, 100.0, 0.1) var attack_range: float = 2.0
@export_range(0.5, 150.0, 0.1) var lose_target_range: float = 18.0
@export_range(0.1, 20.0, 0.1) var move_speed: float = 3.5
@export_range(0.1, 10.0, 0.1) var preferred_attack_distance: float = 1.6
@export_range(0.1, 20.0, 0.1) var acceleration: float = 12.0
@export_range(0.1, 30.0, 0.1) var turn_speed: float = 10.0
@export var engagement_policy: EngagementPolicy = EngagementPolicy.PURSUER
@export var can_retreat: bool = true

func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if archetype_id == &"": errors.append("archetype_id must not be empty.")
	if attack_range > detection_range: errors.append("attack_range must not exceed detection_range.")
	if lose_target_range < detection_range: errors.append("lose_target_range must be at least detection_range.")
	if preferred_attack_distance <= 0.0: errors.append("preferred_attack_distance must be positive.")
	return errors
