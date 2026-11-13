extends CharacterBody3D
class_name CharacterActor
## Lightweight character scene root. No movement, animation, or combat behavior in RR-002.

signal definition_assigned(definition: CharacterDefinition)

@export var definition: CharacterDefinition


func _ready() -> void:
	if definition != null:
		var errors: PackedStringArray = definition.validate()
		if not errors.is_empty():
			push_error("Invalid character definition '%s': %s" % [
				String(definition.character_id),
				"; ".join(errors)
			])


func assign_definition(next_definition: CharacterDefinition) -> Error:
	if next_definition == null:
		push_error("Cannot assign a null CharacterDefinition.")
		return ERR_INVALID_PARAMETER
	var errors: PackedStringArray = next_definition.validate()
	if not errors.is_empty():
		push_error("Cannot assign invalid character definition: %s" % "; ".join(errors))
		return ERR_INVALID_DATA
	definition = next_definition
	definition_assigned.emit(definition)
	return OK
