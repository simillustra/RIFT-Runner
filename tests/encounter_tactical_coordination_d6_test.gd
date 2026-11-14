extends SceneTree
## RR-008 D6 deterministic tactical encounter and lifecycle regression.
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var world := Node3D.new()
	var squad := EnemySquadCoordinator.new()
	squad.name = "Squad"
	squad.max_pursuers = 2
	squad.max_skirmishers = 1
	squad.max_ranged = 1
	world.add_child(squad)
	var player := Node3D.new()
	player.position = Vector3.ZERO
	world.add_child(player)
	var pursuer := _make_enemy("Pursuer")
	var skirmisher := _make_enemy("Skirmisher")
	var ranged := _make_enemy("Ranged")
	world.add_child(pursuer)
	world.add_child(skirmisher)
	world.add_child(ranged)
	root.add_child(world)
	await process_frame
	var p_ai := pursuer.get_node("EnemyAIController") as EnemyAIController
	var s_ai := skirmisher.get_node("EnemyAIController") as EnemyAIController
	var r_ai := ranged.get_node("EnemyAIController") as EnemyAIController
	p_ai.assign_squad_coordinator(squad, EnemyArchetypeProfile.EngagementPolicy.PURSUER)
	s_ai.assign_squad_coordinator(squad, EnemyArchetypeProfile.EngagementPolicy.SKIRMISHER)
	r_ai.assign_squad_coordinator(squad, EnemyArchetypeProfile.EngagementPolicy.RANGED)
	_check(p_ai.assigned_tactical_role == EnemySquadCoordinator.TacticalRole.PURSUER, "pursuer archetype receives pursuer role")
	_check(s_ai.assigned_tactical_role == EnemySquadCoordinator.TacticalRole.SKIRMISHER, "skirmisher archetype receives flank role")
	_check(r_ai.assigned_tactical_role == EnemySquadCoordinator.TacticalRole.RANGED, "ranged archetype receives standoff role")
	_check(squad.get_role_count(EnemySquadCoordinator.TacticalRole.PURSUER) == 1, "composition tracks pursuer count")
	p_ai.set_target(player)
	s_ai.set_target(player)
	r_ai.set_target(player)
	var p_pos := squad.get_approach_position(pursuer, player, p_ai.assigned_tactical_role, 2.0)
	var s_pos := squad.get_approach_position(skirmisher, player, s_ai.assigned_tactical_role, 4.0)
	var r_pos := squad.get_approach_position(ranged, player, r_ai.assigned_tactical_role, 6.0)
	_check(p_pos.distance_to(s_pos) > 1.0 and s_pos.distance_to(r_pos) > 1.0, "different archetypes reserve distinct approach sectors")
	_check(squad.get_approach_position(skirmisher, player, s_ai.assigned_tactical_role, 4.0).is_equal_approx(s_pos), "approach slot is stable across decision ticks")
	var duplicate := _make_enemy("DuplicateFlanker")
	world.add_child(duplicate)
	await process_frame
	var d_ai := duplicate.get_node("EnemyAIController") as EnemyAIController
	d_ai.assign_squad_coordinator(squad, EnemyArchetypeProfile.EngagementPolicy.SKIRMISHER)
	_check(d_ai.assigned_tactical_role != EnemySquadCoordinator.TacticalRole.SKIRMISHER, "role capacity deterministically redirects duplicate archetype")
	var duplicate_pos := squad.get_approach_position(duplicate, player, d_ai.assigned_tactical_role, 3.0)
	_check(duplicate_pos.distance_to(s_pos) > 0.5, "additional member does not reuse an occupied approach sector")
	d_ai.clear_target()
	_check(squad.get_approach_position(duplicate, player, d_ai.assigned_tactical_role, 3.0) != duplicate_pos, "target claim release permits sector reassignment")
	_check(squad.request_attack_slot(pursuer, player), "attack reservation accepted")
	_check(squad.get_active_attacker_count(player) == 1, "attack arbitration remains target-scoped")
	p_ai.set_staggered(true, 0.2)
	_check(squad.get_active_attacker_count(player) == 0, "stagger releases attack reservation")
	p_ai.set_staggered(false)
	var health := pursuer.get_node("HealthComponent") as HealthComponent
	pursuer.position = Vector3(0.0, 0.0, -2.0)
	health.apply_damage(80.0)
	p_ai.update_decision(0.016)
	_check(p_ai.current_state == EnemyAIController.State.RETREAT, "low-health pursuer enters retreat")
	_check(squad.get_retreating_count(player) == 1, "squad tracks retreating member")
	var chase := pursuer.get_node("EnemyChaseController") as EnemyChaseController
	var retreat_vector := chase.update_steering(0.1)
	_check(retreat_vector.z < 0.0, "retreat steering increases separation from target")
	pursuer.position = Vector3(0.0, 0.0, -9.0)
	p_ai.update_decision(0.016)
	_check(p_ai.current_state == EnemyAIController.State.ALERT, "retreat completes at disengagement distance")
	_check(squad.get_retreating_count(player) == 0, "completed retreat clears squad retreat state")
	p_ai.update_decision(1.1)
	_check(p_ai.current_state == EnemyAIController.State.CHASE, "enemy re-engages after deterministic recovery delay")
	var stale_target := Node3D.new()
	world.add_child(stale_target)
	r_ai.set_target(stale_target)
	squad.get_approach_position(ranged, stale_target, r_ai.assigned_tactical_role, 5.0)
	stale_target.free()
	r_ai.update_decision(0.016)
	_check(r_ai.target == null, "invalid target is cleared without retaining tactical claims")
	_check(squad.get_retreating_count(player) == 0, "target invalidation does not leak retreat membership")
	p_ai.set_dead()
	_check(squad.get_role_count(EnemySquadCoordinator.TacticalRole.PURSUER) == 0, "death unregisters tactical role")
	d_ai.set_dead()
	_check(squad.get_approach_position(duplicate, player, d_ai.assigned_tactical_role, 3.0) == player.global_position, "dead member cannot reserve new approach position")
	world.queue_free()
	await process_frame
	if failures == 0:
		print("RR-008 D6 tactical encounter: PASS")
		quit(0)
	else:
		push_error("RR-008 D6 tactical encounter: %d failure(s)" % failures)
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

func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		failures += 1
		push_error("FAIL: %s" % description)
