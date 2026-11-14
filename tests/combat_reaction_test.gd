extends SceneTree
## RR-005 D6 hit reaction, stagger, knockback and death-presentation tests.

var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var actor_scene := load("res://game/scenes/characters/character_actor.tscn") as PackedScene
	_check(actor_scene != null, "CharacterActor scene loads with combat reactions")
	if actor_scene == null:
		_finish()
		return
	var actor := actor_scene.instantiate() as CharacterActor
	actor.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(actor)
	await process_frame
	var health := actor.get_node("HealthComponent") as HealthComponent
	var movement := actor.get_node("MovementController") as CharacterMovementController
	var executor := actor.get_node("AttackExecutor") as AttackExecutor
	var reactions := actor.get_node("CombatReactionController") as CombatReactionController
	movement.set_physics_process(false)
	reactions.set_physics_process(false)
	actor.velocity = Vector3.ZERO
	var source := Node3D.new()
	source.position = Vector3(-2.0, 0.0, 0.0)
	root.add_child(source)
	await process_frame

	var hit_reacted_count := [0]
	var stagger_count := [0]
	var knockback_count := [0]
	reactions.hit_reacted.connect(func(_damage: float, _type: StringName) -> void: hit_reacted_count[0] += 1)
	reactions.stagger_started.connect(func(_duration: float) -> void: stagger_count[0] += 1)
	reactions.knockback_applied.connect(func(_impulse: Vector3) -> void: knockback_count[0] += 1)

	var applied := health.apply_damage(20.0, source, &"physical")
	_check(is_equal_approx(applied, 20.0), "incoming damage remains authoritative in D1")
	_check(hit_reacted_count[0] == 1, "accepted damage emits one hit-reaction presentation event")
	_check(stagger_count[0] == 1, "accepted damage requests a stagger window")
	_check(knockback_count[0] == 1, "accepted damage produces a knockback impulse")
	_check(actor.velocity.x > 0.0, "source position determines outward knockback direction")
	_check(movement.get_stagger_remaining() > 0.0, "movement controller owns the stagger lock")
	_check(reactions.get_fallback_stagger_remaining() == 0.0, "character movement path does not create a second stagger timer")

	# Lethal damage supersedes hit reaction and permanently disables combat collision.
	health.invulnerability_seconds = 0.0
	executor.begin_attack(_make_attack(), actor)
	_check(not executor.is_ready(), "fixture starts an attack before lethal damage")
	health.apply_damage(1000.0, source, &"physical")
	_check(health.is_dead, "D1 remains authoritative for death")
	_check(reactions.is_dead(), "death presentation is entered exactly once")
	_check(movement.is_dead, "dead actor movement is disabled")
	_check(executor.is_ready(), "death cancels any active attack executor")
	var body_shape := actor.get_node("CollisionShape3D") as CollisionShape3D
	_check(body_shape.disabled, "death presentation disables the actor collision shape")
	_check(not reactions.is_dead() == false, "death state remains terminal")

	actor.queue_free()
	source.queue_free()
	await process_frame
	_finish()


func _make_attack() -> AttackDefinition:
	var attack := AttackDefinition.new()
	attack.attack_id = &"death_fixture"
	attack.display_name = "Death Fixture"
	attack.damage = 1.0
	attack.damage_type = &"physical"
	attack.startup_seconds = 0.2
	attack.active_seconds = 0.2
	attack.recovery_seconds = 0.2
	attack.cooldown_seconds = 0.2
	return attack


func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		failures += 1
		push_error("FAIL: %s" % description)


func _finish() -> void:
	if failures == 0:
		print("RR-005 D6 combat reaction tests: PASS")
		quit(0)
	else:
		push_error("RR-005 D6 combat reaction tests: %d failure(s)" % failures)
		quit(1)
