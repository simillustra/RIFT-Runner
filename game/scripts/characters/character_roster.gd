extends Resource
class_name CharacterRoster
## Validated collection of playable character definitions.

@export var characters: Array[CharacterDefinition] = []


func get_character(character_id: StringName) -> CharacterDefinition:
	for character: CharacterDefinition in characters:
		if character != null and character.character_id == character_id:
			return character
	return null


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	var seen_ids: Dictionary = {}
	for index: int in range(characters.size()):
		var character: CharacterDefinition = characters[index]
		if character == null:
			errors.append("characters[%d] is null." % index)
			continue
		errors.append_array(character.validate())
		if seen_ids.has(character.character_id):
			errors.append("Duplicate character_id: %s" % String(character.character_id))
		seen_ids[character.character_id] = true
	return errors
