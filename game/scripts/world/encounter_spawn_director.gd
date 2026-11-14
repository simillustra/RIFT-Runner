extends Node
class_name EncounterSpawnDirector
## Produces deterministic spawn plans from authored segment anchors; it does not instantiate enemies.
@export var pacing_profile: EncounterPacingProfile
@export var world_seed: int = 1

func build_spawn_plan(segment: Node3D, segment_index: int, difficulty_level: int) -> Dictionary:
	if segment == null or not is_instance_valid(segment) or pacing_profile == null:
		return {"budget": 0, "spawn_points": [], "max_concurrent": 0, "seed": 0}
	if not pacing_profile.validate().is_empty():
		push_warning("EncounterSpawnDirector received an invalid pacing profile.")
		return {"budget": 0, "spawn_points": [], "max_concurrent": 0, "seed": 0}
	var definition := segment.get_meta("segment_definition", null) as WorldSegmentDefinition
	if definition == null:
		return {"budget": 0, "spawn_points": [], "max_concurrent": 0, "seed": 0}
	var anchors := definition.get_encounter_spawn_sockets(segment)
	var budget := pacing_profile.get_budget(segment_index, difficulty_level)
	var seed_value: int = world_seed ^ (segment_index * 73856093) ^ (difficulty_level * 19349663)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var shuffled: Array[Marker3D] = anchors.duplicate()
	for index: int in range(shuffled.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var temporary := shuffled[index]
		shuffled[index] = shuffled[swap_index]
		shuffled[swap_index] = temporary
	var requested_count := mini(pacing_profile.maximum_spawn_count, budget / pacing_profile.spawn_cost)
	var spawn_points: Array[Transform3D] = []
	for index: int in range(mini(requested_count, shuffled.size())):
		spawn_points.append(shuffled[index].global_transform)
	return {
		"budget": budget,
		"spawn_points": spawn_points,
		"max_concurrent": pacing_profile.maximum_concurrent_enemies,
		"seed": seed_value
	}
