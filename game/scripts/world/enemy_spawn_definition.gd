extends Resource
class_name EnemySpawnDefinition
## Authored enemy scene and archetype pairing used by EncounterRuntimeSpawner.
@export var definition_id: StringName = &"infected_grunt"
@export var enemy_scene: PackedScene
@export var archetype_profile: EnemyArchetypeProfile
@export_range(1, 100, 1) var selection_weight: int = 1

func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if definition_id == &"":
		errors.append("definition_id must not be empty.")
	if enemy_scene == null:
		errors.append("enemy_scene must be assigned.")
	else:
		var instance := enemy_scene.instantiate()
		if not instance is Node3D:
			errors.append("enemy_scene root must inherit Node3D.")
		else:
			if instance.get_node_or_null("HealthComponent") is not HealthComponent:
				errors.append("enemy_scene must contain a HealthComponent child.")
			if instance.get_node_or_null("EnemyAIController") is not EnemyAIController:
				errors.append("enemy_scene must contain an EnemyAIController child.")
			if instance.get_node_or_null("EnemyArchetypeController") is not EnemyArchetypeController:
				errors.append("enemy_scene must contain an EnemyArchetypeController child.")
		instance.free()
	if archetype_profile == null:
		errors.append("archetype_profile must be assigned.")
	elif not archetype_profile.validate().is_empty():
		errors.append("archetype_profile is invalid.")
	if selection_weight < 1:
		errors.append("selection_weight must be at least one.")
	return errors
