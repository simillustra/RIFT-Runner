extends SceneTree
## RR-008 D3 tests for deterministic local chase steering and attack spacing.
var failures: int = 0
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var actor := CharacterBody3D.new()
	var ai := EnemyAIController.new()
	ai.name = "EnemyAIController"
	var chase := EnemyChaseController.new()
	chase.name = "EnemyChaseController"
	chase.move_speed = 4.0
	chase.preferred_attack_distance = 1.5
	actor.add_child(ai)
	actor.add_child(chase)
	root.add_child(actor)
	var target := Node3D.new()
	target.position = Vector3(0.0, 0.0, -8.0)
	root.add_child(target)
	await process_frame
	ai.set_target(target)
	ai.update_decision(0.016)
	_check(ai.current_state == EnemyAIController.State.CHASE, "target outside attack range enters CHASE")
	var desired := chase.update_steering(0.1)
	_check(desired.z < -0.9 and is_equal_approx(desired.length(), 4.0), "direct steering moves toward target at configured speed")
	_check(actor.velocity.z < 0.0, "chase applies horizontal CharacterBody3D velocity")
	target.position = Vector3(0.0, 0.0, -1.0)
	ai.update_decision(0.016)
	_check(ai.current_state == EnemyAIController.State.ATTACK, "AI enters ATTACK inside attack range")
	var stopped := chase.update_steering(0.1)
	_check(stopped == Vector3.ZERO, "chase stops closing distance inside preferred attack spacing")
	_check(absf(actor.velocity.x) < 0.001 and absf(actor.velocity.z) < 0.001, "chase brakes horizontal velocity at attack spacing")
	if failures == 0:
		print("RR-008 D3 chase steering: PASS")
		quit(0)
	else:
		push_error("RR-008 D3 chase steering: %d failure(s)" % failures)
		quit(1)
func _check(condition: bool, description: String) -> void:
	if condition: print("PASS: %s" % description)
	else:
		failures += 1
		push_error("FAIL: %s" % description)
