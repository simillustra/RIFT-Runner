extends SceneTree
## RR-003 D4 camera-relative free-movement physics tests.

const FIXTURE_SPEED: float = 5.0
const VELOCITY_TOLERANCE: float = 0.12
const SETTLE_FRAMES: int = 120
var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var floor_body := StaticBody3D.new()
	floor_body.name = "FreeMovementFixtureFloor"
	var floor_shape := CollisionShape3D.new()
	var floor_box := BoxShape3D.new()
	floor_box.size = Vector3(100.0, 0.2, 200.0)
	floor_shape.shape = floor_box
	floor_body.add_child(floor_shape)
	floor_body.position = Vector3(0.0, -0.1, 0.0)
	root.add_child(floor_body)

	var actor := CharacterBody3D.new()
	actor.name = "FreeMovementFixtureCharacter"
	actor.position = Vector3(0.0, 1.2, 0.0)
	var actor_shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	actor_shape.shape = capsule
	actor.add_child(actor_shape)
	var controller := CharacterMovementController.new()
	controller.name = "MovementController"
	controller.movement_mode = CharacterMovementController.MovementMode.FREE
	actor.add_child(controller)
	root.add_child(actor)
	await process_frame

	for _step in range(SETTLE_FRAMES):
		await physics_frame
		if controller.is_grounded:
			break
	_check(actor.is_on_floor() and controller.is_grounded, "free-movement CharacterBody3D fixture is grounded")
	_check(controller.movement_mode == CharacterMovementController.MovementMode.FREE, "fixture uses free movement mode")

	# A camera yaw of +90 degrees rotates local forward (-Z) onto world -X.
	controller.set_camera_basis(Basis(Vector3.UP, PI / 2.0))
	controller.set_move_intent(Vector2(0.0, 1.0))
	for _step in range(SETTLE_FRAMES):
		await physics_frame
	var yaw_planar := Vector2(actor.velocity.x, actor.velocity.z)
	_check(yaw_planar.x < -FIXTURE_SPEED + VELOCITY_TOLERANCE, "forward input follows the camera's rotated world direction")
	_check(absf(yaw_planar.y) <= VELOCITY_TOLERANCE, "camera-relative forward input has no unintended lateral component")
	_check(absf(yaw_planar.length() - FIXTURE_SPEED) <= VELOCITY_TOLERANCE, "camera-relative movement reaches configured run speed")
	_check(absf(actor.velocity.y) <= VELOCITY_TOLERANCE, "camera yaw does not introduce vertical velocity")

	# A pitched camera basis must still produce planar movement, not flight.
	actor.velocity = Vector3.ZERO
	controller.set_camera_basis(Basis(Vector3.RIGHT, deg_to_rad(-35.0)))
	controller.set_move_intent(Vector2(0.0, 1.0))
	for _step in range(SETTLE_FRAMES):
		await physics_frame
	var pitched_planar := Vector2(actor.velocity.x, actor.velocity.z)
	_check(absf(pitched_planar.length() - FIXTURE_SPEED) <= VELOCITY_TOLERANCE, "pitched camera movement is flattened and normalized in the ground plane")
	_check(absf(actor.velocity.y) <= VELOCITY_TOLERANCE, "camera pitch never converts movement input into vertical motion")

	# Diagonal input is normalized before applying the configured run speed.
	actor.velocity = Vector3.ZERO
	controller.set_camera_basis(Basis.IDENTITY)
	controller.set_move_intent(Vector2.ONE)
	for _step in range(SETTLE_FRAMES):
		await physics_frame
	var diagonal_planar := Vector2(actor.velocity.x, actor.velocity.z)
	_check(absf(diagonal_planar.length() - FIXTURE_SPEED) <= VELOCITY_TOLERANCE, "diagonal input is normalized to the same speed as cardinal input")
	_check(absf(absf(diagonal_planar.x) - FIXTURE_SPEED / sqrt(2.0)) <= VELOCITY_TOLERANCE, "diagonal X velocity is normalized")
	_check(absf(absf(diagonal_planar.y) - FIXTURE_SPEED / sqrt(2.0)) <= VELOCITY_TOLERANCE, "diagonal Z velocity is normalized")

	# Releasing intent applies braking until both planar velocity components settle.
	controller.set_move_intent(Vector2.ZERO)
	for _step in range(SETTLE_FRAMES):
		await physics_frame
	var released_planar := Vector2(actor.velocity.x, actor.velocity.z)
	_check(released_planar.length() <= VELOCITY_TOLERANCE, "released movement intent brakes planar velocity to zero")

	actor.queue_free()
	floor_body.queue_free()
	await process_frame
	if failures == 0:
		print("RR-003 D4 free movement physics tests: PASS")
		quit(0)
	else:
		push_error("RR-003 D4 free movement physics tests: %d failure(s)" % failures)
		quit(1)


func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		failures += 1
		push_error("FAIL: %s" % description)
