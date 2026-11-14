extends SceneTree
## RR-003 D2 deterministic jump and grounded/airborne transition tests.

const SETTLE_STEPS: int = 120
const LANDING_TIMEOUT_STEPS: int = 180
const GROUNDED_HOLD_STEPS: int = 8
var failures: int = 0
var grounded_events: Array[bool] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var floor_body := StaticBody3D.new()
	floor_body.name = "PhysicsFixtureFloor"
	var floor_shape := CollisionShape3D.new()
	floor_shape.name = "FloorCollisionShape"
	var floor_box := BoxShape3D.new()
	floor_box.size = Vector3(30.0, 0.2, 30.0)
	floor_shape.shape = floor_box
	floor_body.add_child(floor_shape)
	floor_body.position = Vector3(0.0, -0.1, 0.0)
	root.add_child(floor_body)

	var actor := CharacterBody3D.new()
	actor.name = "JumpPhysicsFixtureCharacter"
	actor.position = Vector3(0.0, 1.2, 0.0)
	actor.floor_snap_length = 0.2
	var actor_shape := CollisionShape3D.new()
	actor_shape.name = "CharacterCollisionShape"
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	actor_shape.shape = capsule
	actor.add_child(actor_shape)

	var controller := CharacterMovementController.new()
	controller.name = "MovementController"
	actor.add_child(controller)
	root.add_child(actor)
	await process_frame
	controller.grounded_changed.connect(_on_grounded_changed)

	for _step in range(SETTLE_STEPS):
		await physics_frame
		if controller.is_grounded:
			break

	_check(actor.is_on_floor() and controller.is_grounded, "fixture settles on real floor before jump tests")
	_check(grounded_events.size() == 1 and grounded_events[0], "initial grounded transition emits once")

	actor.velocity.y = -1.0
	await physics_frame
	_check(is_zero_approx(actor.velocity.y), "grounded downward velocity is cleared")
	for _step in range(GROUNDED_HOLD_STEPS):
		await physics_frame
	_check(is_zero_approx(actor.velocity.y), "gravity does not accumulate downward velocity while grounded")

	controller.request_jump()
	await physics_frame
	_check(actor.velocity.y >= controller.jump_velocity - 0.001, "grounded jump launches at configured upward velocity")
	_check(not actor.is_on_floor() and not controller.is_grounded, "jump transitions character to airborne state")
	_check(grounded_events.size() == 2 and not grounded_events[1], "takeoff emits one airborne transition")

	var upward_velocity_before_rejected_jump := actor.velocity.y
	controller.request_jump()
	await physics_frame
	var expected_velocity := upward_velocity_before_rejected_jump - controller.gravity * (1.0 / float(Engine.physics_ticks_per_second))
	_check(absf(actor.velocity.y - expected_velocity) <= 0.03, "airborne jump request is ignored while normal gravity continues")
	_check(actor.velocity.y < upward_velocity_before_rejected_jump, "airborne request does not reset upward velocity for a second jump")

	var landed := false
	for _step in range(LANDING_TIMEOUT_STEPS):
		await physics_frame
		if controller.is_grounded and actor.is_on_floor():
			landed = true
			break
	_check(landed, "jump arc returns character to the fixture floor")
	_check(grounded_events.size() == 3 and grounded_events[2], "landing emits one grounded transition")

	for _step in range(GROUNDED_HOLD_STEPS):
		await physics_frame
	_check(is_zero_approx(actor.velocity.y), "landed character remains grounded without accumulating gravity")
	_check(grounded_events.size() == 3, "grounded transition is not emitted repeatedly while standing")

	actor.queue_free()
	floor_body.queue_free()
	await process_frame
	if failures == 0:
		print("RR-003 D2 jump physics tests: PASS")
		quit(0)
	else:
		push_error("RR-003 D2 jump physics tests: %d failure(s)" % failures)
		quit(1)


func _on_grounded_changed(value: bool) -> void:
	grounded_events.append(value)


func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		failures += 1
		push_error("FAIL: %s" % description)
