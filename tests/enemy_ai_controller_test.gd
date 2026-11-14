extends SceneTree
## RR-008 D1 tests for deterministic enemy state transitions and lifecycle.
var failures: int = 0
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var enemy_scene := load("res://game/scenes/combat/enemy_combatant.tscn") as PackedScene
	_check(enemy_scene != null, "enemy combatant scene loads")
	if enemy_scene != null:
		var enemy_scene_instance := enemy_scene.instantiate()
		root.add_child(enemy_scene_instance)
		await process_frame
		_check(enemy_scene_instance.get_node_or_null("EnemyAIController") is EnemyAIController, "enemy scene wires the AI controller")
		enemy_scene_instance.queue_free()
	var boss_scene := load("res://game/scenes/combat/boss_combatant.tscn") as PackedScene
	_check(boss_scene != null, "boss combatant scene loads")
	if boss_scene != null:
		var boss_scene_instance := boss_scene.instantiate()
		root.add_child(boss_scene_instance)
		await process_frame
		_check(boss_scene_instance.get_node_or_null("EnemyAIController") is EnemyAIController, "boss scene wires the AI controller")
		boss_scene_instance.queue_free()
	var enemy := CharacterBody3D.new()
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	var ai := EnemyAIController.new()
	ai.name = "EnemyAIController"
	enemy.add_child(health)
	enemy.add_child(ai)
	root.add_child(enemy)
	var player := Node3D.new()
	player.position = Vector3(0.0, 0.0, -8.0)
	root.add_child(player)
	await process_frame
	ai.set_target(player)
	_check(ai.current_state == EnemyAIController.State.ALERT, "acquiring a target enters ALERT")
	ai.update_decision(0.016)
	_check(ai.current_state == EnemyAIController.State.CHASE, "target outside attack range enters CHASE")
	player.position = Vector3(0.0, 0.0, -1.0)
	ai.update_decision(0.016)
	_check(ai.current_state == EnemyAIController.State.ATTACK, "target inside attack range enters ATTACK")
	ai.set_staggered(true)
	ai.update_decision(0.5)
	_check(ai.current_state == EnemyAIController.State.STAGGERED, "stagger suppresses normal decisions")
	ai.set_staggered(false)
	_check(ai.current_state == EnemyAIController.State.ALERT, "stagger recovery resumes target evaluation")
	health.apply_damage(100.0)
	_check(ai.current_state == EnemyAIController.State.DEAD, "authoritative health death transitions AI to DEAD")
	ai.set_target(player)
	_check(ai.current_state == EnemyAIController.State.DEAD, "dead enemy cannot reacquire a target")
	if failures == 0:
		print("RR-008 D1 enemy AI controller: PASS")
		quit(0)
	else:
		push_error("RR-008 D1 enemy AI controller: %d failure(s)" % failures)
		quit(1)
func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		failures += 1
		push_error("FAIL: %s" % description)
