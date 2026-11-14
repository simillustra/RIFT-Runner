extends Node
class_name HeroCombatController
## Data-driven hero combat entry point. Attack timing/damage remain owned by AttackExecutor.

signal basic_attack_requested(definition: AttackDefinition)
signal ability_activated(ability: AbilityDefinition)
signal ability_effect_started(ability: AbilityDefinition)
signal ability_effect_ended(ability: AbilityDefinition)
signal ability_rejected(ability_id: StringName, reason: String)

@export var attack_executor_path: NodePath = NodePath("../AttackExecutor")
@export var character_actor_path: NodePath = NodePath("..")

var _executor: AttackExecutor
var _actor: CharacterActor
var _cooldowns: Dictionary = {}
var _active_abilities: Dictionary = {}


func _ready() -> void:
	_executor = get_node_or_null(attack_executor_path) as AttackExecutor
	_actor = get_node_or_null(character_actor_path) as CharacterActor
	if _executor == null:
		push_warning("HeroCombatController requires an AttackExecutor.")
	if _actor == null:
		push_warning("HeroCombatController requires a CharacterActor parent.")


func execute_basic_attack() -> Error:
	if not _is_combatant_ready():
		return ERR_UNCONFIGURED
	var definition := _actor.definition.basic_attack
	if definition == null:
		return ERR_UNCONFIGURED
	var errors := definition.validate()
	if not errors.is_empty():
		push_error("Invalid hero basic attack: %s" % "; ".join(errors))
		return ERR_INVALID_DATA
	var result := _executor.begin_attack(definition, _actor)
	if result == OK:
		basic_attack_requested.emit(definition)
	return result


func activate_ability(ability_id: StringName) -> Error:
	if not _is_combatant_ready():
		return ERR_UNCONFIGURED
	if ability_id == &"":
		return ERR_INVALID_PARAMETER
	var ability := _find_ability(ability_id)
	if ability == null:
		ability_rejected.emit(ability_id, "Ability is not present in this hero's definition.")
		return ERR_DOES_NOT_EXIST
	var errors := ability.validate()
	if not errors.is_empty():
		ability_rejected.emit(ability_id, "; ".join(errors))
		return ERR_INVALID_DATA
	if float(_cooldowns.get(ability_id, 0.0)) > 0.0:
		ability_rejected.emit(ability_id, "Ability is on cooldown.")
		return ERR_BUSY
	if _active_abilities.has(ability_id):
		ability_rejected.emit(ability_id, "Ability is already active.")
		return ERR_BUSY

	_cooldowns[ability_id] = ability.cooldown_seconds
	if ability.duration_seconds > 0.0:
		_active_abilities[ability_id] = {
			"definition": ability,
			"remaining": ability.duration_seconds,
		}
	ability_activated.emit(ability)
	if ability.duration_seconds > 0.0:
		ability_effect_started.emit(ability)
	else:
		ability_effect_ended.emit(ability)
	return OK


func update_timers(delta: float) -> void:
	if delta <= 0.0:
		return
	for ability_id: Variant in _cooldowns.keys():
		_cooldowns[ability_id] = maxf(float(_cooldowns[ability_id]) - delta, 0.0)
	for ability_id: Variant in _active_abilities.keys():
		var state: Dictionary = _active_abilities[ability_id]
		var ability := state.get("definition") as AbilityDefinition
		if ability == null:
			_active_abilities.erase(ability_id)
			continue
		state["remaining"] = maxf(float(state.get("remaining", 0.0)) - delta, 0.0)
		if float(state["remaining"]) <= 0.0:
			_active_abilities.erase(ability_id)
			ability_effect_ended.emit(ability)


func get_cooldown_remaining(ability_id: StringName) -> float:
	return maxf(float(_cooldowns.get(ability_id, 0.0)), 0.0)


func is_ability_active(ability_id: StringName) -> bool:
	return _active_abilities.has(ability_id)


func _process(delta: float) -> void:
	update_timers(delta)


func _find_ability(ability_id: StringName) -> AbilityDefinition:
	for ability: AbilityDefinition in _actor.definition.abilities:
		if ability != null and ability.ability_id == ability_id:
			return ability
	return null


func _is_combatant_ready() -> bool:
	if not is_instance_valid(_executor) or not is_instance_valid(_actor):
		return false
	if _actor.definition == null or _actor.definition.stats == null:
		return false
	var health := _actor.get_node_or_null("HealthComponent") as HealthComponent
	return health != null and not health.is_dead
