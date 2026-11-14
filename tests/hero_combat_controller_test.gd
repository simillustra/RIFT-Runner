extends SceneTree
## RR-005 D4 hero attack profiles and ability execution-hook tests.

var failures: int = 0
const HERO_PATHS: Array[String] = [
	"res://game/resources/characters/heroes/vanguard.tres",
	"res://game/resources/characters/heroes/phantom.tres",
	"res://game/resources/characters/heroes/cipher.tres",
]
const EXPECTED_ABILITY_IDS: Array[StringName] = [&"bulwark", &"phase_shift", &"overclock"]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for index: int in range(HERO_PATHS.size()):
		await _test_hero(HERO_PATHS[index], EXPECTED_ABILITY_IDS[index])
	if failures == 0:
		print("RR-005 D4 hero combat controller tests: PASS")
		quit(0)
	else:
		push_error("RR-005 D4 hero combat controller tests: %d failure(s)" % failures)
		quit(1)


func _test_hero(resource_path: String, expected_ability_id: StringName) -> void:
	var definition := load(resource_path) as CharacterDefinition
	_check(definition != null, "%s loads" % resource_path)
	if definition == null:
		return
	var attack := load(_attack_path_for(expected_ability_id)) as AttackDefinition
	_check(attack != null and attack.validate().is_empty(), "%s basic attack profile validates" % String(definition.character_id))
	definition.basic_attack = attack
	_check(definition.validate().is_empty(), "%s character definition validates with combat profile" % String(definition.character_id))

	var actor := CharacterActor.new()
	actor.name = "Hero_%s" % String(definition.character_id)
	actor.definition = definition
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	actor.add_child(health)
	var executor := AttackExecutor.new()
	executor.name = "AttackExecutor"
	actor.add_child(executor)
	var controller := HeroCombatController.new()
	controller.name = "HeroCombatController"
	actor.add_child(controller)
	root.add_child(actor)
	await process_frame

	_check(controller.execute_basic_attack() == OK, "%s starts its data-driven basic attack" % String(definition.character_id))
	_check(executor.active_definition == attack, "%s attack is delegated to D2 executor" % String(definition.character_id))
	_check(controller.execute_basic_attack() == ERR_BUSY, "%s cannot bypass D2 attack phase lock" % String(definition.character_id))
	executor.cancel_attack()

	_check(controller.activate_ability(expected_ability_id) == OK, "%s activates its signature ability hook" % String(definition.character_id))
	_check(controller.is_ability_active(expected_ability_id), "%s ability effect enters active state" % String(definition.character_id))
	_check(controller.get_cooldown_remaining(expected_ability_id) > 0.0, "%s ability cooldown starts" % String(definition.character_id))
	_check(controller.activate_ability(expected_ability_id) == ERR_BUSY, "%s cannot activate an ability twice during its active window" % String(definition.character_id))
	var ability := definition.abilities[0]
	controller.update_timers(ability.duration_seconds)
	_check(not controller.is_ability_active(expected_ability_id), "%s ability effect expires at configured duration" % String(definition.character_id))
	_check(controller.get_cooldown_remaining(expected_ability_id) > 0.0, "%s cooldown persists after effect expiry" % String(definition.character_id))
	controller.update_timers(ability.cooldown_seconds)
	_check(is_zero_approx(controller.get_cooldown_remaining(expected_ability_id)), "%s cooldown expires deterministically" % String(definition.character_id))
	_check(controller.activate_ability(expected_ability_id) == OK, "%s can reactivate ability after cooldown" % String(definition.character_id))

	actor.queue_free()
	await process_frame


func _attack_path_for(ability_id: StringName) -> String:
	match ability_id:
		&"bulwark":
			return "res://game/resources/characters/attacks/vanguard_basic_attack.tres"
		&"phase_shift":
			return "res://game/resources/characters/attacks/phantom_basic_attack.tres"
		_:
			return "res://game/resources/characters/attacks/cipher_basic_attack.tres"


func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		failures += 1
		push_error("FAIL: %s" % description)
