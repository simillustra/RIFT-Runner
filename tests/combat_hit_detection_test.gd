extends SceneTree
## RR-005 D3 collision, filtering and D1/D2 integration tests.

var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var attacker := Node3D.new()
	attacker.name = "Attacker"
	attacker.position = Vector3.ZERO
	var executor := AttackExecutor.new()
	executor.name = "AttackExecutor"
	attacker.add_child(executor)
	var hitbox := CombatHitbox.new()
	hitbox.name = "Hitbox"
	hitbox.attacker_team_id = &"heroes"
	hitbox.collision_layer = 0
	hitbox.collision_mask = 2
	attacker.add_child(hitbox)
	var hit_shape := CollisionShape3D.new()
	var hit_sphere := SphereShape3D.new()
	hit_sphere.radius = 1.25
	hit_shape.shape = hit_sphere
	hitbox.add_child(hit_shape)
	root.add_child(attacker)

	var enemy := _make_target("Enemy", Vector3(0.5, 0.0, 0.0), &"infected")
	var friendly := _make_target("Friendly", Vector3(0.0, 0.0, 0.5), &"heroes")
	root.add_child(enemy)
	root.add_child(friendly)
	await process_frame
	await physics_frame
	await physics_frame

	_check(executor != null and not hitbox.monitoring, "hitbox is dormant outside an active attack window")
	var definition := _make_definition()
	definition.startup_seconds = 0.1
	definition.active_seconds = 0.25
	definition.recovery_seconds = 0.1
	definition.cooldown_seconds = 0.1
	_check(executor.begin_attack(definition, attacker) == OK, "attack starts through D2 executor")
	_check(not hitbox.monitoring, "startup does not enable collision hit detection")
	_check(is_equal_approx(_health(enemy).current_health, 100.0), "startup overlap cannot damage target")

	# Advance the authoritative D2 timer; the active-window signal enables physics detection.
	executor.update_timers(0.1)
	_check(executor.is_active() and hitbox.monitoring, "D2 active-window signal enables hitbox monitoring")
	await physics_frame
	await physics_frame
	await physics_frame
	_check(is_equal_approx(_health(enemy).current_health, 80.0), "enemy overlap routes damage through AttackExecutor to D1 health")
	_check(is_equal_approx(_health(friendly).current_health, 100.0), "same-team target is filtered before hit registration")
	_check(executor.has_registered_hit(_health(enemy)), "collision hit registers target in D2 executor")

	# Repeated overlap notifications must not cause a second hit.
	hitbox._on_area_entered(_hurtbox(enemy))
	_check(is_equal_approx(_health(enemy).current_health, 80.0), "repeated overlap cannot damage a target twice in one attack")

	executor.update_timers(0.25)
	_check(executor.phase == AttackExecutor.Phase.RECOVERY, "active window closes into D2 recovery")
	_check(not hitbox.monitoring, "recovery disables hitbox monitoring")
	await physics_frame
	_check(is_equal_approx(_health(enemy).current_health, 80.0), "recovery overlap cannot apply damage")

	# Dead and disabled hurtboxes are not eligible targets.
	_hurtbox(enemy).set_hurtbox_enabled(false)
	_check(_hurtbox(enemy).get_health_component() == null, "disabled hurtbox does not expose a damage receiver")
	_check(_health(enemy).apply_damage(1000.0) == 80.0, "fixture can independently validate lethal D1 damage")
	_check(_hurtbox(enemy).get_health_component() == null, "dead target is not exposed as hittable")

	attacker.queue_free()
	enemy.queue_free()
	friendly.queue_free()
	await process_frame

	if failures == 0:
		print("RR-005 D3 collision hit detection tests: PASS")
		quit(0)
	else:
		push_error("RR-005 D3 collision hit detection tests: %d failure(s)" % failures)
		quit(1)


func _make_target(target_name: String, target_position: Vector3, team: StringName) -> Node3D:
	var target := Node3D.new()
	target.name = target_name
	target.position = target_position
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	health.max_health = 100.0
	target.add_child(health)
	var hurtbox := CombatHurtbox.new()
	hurtbox.name = "Hurtbox"
	hurtbox.team_id = team
	hurtbox.collision_layer = 2
	hurtbox.collision_mask = 0
	target.add_child(hurtbox)
	var shape_node := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.5
	shape_node.shape = sphere
	hurtbox.add_child(shape_node)
	return target


func _health(target: Node3D) -> HealthComponent:
	return target.get_node("HealthComponent") as HealthComponent


func _hurtbox(target: Node3D) -> CombatHurtbox:
	return target.get_node("Hurtbox") as CombatHurtbox


func _make_definition() -> AttackDefinition:
	var definition := AttackDefinition.new()
	definition.attack_id = &"collision_test"
	definition.display_name = "Collision Test"
	definition.damage = 20.0
	definition.damage_type = &"physical"
	definition.startup_seconds = 0.1
	definition.active_seconds = 0.25
	definition.recovery_seconds = 0.1
	definition.cooldown_seconds = 0.1
	return definition


func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		failures += 1
		push_error("FAIL: %s" % description)
