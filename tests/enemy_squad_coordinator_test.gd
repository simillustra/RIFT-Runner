extends SceneTree
## RR-008 D5 tests for deterministic squad attack-slot arbitration and AI lifecycle release.
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var world := Node3D.new()
	var coordinator := EnemySquadCoordinator.new()
	coordinator.name = "SquadCoordinator"
	coordinator.max_simultaneous_attackers_per_target = 1
	world.add_child(coordinator)
	var target := Node3D.new()
	target.add_to_group("player")
	world.add_child(target)
	var first := _make_enemy("FirstEnemy", coordinator, target)
	var second := _make_enemy("SecondEnemy", coordinator, target)
	world.add_child(first)
	world.add_child(second)
	root.add_child(world)
	await process_frame
	var first_ai := first.get_node("EnemyAIController") as EnemyAIController
	var second_ai := second.get_node("EnemyAIController") as EnemyAIController
	var first_executor := first.get_node("AttackExecutor") as AttackExecutor
	var second_executor := second.get_node("AttackExecutor") as AttackExecutor
	first_ai.set_target(target)
	second_ai.set_target(target)
	first_ai.update_decision(0.016)
	second_ai.update_decision(0.016)
	_check(first_executor.phase != AttackExecutor.Phase.IDLE, "first enemy claims the only attack slot")
	_check(second_executor.phase == AttackExecutor.Phase.IDLE, "second enemy is held while target attack capacity is full")
	_check(coordinator.get_active_attacker_count(target) == 1, "coordinator enforces one active attacker per target")
	first_executor.update_timers(2.0)
	_check(coordinator.get_active_attacker_count(target) == 0, "attack completion releases the slot")
	second_ai.update_decision(0.3)
	_check(second_executor.phase != AttackExecutor.Phase.IDLE, "waiting enemy attacks after the slot is released")
	second_ai.set_staggered(true, 0.5)
	_check(coordinator.get_active_attacker_count(target) == 0, "stagger cancels attack and releases its slot")
	second_ai.set_staggered(false)
	second_ai.update_decision(0.3)
	_check(second_executor.phase != AttackExecutor.Phase.IDLE, "enemy can re-enter coordinated attack after stagger")
	second_ai.set_dead()
	_check(coordinator.get_active_attacker_count(target) == 0, "death releases attack slot and cancels attack")
	_check(not coordinator.has_attack_slot(second), "dead enemy no longer owns an attack slot")
	world.queue_free()
	await process_frame
	if failures == 0:
		print("RR-008 D5 squad coordination: PASS")
		quit(0)
	else:
		push_error("RR-008 D5 squad coordination: %d failure(s)" % failures)
		quit(1)

func _make_enemy(enemy_name: String, coordinator: EnemySquadCoordinator, target: Node3D) -> CharacterBody3D:
	var actor := CharacterBody3D.new()
	actor.name = enemy_name
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	actor.add_child(health)
	var definition := AttackDefinition.new()
	definition.attack_id = StringName(enemy_name.to_snake_case())
	definition.display_name = enemy_name
	definition.startup_seconds = 0.05
	definition.active_seconds = 0.1
	definition.recovery_seconds = 0.05
	definition.cooldown_seconds = 0.05
	var executor := AttackExecutor.new()
	executor.name = "AttackExecutor"
	actor.add_child(executor)
	var combat := EnemyCombatController.new()
	combat.name = "EnemyCombatController"
	combat.attack_definition = definition
	actor.add_child(combat)
	var ai := EnemyAIController.new()
	ai.name = "EnemyAIController"
	ai.squad_coordinator_path = NodePath("../../SquadCoordinator")
	actor.add_child(ai)
	return actor

func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		failures += 1
		push_error("FAIL: %s" % description)
