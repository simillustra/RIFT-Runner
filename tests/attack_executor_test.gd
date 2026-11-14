extends SceneTree
## RR-005 D2 AttackDefinition and AttackExecutor tests.

var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var definition := _make_definition()
	_check(definition.validate().is_empty(), "valid attack definition passes validation")

	var executor := AttackExecutor.new()
	root.add_child(executor)
	await process_frame
	executor.set_process(false)

	var source := Node.new()
	source.name = "AttackSource"
	root.add_child(source)
	var target_health := HealthComponent.new()
	target_health.max_health = 100.0
	root.add_child(target_health)
	var second_health := HealthComponent.new()
	second_health.max_health = 100.0
	root.add_child(second_health)
	await process_frame

	_check(executor.is_ready(), "executor starts ready")
	_check(executor.begin_attack(null, source) == ERR_INVALID_PARAMETER, "null attack definition is rejected")
	var invalid_definition := _make_definition()
	invalid_definition.damage = 0.0
	_check(executor.begin_attack(invalid_definition, source) == ERR_INVALID_DATA, "invalid attack definition is rejected")
	_check(executor.is_ready(), "rejected attack leaves executor ready")

	_check(executor.begin_attack(definition, source) == OK, "valid attack starts")
	_check(executor.phase == AttackExecutor.Phase.STARTUP, "attack enters startup phase")
	_check(executor.try_hit(target_health) == 0.0, "startup phase cannot apply damage")
	_check(executor.begin_attack(definition, source) == ERR_BUSY, "executor rejects overlapping attack requests")

	executor.update_timers(0.1)
	_check(executor.phase == AttackExecutor.Phase.STARTUP, "startup remains active before its duration expires")
	executor.update_timers(0.1)
	_check(executor.phase == AttackExecutor.Phase.ACTIVE, "startup transitions into active window")
	_check(executor.is_active(), "active phase is externally observable")
	_check(is_equal_approx(executor.try_hit(target_health), 20.0), "active window applies configured damage")
	_check(is_equal_approx(target_health.current_health, 80.0), "accepted attack reduces target health")
	_check(executor.has_registered_hit(target_health), "successful target is recorded for this attack")
	_check(executor.try_hit(target_health) == 0.0, "same target cannot be hit twice in one attack")
	_check(is_equal_approx(executor.try_hit(second_health), 20.0), "different target can be hit during the same active window")

	executor.update_timers(0.3)
	_check(executor.phase == AttackExecutor.Phase.RECOVERY, "active window transitions into recovery")
	_check(executor.try_hit(target_health) == 0.0, "recovery phase cannot apply damage")
	executor.update_timers(0.4)
	_check(executor.phase == AttackExecutor.Phase.COOLDOWN, "recovery transitions into cooldown")
	_check(not executor.is_ready(), "executor remains unavailable during cooldown")
	_check(executor.begin_attack(definition, source) == ERR_BUSY, "cooldown prevents a new attack")
	executor.update_timers(0.5)
	_check(executor.is_ready(), "cooldown expiry returns executor to ready")
	_check(executor.active_definition == null, "completed attack releases its definition")
	_check(executor.begin_attack(definition, source) == OK, "executor can start a new attack after cooldown")
	executor.cancel_attack()
	_check(executor.is_ready(), "explicit cancellation returns executor to ready")

	# Zero startup/recovery/cooldown values are supported; active duration remains positive.
	var fast_definition := _make_definition()
	fast_definition.startup_seconds = 0.0
	fast_definition.recovery_seconds = 0.0
	fast_definition.cooldown_seconds = 0.0
	_check(executor.begin_attack(fast_definition, source) == OK, "zero-startup attack enters active immediately")
	_check(executor.phase == AttackExecutor.Phase.ACTIVE, "zero startup begins active window synchronously")
	executor.update_timers(fast_definition.active_seconds)
	_check(executor.is_ready(), "zero recovery and cooldown complete after active window")

	# A single large timer step must advance through every remaining phase.
	var large_step_definition := _make_definition()
	large_step_definition.startup_seconds = 0.1
	large_step_definition.active_seconds = 0.1
	large_step_definition.recovery_seconds = 0.1
	large_step_definition.cooldown_seconds = 0.1
	_check(executor.begin_attack(large_step_definition, source) == OK, "large-step fixture attack starts")
	executor.update_timers(1.0)
	_check(executor.is_ready(), "large timer delta advances through startup, active, recovery and cooldown")

	executor.queue_free()
	source.queue_free()
	target_health.queue_free()
	second_health.queue_free()
	await process_frame

	if failures == 0:
		print("RR-005 D2 attack executor tests: PASS")
		quit(0)
	else:
		push_error("RR-005 D2 attack executor tests: %d failure(s)" % failures)
		quit(1)


func _make_definition() -> AttackDefinition:
	var definition := AttackDefinition.new()
	definition.attack_id = &"test_slash"
	definition.display_name = "Test Slash"
	definition.damage = 20.0
	definition.damage_type = &"physical"
	definition.startup_seconds = 0.2
	definition.active_seconds = 0.3
	definition.recovery_seconds = 0.4
	definition.cooldown_seconds = 0.5
	return definition


func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		failures += 1
		push_error("FAIL: %s" % description)
