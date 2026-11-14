extends SceneTree
## RR-008 D4 tests for Resource-driven enemy archetype policies.
var failures: int = 0
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var actor := CharacterBody3D.new()
	var ai := EnemyAIController.new()
	ai.name = "EnemyAIController"
	var chase := EnemyChaseController.new()
	chase.name = "EnemyChaseController"
	var archetype := EnemyArchetypeController.new()
	archetype.name = "EnemyArchetypeController"
	actor.add_child(ai)
	actor.add_child(chase)
	actor.add_child(archetype)
	root.add_child(actor)
	await process_frame
	var profile := EnemyArchetypeProfile.new()
	profile.archetype_id = &"infected_skirmisher"
	profile.detection_range = 22.0
	profile.attack_range = 3.0
	profile.lose_target_range = 30.0
	profile.move_speed = 5.5
	profile.preferred_attack_distance = 2.8
	profile.engagement_policy = EnemyArchetypeProfile.EngagementPolicy.SKIRMISHER
	profile.can_retreat = false
	_check(archetype.apply_profile(profile) == OK, "valid archetype profile applies")
	_check(is_equal_approx(ai.detection_range, 22.0), "profile configures perception range")
	_check(is_equal_approx(ai.attack_range, 3.0), "profile configures attack range")
	_check(is_equal_approx(chase.move_speed, 5.5), "profile configures chase speed")
	_check(chase.engagement_policy == EnemyArchetypeProfile.EngagementPolicy.SKIRMISHER, "profile configures engagement policy")
	_check(not ai.retreat_enabled, "archetype profile can disable retreat for committed enemies")
	var invalid := EnemyArchetypeProfile.new()
	invalid.archetype_id = &"invalid"
	invalid.attack_range = 40.0
	_check(archetype.apply_profile(invalid) == ERR_INVALID_DATA, "invalid archetype profile is rejected")
	if failures == 0:
		print("RR-008 D4 archetype policies: PASS")
		quit(0)
	else:
		push_error("RR-008 D4 archetype policies: %d failure(s)" % failures)
		quit(1)
func _check(condition: bool, description: String) -> void:
	if condition: print("PASS: %s" % description)
	else:
		failures += 1
		push_error("FAIL: %s" % description)
