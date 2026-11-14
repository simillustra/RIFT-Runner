extends Resource
class_name EncounterPacingProfile
## Deterministic per-segment encounter budget. Values are authored design targets.
@export_range(0, 100, 1) var base_budget: int = 2
@export_range(0, 20, 1) var budget_per_segment: int = 1
@export_range(0, 20, 1) var budget_per_difficulty_level: int = 1
@export_range(0, 200, 1) var maximum_budget: int = 12
@export_range(1, 20, 1) var maximum_spawn_count: int = 5
@export_range(1, 20, 1) var maximum_concurrent_enemies: int = 4
@export_range(1, 20, 1) var spawn_cost: int = 2

func get_budget(segment_index: int, difficulty_level: int) -> int:
	var progression := maxi(segment_index, 0) * budget_per_segment
	var difficulty := maxi(difficulty_level, 0) * budget_per_difficulty_level
	return clampi(base_budget + progression + difficulty, 0, maximum_budget)

func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if maximum_budget < base_budget: errors.append("maximum_budget must be at least base_budget.")
	if spawn_cost < 1: errors.append("spawn_cost must be at least one.")
	if maximum_spawn_count < 1: errors.append("maximum_spawn_count must be at least one.")
	if maximum_concurrent_enemies < 1: errors.append("maximum_concurrent_enemies must be at least one.")
	return errors
