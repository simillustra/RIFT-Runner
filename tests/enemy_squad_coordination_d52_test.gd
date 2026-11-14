extends SceneTree
## Compatibility regression for RR-008 D5.2 retreat and squad role foundations.
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var world := Node3D.new()
	var coordinator := EnemySquadCoordinator.new()
	coordinator.name = "SquadCoordinator"
	coordinator.max_skirmishers = 1
	world.add_child(coordinator)
	var target := Node3D.new()
	target.position = Vector3(0.0, 0.0, -10.0)
	world.add_child(target)
	var assault := _make_enemy("Assault")
	var flanker := _make_enemy("Flanker")
	var extra := _make_enemy("ExtraFlanker")
	world.add_child(assault)
	world.add_child(flanker)
	world.add_child(extra)
	root.add_child(world)
	await process_frame
	var ai := assault.get_node("EnemyAIController") as EnemyAIController
	var f := flanker.get_node("EnemyAIController") as EnemyAIController
	var x := extra.get_node("EnemyAIController") as EnemyAIController
	ai.assign_squad_coordinator(coordinator, EnemyArchetypeProfile.EngagementPolicy.PURSUER)
	f.assign_squad_coordinator(coordinator, EnemyArchetypeProfile.EngagementPolicy.SKIRMISHER)
	x.assign_squad_coordinator(coordinator, EnemyArchetypeProfile.EngagementPolicy.SKIRMISHER)
	_check(f.assigned_tactical_role == EnemySquadCoordinator.TacticalRole.SKIRMISHER and x.assigned_tactical_role != EnemySquadCoordinator.TacticalRole.SKIRMISHER, "role capacity and deterministic fallback")
	var flanker_chase := flanker.get_node("EnemyChaseController") as EnemyChaseController
	f.set_target(target)
	f.current_state = EnemyAIController.State.CHASE
	flanker.position = Vector3(0.0, 0.0, -7.0)
	_check(flanker_chase.update_steering(0.1).length() > 0.0, "assigned flanker receives a distinct tactical approach")
	ai.retreat_health_ratio = 0.5
	ai.retreat_distance = 6.0
	assault.position = Vector3(0.0, 0.0, -7.0)
	ai.set_target(target)
	(assault.get_node("HealthComponent") as HealthComponent).apply_damage(60.0)
	ai.update_decision(0.016)
	_check(ai.current_state == EnemyAIController.State.RETREAT, "low health triggers retreat")
	_check(coordinator.get_retreating_count(target) == 1, "squad observes retreating member")
	var chase := assault.get_node("EnemyChaseController") as EnemyChaseController
	_check(chase.update_steering(0.1).z > 0.0, "retreat steering moves away from target")
	assault.position = Vector3(0.0, 0.0, 7.0)
	ai.update_decision(0.016)
	_check(ai.current_state == EnemyAIController.State.ALERT and coordinator.get_retreating_count(target) == 0, "disengagement clears retreat state")
	ai.set_staggered(true, 0.2)
	ai.update_decision(0.1)
	_check(ai.current_state == EnemyAIController.State.STAGGERED, "stagger pauses decision updates")
	ai.update_decision(0.11)
	_check(ai.current_state != EnemyAIController.State.STAGGERED, "stagger recovers on deterministic timer")
	ai.set_dead()
	_check(ai.current_state == EnemyAIController.State.DEAD, "death remains terminal")
	world.queue_free()
	await process_frame
	if failures == 0:
		print("RR-008 D5.2 compatibility: PASS")
		quit(0)
	else:
		push_error("RR-008 D5.2 compatibility: %d failure(s)" % failures)
		quit(1)

func _make_enemy(label: String) -> CharacterBody3D:
	var actor := CharacterBody3D.new()
	actor.name = label
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	actor.add_child(health)
	var ai := EnemyAIController.new()
	ai.name = "EnemyAIController"
	actor.add_child(ai)
	var chase := EnemyChaseController.new()
	chase.name = "EnemyChaseController"
	actor.add_child(chase)
	return actor

func _check(ok: bool, label: String) -> void:
	if ok:
		print("PASS: " + label)
	else:
		failures += 1
		push_error("FAIL: " + label)
