extends SceneTree
## RR-005 D1 health and damage contract tests.

var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var health := HealthComponent.new()
	health.max_health = 100.0
	health.defense = 5.0
	health.invulnerability_seconds = 0.5
	root.add_child(health)
	await process_frame

	_check(is_equal_approx(health.current_health, 100.0), "health initializes to configured maximum")
	_check(is_equal_approx(health.get_health_ratio(), 1.0), "full health reports a ratio of one")
	_check(is_equal_approx(health.apply_damage(30.0), 25.0), "defense reduces incoming damage")
	_check(is_equal_approx(health.current_health, 75.0), "accepted damage reduces current health")
	_check(is_equal_approx(health.apply_damage(20.0), 0.0), "temporary invulnerability blocks subsequent damage")
	health.update_timers(0.5)
	_check(is_equal_approx(health.apply_damage(2.0), 1.0), "damage always applies at least one point after defense")
	_check(is_equal_approx(health.heal(50.0), 26.0), "healing is capped at maximum health")
	_check(is_equal_approx(health.heal(100.0), 0.0), "healing at maximum health has no effect")
	_check(is_equal_approx(health.current_health, 100.0), "health never exceeds its maximum")
	health.update_timers(0.5)
	_check(is_equal_approx(health.apply_damage(500.0), 100.0), "lethal damage is capped at remaining health")
	_check(health.is_dead, "lethal damage marks the component dead")
	_check(is_equal_approx(health.apply_damage(10.0), 0.0), "dead actors reject further damage")
	_check(is_equal_approx(health.heal(10.0), 0.0), "dead actors cannot be healed without reset")
	health.reset_health()
	_check(not health.is_dead and is_equal_approx(health.current_health, 100.0), "explicit reset restores a dead actor")
	_check(is_equal_approx(health.apply_damage(0.0), 0.0), "zero damage is ignored")
	_check(is_equal_approx(health.apply_damage(-5.0), 0.0), "negative damage is ignored")
	_check(health.configure(0.0, 0.0) == ERR_INVALID_PARAMETER, "invalid maximum health is rejected")
	_check(health.configure(120.0, 12.0) == OK, "valid character attributes can configure health")
	_check(is_equal_approx(health.max_health, 120.0) and is_equal_approx(health.defense, 12.0), "configured health and defense are applied")
	_check(is_equal_approx(health.current_health, 120.0), "configuration initializes health to the new maximum")
	health.queue_free()
	await process_frame

	var actor_scene := load("res://game/scenes/characters/character_actor.tscn") as PackedScene
	_check(actor_scene != null, "CharacterActor scene loads with health composition")
	if actor_scene != null:
		var actor := actor_scene.instantiate() as CharacterActor
		actor.process_mode = Node.PROCESS_MODE_DISABLED
		var stats := CharacterStats.new()
		stats.max_health = 180.0
		stats.defense = 14.0
		var definition := CharacterDefinition.new()
		definition.character_id = &"health_test"
		definition.display_name = "Health Test"
		definition.archetype = &"vanguard"
		definition.stats = stats
		_check(actor.assign_definition(definition) == OK, "valid character definition is accepted")
		root.add_child(actor)
		await process_frame
		var actor_health := actor.get_node_or_null("HealthComponent") as HealthComponent
		_check(actor_health != null, "CharacterActor owns a HealthComponent")
		if actor_health != null:
			_check(is_equal_approx(actor_health.max_health, 180.0), "character maximum health configures the health component")
			_check(is_equal_approx(actor_health.defense, 14.0), "character defense configures the health component")
			_check(is_equal_approx(actor_health.current_health, 180.0), "new character starts at full configured health")
		actor.queue_free()
		await process_frame

	if failures == 0:
		print("RR-005 D1 health and damage tests: PASS")
		quit(0)
	else:
		push_error("RR-005 D1 health and damage tests: %d failure(s)" % failures)
		quit(1)


func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		failures += 1
		push_error("FAIL: %s" % description)
