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
@export var primary_ability_id: StringName = &""
@export var secondary_ability_id: StringName = &""


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

	if primary_ability_id != &"" and not seen_ability_ids.has(primary_ability_id):
		errors.append("primary_ability_id must reference an ability owned by this hero.")
	if secondary_ability_id != &"" and not seen_ability_ids.has(secondary_ability_id):
		errors.append("secondary_ability_id must reference an ability owned by this hero.")
	if primary_ability_id != &"" and primary_ability_id == secondary_ability_id:
		errors.append("Primary and secondary ability slots must reference different abilities.")
	return errors


func get_ability_id_for_slot(action: int) -> StringName:
	match action:
		MobileInputAction.Action.ABILITY_PRIMARY:
			return primary_ability_id
		MobileInputAction.Action.ABILITY_SECONDARY:
			return secondary_ability_id
	return &""


func owns_ability(ability_id: StringName) -> bool:
	if ability_id == &"":
		return false
	for ability: AbilityDefinition in abilities:
		if ability != null and ability.ability_id == ability_id:
			return true
	return false
