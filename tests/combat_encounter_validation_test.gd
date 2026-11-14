extends SceneTree
## RR-005 D7 deterministic hero-versus-baseline encounter and balance regression tests.

const STEP_SECONDS: float = 0.01
const TARGET_HEALTH: float = 100.0
const HERO_CASES: Array[Dictionary] = [
	{"id": &"vanguard", "path": "res://game/resources/characters/heroes/vanguard.tres", "expected_hits": 5, "expected_time": 5.30},
	{"id": &"phantom", "path": "res://game/resources/characters/heroes/phantom.tres", "expected_hits": 5, "expected_time": 3.20},
	{"id": &"cipher", "path": "res://game/resources/characters/heroes/cipher.tres", "expected_hits": 6, "expected_time": 5.10},
]

var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for hero_case: Dictionary in HERO_CASES:
		await _validate_hero_encounter(hero_case)
	if failures == 0:
		print("RR-005 D7 combat encounter validation: PASS")
		quit(0)
	else:
		push_error("RR-005 D7 combat encounter validation: %d failure(s)" % failures)
		quit(1)


func _validate_hero_encounter(hero_case: Dictionary) -> void:
	var hero_id: StringName = hero_case["id"]
	var definition := load(String(hero_case["path"])) as CharacterDefinition
	_check(definition != null, "%s hero definition loads" % String(hero_id))
	if definition == null:
		return
	_check(definition.validate().is_empty(), "%s complete hero definition validates" % String(hero_id))
	var attack := definition.basic_attack
	_check(attack != null and attack.validate().is_empty(), "%s basic attack definition validates" % String(hero_id))
	if attack == null:
		return

	var combatant := Node.new()
	combatant.name = "D7_%s_Combatant" % String(hero_id)
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	health.max_health = TARGET_HEALTH
	health.defense = 0.0
	health.invulnerability_seconds = 0.0
	combatant.add_child(health)
	var executor := AttackExecutor.new()
	executor.name = "AttackExecutor"
	combatant.add_child(executor)
	root.add_child(combatant)
	await process_frame
	health.set_process(false)
	executor.set_process(false)

	_check(executor.try_hit(health) == 0.0, "%s cannot deal damage before an attack starts" % String(hero_id))
	var landed_hits: int = 0
	var elapsed_seconds: float = 0.0
	var attack_cycles: int = 0
	while not health.is_dead and attack_cycles < 20:
		_check(executor.begin_attack(attack, combatant) == OK, "%s starts encounter attack cycle %d" % [String(hero_id), attack_cycles + 1])
		_check(executor.try_hit(health) == 0.0, "%s cannot hit during startup" % String(hero_id))
		var hit_registered_this_cycle: bool = false
		var frame_guard: int = 0
		while not executor.is_ready() and frame_guard < 2000:
			executor.update_timers(STEP_SECONDS)
			elapsed_seconds += STEP_SECONDS
			frame_guard += 1
			if executor.is_active() and not hit_registered_this_cycle:
				var applied := executor.try_hit(health)
				if applied > 0.0:
					landed_hits += 1
				hit_registered_this_cycle = true
		_check(frame_guard < 2000, "%s attack cycle completes within deterministic frame guard" % String(hero_id))
		attack_cycles += 1
	_check(health.is_dead, "%s defeats baseline target within 20 attack cycles" % String(hero_id))
	_check(landed_hits == int(hero_case["expected_hits"]), "%s lands expected number of attacks (%d)" % [String(hero_id), int(hero_case["expected_hits"])])
	_check(is_equal_approx(elapsed_seconds, float(hero_case["expected_time"])), "%s baseline time-to-kill remains %.2f seconds (actual %.2f)" % [String(hero_id), float(hero_case["expected_time"]), elapsed_seconds])
	_check(health.current_health == 0.0 and health.is_dead, "%s encounter ends through authoritative D1 death" % String(hero_id))
	print("D7 BALANCE: %s | hits=%d | simulated_ttk=%.2fs | attack_cycle=%.2fs" % [
		String(hero_id), landed_hits, elapsed_seconds,
		attack.startup_seconds + attack.active_seconds + attack.recovery_seconds + attack.cooldown_seconds,
	])
	combatant.queue_free()
	await process_frame


func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		failures += 1
		push_error("FAIL: %s" % description)
