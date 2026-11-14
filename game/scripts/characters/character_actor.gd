extends CharacterBody3D
class_name CharacterActor
## Lightweight character root with optional movement/animation and authoritative health.

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
			return
		_configure_health_from_definition()


func _configure_health_from_definition() -> void:
	if definition == null or definition.stats == null:
		return
	var health := get_node_or_null("HealthComponent") as HealthComponent
	if health == null:
		push_warning("CharacterActor has a definition but no HealthComponent child.")
		return
	var result := health.configure(definition.stats.max_health, definition.stats.defense)
	if result != OK:
		push_error("CharacterActor could not configure HealthComponent from CharacterDefinition.")


func assign_definition(next_definition: CharacterDefinition) -> Error:
	if next_definition == null:
		push_error("Cannot assign a null CharacterDefinition.")
		return ERR_INVALID_PARAMETER
	var errors: PackedStringArray = next_definition.validate()
	if not errors.is_empty():
		push_error("Cannot assign invalid CharacterDefinition: %s" % "; ".join(errors))
		return ERR_INVALID_DATA
	definition = next_definition
	_configure_health_from_definition()
	definition_assigned.emit(definition)
	return OK
