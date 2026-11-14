extends SceneTree
## RR-005 D5 enemy combat and boss damage-interface tests.

var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var enemy_scene := load("res://game/scenes/combat/enemy_combatant.tscn") as PackedScene
	var boss_scene := load("res://game/scenes/combat/boss_combatant.tscn") as PackedScene
	_check(enemy_scene != null, "reusable enemy combatant scene loads")
	_check(boss_scene != null, "reusable boss combatant scene loads")
	if enemy_scene == null or boss_scene == null:
		_finish()
		return

	var enemy := enemy_scene.instantiate() as Node3D
	root.add_child(enemy)
	await process_frame
	var enemy_health := enemy.get_node("HealthComponent") as HealthComponent
	var enemy_executor := enemy.get_node("AttackExecutor") as AttackExecutor
	var enemy_controller := enemy.get_node("EnemyCombatController") as EnemyCombatController
	enemy_executor.set_process(false)
	enemy_controller.attack_definition = _make_attack()
	_check(enemy_controller.request_attack() == OK, "living enemy starts attack through D2 executor")
	_check(enemy_executor.phase == AttackExecutor.Phase.STARTUP, "enemy attack observes D2 startup timing")
	_check(enemy_executor.try_hit(enemy_health) == 0.0, "enemy cannot damage during startup")
	enemy_executor.update_timers(0.1)
	_check(enemy_executor.is_active(), "enemy attack enters D2 active window")
	_check(enemy_executor.try_hit(enemy_health) == 20.0, "D2 executor remains the only enemy damage execution path")
	enemy_executor.update_timers(0.2)
	_check(enemy_executor.phase == AttackExecutor.Phase.RECOVERY, "enemy attack closes into D2 recovery")
	enemy_health.apply_damage(1000.0)
	_check(enemy_controller.request_attack() == ERR_UNCONFIGURED, "dead enemy cannot request another attack")

	var boss := boss_scene.instantiate() as Node3D
	root.add_child(boss)
	await process_frame
	var boss_health := boss.get_node("HealthComponent") as HealthComponent
	var boss_controller := boss.get_node("BossDamageController") as BossDamageController
	var boss_executor := boss.get_node("AttackExecutor") as AttackExecutor
	boss_executor.set_process(false)
	_check(is_equal_approx(boss_health.damage_taken_multiplier, 0.25), "boss starts in armored damage phase")
	_check(is_equal_approx(boss_health.apply_damage(100.0), 23.75), "armored phase scales post-defense damage")
	_check(boss_controller.set_phase(BossDamageController.Phase.EXPOSED) == OK, "boss can enter exposed phase")
	_check(is_equal_approx(boss_health.apply_damage(100.0), 142.5), "exposed phase increases damage through D1 health")
	_check(boss_controller.set_phase(BossDamageController.Phase.ENRAGED) == OK, "boss can enter enraged phase")
	_check(is_equal_approx(boss_health.apply_damage(100.0), 95.0), "enraged phase restores configured damage intake")
	_check(boss_controller.set_phase(BossDamageController.Phase.DEFEATED) == ERR_INVALID_PARAMETER, "defeated phase cannot be set manually")
	boss_health.apply_damage(10000.0)
	_check(boss_health.is_dead, "boss death remains owned by D1 HealthComponent")
	_check(boss_controller.phase == BossDamageController.Phase.DEFEATED, "D1 death event moves boss interface to defeated")
	_check(is_equal_approx(boss_controller.get_damage_multiplier(), 0.0), "defeated boss rejects further scaled damage")
	_check(boss_controller.set_phase(BossDamageController.Phase.EXPOSED) == ERR_UNCONFIGURED, "defeated boss cannot re-enter a vulnerable phase")

	enemy.queue_free()
	boss.queue_free()
	await process_frame
	_finish()


func _make_attack() -> AttackDefinition:
	var definition := AttackDefinition.new()
	definition.attack_id = &"infected_claw"
	definition.display_name = "Infected Claw"
	definition.damage = 20.0
	definition.damage_type = &"physical"
	definition.startup_seconds = 0.1
	definition.active_seconds = 0.2
	definition.recovery_seconds = 0.2
	definition.cooldown_seconds = 0.1
	return definition


func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		failures += 1
		push_error("FAIL: %s" % description)


func _finish() -> void:
	if failures == 0:
		print("RR-005 D5 enemy and boss combat tests: PASS")
		quit(0)
	else:
		push_error("RR-005 D5 enemy and boss combat tests: %d failure(s)" % failures)
		quit(1)
