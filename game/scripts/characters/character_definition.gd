extends Resource
class_name CharacterDefinition
## Data-driven character identity, stats, basic combat move and ability metadata.

@export var character_id: StringName = &""
@export var display_name: String = ""
@export var archetype: StringName = &""
@export_multiline var description: String = ""
@export var stats: CharacterStats
@export var basic_attack: AttackDefinition
@export var abilities: Array[AbilityDefinition] = []


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if character_id == &"":
		errors.append("character_id is required.")
	if display_name.strip_edges().is_empty():
		errors.append("display_name is required.")
	if archetype == &"":
		errors.append("archetype is required.")
	if stats == null:
		errors.append("stats resource is required.")
	else:
		errors.append_array(stats.validate())
	if basic_attack != null:
		errors.append_array(basic_attack.validate())

	var seen_ability_ids: Dictionary = {}
	for index: int in range(abilities.size()):
		var ability: AbilityDefinition = abilities[index]
		if ability == null:
			errors.append("abilities[%d] is null." % index)
			continue
		errors.append_array(ability.validate())
		if seen_ability_ids.has(ability.ability_id):
			errors.append("Duplicate ability_id: %s" % String(ability.ability_id))
		seen_ability_ids[ability.ability_id] = true
	return errors
