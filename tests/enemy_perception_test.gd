extends SceneTree
## RR-008 D2 tests for local perception and nearest valid target selection.
var failures: int = 0
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var enemy := CharacterBody3D.new()
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	var ai := EnemyAIController.new()
	ai.name = "EnemyAIController"
	var perception := EnemyPerceptionController.new()
	perception.name = "EnemyPerceptionController"
	perception.perception_range = 20.0
	enemy.add_child(health)
	enemy.add_child(ai)
	enemy.add_child(perception)
	root.add_child(enemy)
	var far_player := Node3D.new()
	far_player.position = Vector3(0.0, 0.0, -12.0)
	far_player.add_to_group(&"player")
	root.add_child(far_player)
	var near_player := Node3D.new()
	near_player.position = Vector3(0.0, 0.0, -5.0)
	near_player.add_to_group(&"player")
	root.add_child(near_player)
	var non_player := Node3D.new()
	non_player.position = Vector3(0.0, 0.0, -1.0)
	root.add_child(non_player)
	await process_frame
	_check(perception.refresh_perception() == near_player, "nearest player-group target is selected")
	_check(ai.target == near_player, "selected target is passed into the enemy state machine")
	near_player.position = Vector3(0.0, 0.0, -25.0)
	_check(perception.refresh_perception() == far_player, "next in-range candidate is selected")
	far_player.remove_from_group(&"player")
	_check(perception.refresh_perception() == null, "target is cleared when no candidates remain")
	_check(ai.target == null, "cleared target is removed from enemy AI")
	var dead_player := Node3D.new()
	dead_player.position = Vector3(0.0, 0.0, -2.0)
	dead_player.add_to_group(&"player")
	var dead_health := HealthComponent.new()
	dead_health.name = "HealthComponent"
	dead_player.add_child(dead_health)
	root.add_child(dead_player)
	await process_frame
	dead_health.apply_damage(100.0)
	_check(perception.refresh_perception() == null, "dead player candidate is ignored")
	if failures == 0:
		print("RR-008 D2 enemy perception: PASS")
		quit(0)
	else:
		push_error("RR-008 D2 enemy perception: %d failure(s)" % failures)
		quit(1)
func _check(condition: bool, description: String) -> void:
	if condition: print("PASS: %s" % description)
	else:
		failures += 1
		push_error("FAIL: %s" % description)
