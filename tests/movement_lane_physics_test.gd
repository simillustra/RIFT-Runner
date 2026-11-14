extends SceneTree
## RR-003 D3 deterministic lane-boundary and convergence tests.

const SETTLE_STEPS: int = 120
const CONVERGENCE_TIMEOUT_STEPS: int = 90
const POSITION_TOLERANCE: float = 0.015
var failures: int = 0
var lane_events: Array[int] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var floor_body := StaticBody3D.new()
	floor_body.name = "LanePhysicsFixtureFloor"
	var floor_shape := CollisionShape3D.new()
	var floor_box := BoxShape3D.new()
	floor_box.size = Vector3(30.0, 0.2, 200.0)
	floor_shape.shape = floor_box
	floor_body.add_child(floor_shape)
	floor_body.position = Vector3(0.0, -0.1, 0.0)
	root.add_child(floor_body)

	var actor := CharacterBody3D.new()
	actor.name = "LanePhysicsFixtureCharacter"
	actor.position = Vector3(0.0, 1.2, 0.0)
	var actor_shape := CollisionShape3D.new()
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
	controller.lane_changed.connect(_on_lane_changed)

	for _step in range(SETTLE_STEPS):
		await physics_frame
		if controller.is_grounded:
			break
	_check(actor.is_on_floor() and controller.is_grounded, "real CharacterBody3D is grounded before lane movement")
	_check(controller.lane_index == 1, "three-lane controller starts in the center lane")

	# Move to the left outer lane. Further left requests must be clamped.
	controller.request_lane_change(-1)
	controller.request_lane_change(-1)
	_check(controller.lane_index == 0, "repeated left requests stop at the left outer lane")
	_check(lane_events.size() == 1 and lane_events[0] == 0, "left boundary emits only the actual lane change")
	controller.request_lane_change(-1)
	controller.request_lane_change(0)
	_check(controller.lane_index == 0, "left boundary and zero direction do not change lane")
	_check(lane_events.size() == 1, "no-op lane requests do not emit lane_changed")

	var left_target := -controller.lane_width
	var previous_x := actor.global_position.x
	var left_converged := false
	for _step in range(CONVERGENCE_TIMEOUT_STEPS):
		await physics_frame
		var current_x := actor.global_position.x
		_check(current_x <= previous_x + POSITION_TOLERANCE, "left lane movement remains monotonic toward its target")
		_check(current_x >= left_target - POSITION_TOLERANCE, "left lane movement does not overshoot its outer lane center")
		previous_x = current_x
		if absf(current_x - left_target) <= POSITION_TOLERANCE:
			left_converged = true
			break
	_check(left_converged, "left lane movement converges on the exact outer lane center")
	# move_and_slide() retains the velocity used for the final movement step.
	# Observe one more physics tick so the controller can zero lateral velocity
	# after it starts exactly at the requested lane center.
	await physics_frame
	_check(absf(actor.global_position.x - left_target) <= POSITION_TOLERANCE, "left lane position remains stable after convergence")
	_check(absf(actor.velocity.x) <= POSITION_TOLERANCE, "lateral velocity settles at the left lane center")

	# Move across the center to the right outer lane and check the opposite bound.
	controller.request_lane_change(1)
	controller.request_lane_change(1)
	_check(controller.lane_index == 2, "repeated right requests stop at the right outer lane")
	_check(lane_events.size() == 3 and lane_events[1] == 1 and lane_events[2] == 2, "lane_changed emits each real intermediate lane exactly once")
	controller.request_lane_change(1)
	_check(controller.lane_index == 2, "right boundary rejects further outward requests")
	_check(lane_events.size() == 3, "right boundary no-op does not emit lane_changed")

	var right_target := controller.lane_width
	previous_x = actor.global_position.x
	var right_converged := false
	for _step in range(CONVERGENCE_TIMEOUT_STEPS):
		await physics_frame
		var current_x := actor.global_position.x
		_check(current_x >= previous_x - POSITION_TOLERANCE, "right lane movement remains monotonic toward its target")
		_check(current_x <= right_target + POSITION_TOLERANCE, "right lane movement does not overshoot its outer lane center")
		previous_x = current_x
		if absf(current_x - right_target) <= POSITION_TOLERANCE:
			right_converged = true
			break
	_check(right_converged, "right lane movement converges on the exact outer lane center")
	await physics_frame
	_check(absf(actor.global_position.x - right_target) <= POSITION_TOLERANCE, "right lane position remains stable after convergence")
	_check(absf(actor.velocity.x) <= POSITION_TOLERANCE, "lateral velocity settles at the right lane center")

	actor.queue_free()
	floor_body.queue_free()
	await process_frame
	if failures == 0:
		print("RR-003 D3 lane physics tests: PASS")
		quit(0)
	else:
		push_error("RR-003 D3 lane physics tests: %d failure(s)" % failures)
		quit(1)


func _on_lane_changed(index: int) -> void:
	lane_events.append(index)


func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		failures += 1
		push_error("FAIL: %s" % description)
