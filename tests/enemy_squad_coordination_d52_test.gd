extends SceneTree
var failures: int = 0
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var world := Node3D.new()
	var coordinator := EnemySquadCoordinator.new()
	coordinator.name = "SquadCoordinator"
	world.add_child(coordinator)
	var target := Node3D.new()
	target.position = Vector3(0.0, 0.0, -10.0)
	world.add_child(target)
	var assault := _make_enemy("Assault", EnemyArchetypeProfile.SquadRole.ASSAULT)
	var flanker := _make_enemy("Flanker", EnemyArchetypeProfile.SquadRole.FLANKER)
	var extra := _make_enemy("ExtraFlanker", EnemyArchetypeProfile.SquadRole.FLANKER)
	world.add_child(assault); world.add_child(flanker); world.add_child(extra)
	root.add_child(world)
	await process_frame
	var ai := assault.get_node("EnemyAIController") as EnemyAIController
	var f := flanker.get_node("EnemyAIController") as EnemyAIController
	var x := extra.get_node("EnemyAIController") as EnemyAIController
	ai.set_target(target); f.set_target(target); x.set_target(target)
	_check(f.assigned_squad_role == 1 and x.assigned_squad_role == 0, "role capacity and deterministic fallback")
	# Reuse the flanker that successfully reserved the role above. The extra
	# flanker correctly fell back to ASSAULT because the role capacity is one.
	# Put the assigned flanker inside its preferred engagement radius so the
	# steering controller exercises lateral repositioning rather than approach.
	var flanker_chase := flanker.get_node("EnemyChaseController") as EnemyChaseController
	flanker.position = Vector3(0.0, 0.0, -7.0)
	f.current_state = EnemyAIController.State.CHASE
	f.attack_range = 1.0
	flanker_chase.preferred_attack_distance = 3.0
	_check(f.assigned_squad_role == EnemyArchetypeProfile.SquadRole.FLANKER, "movement fixture retains flanker role reservation")
	_check(absf(flanker_chase.update_steering(0.1).x) > 0.01, "flanker role produces lateral repositioning")
	var support := _make_enemy("Support", EnemyArchetypeProfile.SquadRole.SUPPORT)
	world.add_child(support)
	await process_frame
	var support_ai := support.get_node("EnemyAIController") as EnemyAIController
	var support_chase := support.get_node("EnemyChaseController") as EnemyChaseController
	support.position = Vector3(0.0, 0.0, -7.5)
	support_ai.set_target(target)
	support_ai.current_state = EnemyAIController.State.CHASE
	support_ai.attack_range = 2.0
	support_chase.preferred_attack_distance = 1.6
	_check(support_chase.update_steering(0.1) == Vector3.ZERO, "support role holds safer standoff distance")
	ai.retreat_health_ratio = 0.5
	ai.retreat_distance = 6.0
	(assault.get_node("HealthComponent") as HealthComponent).apply_damage(60.0)
	ai.update_decision(0.016)
	_check(ai.current_state == EnemyAIController.State.RETREAT, "low health triggers retreat")
	_check(coordinator.get_retreating_count(target) == 1, "squad observes retreating member")
	var chase := assault.get_node("EnemyChaseController") as EnemyChaseController
	_check(chase.update_steering(0.1).z > 0.0, "retreat steering moves away from target")
	assault.position = Vector3(0.0, 0.0, 7.0)
	ai.update_decision(0.016)
	_check(ai.current_state == EnemyAIController.State.ALERT and coordinator.get_retreating_count(target) == 0, "disengagement clears retreat state")
	ai.set_staggered(true, 0.2); ai.update_decision(0.1)
	_check(ai.current_state == EnemyAIController.State.STAGGERED, "stagger pauses decision updates")
	ai.update_decision(0.11)
	_check(ai.current_state != EnemyAIController.State.STAGGERED, "stagger recovers on deterministic timer")
	ai.set_dead()
	_check(ai.current_state == EnemyAIController.State.DEAD, "death remains terminal")
	world.queue_free(); await process_frame
	if failures == 0: print("RR-008 D5.2: PASS"); quit(0)
	else: push_error("RR-008 D5.2 failures: %d" % failures); quit(1)
func _make_enemy(label: String, role: EnemyArchetypeProfile.SquadRole) -> CharacterBody3D:
	var actor := CharacterBody3D.new(); actor.name = label
	var health := HealthComponent.new(); health.name = "HealthComponent"; actor.add_child(health)
	var ai := EnemyAIController.new(); ai.name = "EnemyAIController"; ai.squad_coordinator_path = NodePath("../../SquadCoordinator"); ai.preferred_squad_role = role; actor.add_child(ai)
	var chase := EnemyChaseController.new(); chase.name = "EnemyChaseController"; actor.add_child(chase)
	return actor
func _check(ok: bool, label: String) -> void:
	if ok: print("PASS: " + label)
	else: failures += 1; push_error("FAIL: " + label)
