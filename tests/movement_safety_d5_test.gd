extends SceneTree
## RR-003 D5 invalid-delta, configuration and actor-ownership safety tests.

const PRESERVED_VELOCITY := Vector3(1.25, -2.5, 3.75)
var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_invalid_deltas_are_no_ops()
	await _test_invalid_configuration_is_rejected()
	await _test_invalid_actor_ownership_is_safe()
	await _test_unowned_controller_is_safe()
	if failures == 0:
		print("RR-003 D5 movement safety tests: PASS")
		quit(0)
	else:
		push_error("RR-003 D5 movement safety tests: %d failure(s)" % failures)
		quit(1)


func _test_invalid_deltas_are_no_ops() -> void:
	var actor := _make_actor("DeltaSafetyActor")
	var controller := CharacterMovementController.new()
	controller.name = "MovementController"
	actor.add_child(controller)
	root.add_child(actor)
	await process_frame
	_check(controller.is_operational(), "valid CharacterBody3D ownership initializes the controller")
	actor.velocity = PRESERVED_VELOCITY
	var actor_position := actor.global_position
	controller.physics_step(0.0)
	_check(actor.velocity == PRESERVED_VELOCITY and actor.global_position == actor_position, "zero delta leaves actor state unchanged")
	controller.physics_step(-0.016)
	_check(actor.velocity == PRESERVED_VELOCITY and actor.global_position == actor_position, "negative delta leaves actor state unchanged")
	controller.physics_step(NAN)
	_check(actor.velocity == PRESERVED_VELOCITY and actor.global_position == actor_position, "NaN delta leaves actor state unchanged")
	controller.physics_step(INF)
	_check(actor.velocity == PRESERVED_VELOCITY and actor.global_position == actor_position, "infinite delta leaves actor state unchanged")
	actor.queue_free()
	await process_frame


func _test_invalid_configuration_is_rejected() -> void:
	var invalid_controller := CharacterMovementController.new()
	invalid_controller.lane_count = 2
	invalid_controller.lane_width = 0.0
	invalid_controller.acceleration = -1.0
	invalid_controller.braking = NAN
	invalid_controller.lateral_speed = INF
	invalid_controller.jump_velocity = 0.0
	invalid_controller.gravity = -9.8
	invalid_controller.combat_impulse_decay = 0.0
	var errors := invalid_controller.validate_configuration()
	_check(errors.size() >= 8, "configuration validator reports every invalid movement parameter")
	_check(_contains_diagnostic(errors, "lane_count"), "configuration diagnostic identifies invalid lane_count")
	_check(_contains_diagnostic(errors, "lane_width"), "configuration diagnostic identifies invalid lane_width")
	_check(_contains_diagnostic(errors, "acceleration"), "configuration diagnostic identifies invalid acceleration")
	_check(_contains_diagnostic(errors, "braking"), "configuration diagnostic identifies invalid braking")
	_check(_contains_diagnostic(errors, "lateral_speed"), "configuration diagnostic identifies invalid lateral_speed")
	_check(_contains_diagnostic(errors, "jump_velocity"), "configuration diagnostic identifies invalid jump_velocity")
	_check(_contains_diagnostic(errors, "gravity"), "configuration diagnostic identifies invalid gravity")
	_check(_contains_diagnostic(errors, "combat_impulse_decay"), "configuration diagnostic identifies invalid combat_impulse_decay")

	var actor := _make_actor("InvalidConfigurationActor")
	var attached := CharacterMovementController.new()
	attached.gravity = 0.0
	actor.add_child(attached)
	root.add_child(actor)
	await process_frame
	_check(not attached.is_operational(), "controller with invalid configuration is disabled during initialization")
	actor.velocity = PRESERVED_VELOCITY
	attached.physics_step(1.0 / float(Engine.physics_ticks_per_second))
	_check(actor.velocity == PRESERVED_VELOCITY, "disabled invalid-configuration controller cannot mutate its actor")
	actor.queue_free()
	await process_frame
	invalid_controller.free()


func _test_invalid_actor_ownership_is_safe() -> void:
	var container := Node3D.new()
	container.name = "InvalidControllerContainer"
	var controller := CharacterMovementController.new()
	controller.name = "OrphanedMovementController"
	container.add_child(controller)
	root.add_child(container)
	await process_frame
	_check(not controller.is_operational(), "controller under a non-CharacterBody3D parent is disabled")
	controller.physics_step(1.0 / float(Engine.physics_ticks_per_second))
	_check(not controller.is_operational(), "invalid owner cannot activate movement processing")
	container.queue_free()
	await process_frame


func _test_unowned_controller_is_safe() -> void:
	var controller := CharacterMovementController.new()
	controller.physics_step(1.0 / float(Engine.physics_ticks_per_second))
	_check(not controller.is_operational(), "unattached controller safely no-ops before entering the scene tree")
	controller.free()


func _make_actor(actor_name: String) -> CharacterBody3D:
	var actor := CharacterBody3D.new()
	actor.name = actor_name
	actor.position = Vector3(0.0, 1.0, 0.0)
	return actor


func _contains_diagnostic(errors: PackedStringArray, fragment: String) -> bool:
	for diagnostic in errors:
		if diagnostic.contains(fragment):
			return true
	return false


func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		failures += 1
		push_error("FAIL: %s" % description)
