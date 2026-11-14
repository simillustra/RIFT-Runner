extends SceneTree
## RR-003 D7 device-validation recorder contract tests.

var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var actor := CharacterBody3D.new()
	actor.name = "RecorderTestActor"
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	collider.shape = capsule
	actor.add_child(collider)
	var controller := CharacterMovementController.new()
	controller.name = "MovementController"
	actor.add_child(controller)
	root.add_child(actor)
	var recorder := MovementValidationRecorder.new()
	root.add_child(recorder)
	await process_frame
	await physics_frame

	_check(controller.is_operational(), "production movement controller is operational in recorder fixture")
	_check(recorder.begin_capture(actor, controller), "recorder starts with a directly owned operational controller")
	_check(not recorder.begin_capture(actor, controller), "recorder rejects a duplicate active capture")
	actor.velocity = Vector3(1.0, 0.0, -4.0)
	controller.is_grounded = true
	controller.lane_index = 2
	recorder.record_sample(1.0 / 60.0)
	recorder.record_sample(1.0 / 30.0)
	recorder.record_sample(1.0 / 120.0)
	recorder.record_sample(0.0)
	recorder.record_sample(-1.0)
	_check(recorder.get_sample_count() == 3, "only finite positive frame deltas are sampled")
	var report := recorder.finish_capture(false)
	_check(not recorder.is_capturing(), "finish_capture closes the active session")
	_check(int(report.get("schema_version", 0)) == 1, "report includes a versioned schema")
	_check(int(report.get("sample_count", 0)) == 3, "report includes the captured sample count")
	_check(float(report.get("session_duration_seconds", 0.0)) > 0.0, "report records session duration")
	var device: Dictionary = report.get("device", {})
	_check(device.has("os") and device.has("model") and device.has("renderer"), "report records OS, device model and renderer")
	var performance: Dictionary = report.get("performance", {})
	_check(float(performance.get("average_fps", 0.0)) > 0.0, "report calculates average FPS")
	_check(float(performance.get("minimum_sample_fps", 0.0)) > 0.0, "report calculates minimum sampled FPS")
	_check(float(performance.get("p95_frame_time_ms", 0.0)) > 0.0, "report calculates p95 frame time")
	var samples: Array = report.get("samples", [])
	_check(samples.size() == 3, "report preserves per-frame samples")
	if samples.size() == 3:
		var last: Dictionary = samples[2]
		_check(bool(last.get("grounded", false)), "samples capture grounded state")
		_check(int(last.get("lane_index", -1)) == 2, "samples capture lane index")
		_check((last.get("velocity", []) as Array).size() == 3, "samples capture actor velocity")
	_check(recorder.finish_capture(false).has("samples"), "repeated finish returns the last completed report")

	var invalid_recorder := MovementValidationRecorder.new()
	root.add_child(invalid_recorder)
	_check(not invalid_recorder.begin_capture(actor, CharacterMovementController.new()), "recorder rejects a controller not owned by the actor")
	actor.queue_free()
	recorder.queue_free()
	invalid_recorder.queue_free()
	await process_frame

	if failures == 0:
		print("RR-003 D7 movement validation recorder: PASS")
		quit(0)
	else:
		push_error("RR-003 D7 movement validation recorder: %d failure(s)" % failures)
		quit(1)


func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		failures += 1
		push_error("FAIL: %s" % description)
