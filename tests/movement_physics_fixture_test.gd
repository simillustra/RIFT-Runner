extends SceneTree
## RR-003 D1 deterministic physics fixture using Godot's real collision solver.

const SETTLE_STEPS: int = 120
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
	actor.name = "PhysicsFixtureCharacter"
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

	_check(controller.get_parent() == actor, "fixture uses a real CharacterBody3D owner")
	_check(actor.get_node_or_null("CharacterCollisionShape") != null, "character fixture has a capsule collision shape")
	_check(floor_body.get_node_or_null("FloorCollisionShape") != null, "fixture has a static collision floor")
	controller.grounded_changed.connect(_on_grounded_changed)

	for _step in range(SETTLE_STEPS):
		await physics_frame

	_check(actor.is_on_floor(), "real CharacterBody3D settles onto the fixture floor")
	_check(controller.is_grounded, "movement controller reports grounded after floor contact")
	_check(absf(actor.global_position.y - 0.9) <= 0.03, "capsule rests at the expected floor-contact height")
	_check(grounded_events.size() == 1 and grounded_events[0], "grounded transition emits once when floor contact begins")

	actor.velocity.y = -2.0
	await physics_frame
	_check(is_zero_approx(actor.velocity.y), "grounded downward velocity is resolved by the floor")

	actor.global_position = Vector3(0.0, 5.0, 0.0)
	actor.velocity = Vector3.ZERO
	await physics_frame
	await physics_frame
	_check(not actor.is_on_floor(), "teleported character leaves floor contact")
	_check(not controller.is_grounded, "controller reports airborne after leaving the floor")
	_check(actor.velocity.y < 0.0, "gravity produces downward velocity while airborne")
	_check(grounded_events.size() == 2 and not grounded_events[1], "airborne transition emits once")

	actor.queue_free()
	floor_body.queue_free()
	await process_frame
	if failures == 0:
		print("RR-003 D1 deterministic physics fixture: PASS")
		quit(0)
	else:
		push_error("RR-003 D1 deterministic physics fixture: %d failure(s)" % failures)
		quit(1)


func _on_grounded_changed(value: bool) -> void:
	grounded_events.append(value)


func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		failures += 1
		push_error("FAIL: %s" % description)
