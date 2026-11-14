extends Node
class_name MovementValidationRecorder
## Captures reproducible RR-003 movement and frame-time evidence during device playtests.
## Attach to a test scene and call begin_capture(actor, controller) / finish_capture().

var _actor: CharacterBody3D
var _controller: CharacterMovementController
var _capturing: bool = false
var _elapsed_seconds: float = 0.0
var _frame_times: PackedFloat64Array = PackedFloat64Array()
var _samples: Array[Dictionary] = []
var _started_unix_seconds: int = 0
var _last_report: Dictionary = {}


func begin_capture(actor: CharacterBody3D, controller: CharacterMovementController) -> bool:
	if _capturing or not is_instance_valid(actor) or not is_instance_valid(controller):
		return false
	if controller.get_parent() != actor or not controller.is_operational():
		return false
	_actor = actor
	_controller = controller
	_capturing = true
	_elapsed_seconds = 0.0
	_frame_times.clear()
	_samples.clear()
	_started_unix_seconds = int(Time.get_unix_time_from_system())
	_last_report.clear()
	return true


func _process(delta: float) -> void:
	if _capturing:
		record_sample(delta)


## Public for deterministic tests; normal sessions call this from _process.
func record_sample(delta: float) -> void:
	if not _capturing or not is_finite(delta) or delta <= 0.0:
		return
	if not is_instance_valid(_actor) or not is_instance_valid(_controller):
		return
	_elapsed_seconds += delta
	_frame_times.append(delta)
	_samples.append({
		"elapsed_seconds": _elapsed_seconds,
		"frame_time_ms": delta * 1000.0,
		"fps": 1.0 / delta,
		"position": [_actor.global_position.x, _actor.global_position.y, _actor.global_position.z],
		"velocity": [_actor.velocity.x, _actor.velocity.y, _actor.velocity.z],
		"grounded": _controller.is_grounded,
		"lane_index": _controller.lane_index,
		"movement_mode": int(_controller.movement_mode)
	})


func finish_capture(write_report: bool = true) -> Dictionary:
	if not _capturing:
		return _last_report.duplicate(true)
	_capturing = false
	var sorted_times := _frame_times.duplicate()
	sorted_times.sort()
	var average_fps := float(_frame_times.size()) / _elapsed_seconds if _elapsed_seconds > 0.0 else 0.0
	var min_fps := 0.0
	if not sorted_times.is_empty():
		min_fps = 1.0 / sorted_times[sorted_times.size() - 1]
	var report := {
		"schema_version": 1,
		"started_unix_seconds": _started_unix_seconds,
		"captured_at_unix_seconds": int(Time.get_unix_time_from_system()),
		"session_duration_seconds": _elapsed_seconds,
		"sample_count": _samples.size(),
		"device": {
			"os": OS.get_name(),
			"model": OS.get_model_name(),
			"screen_width": DisplayServer.screen_get_size().x,
			"screen_height": DisplayServer.screen_get_size().y,
			"godot_version": Engine.get_version_info().get("string", "unknown"),
			"renderer": str(ProjectSettings.get_setting("rendering/renderer/rendering_method", "unknown"))
		},
		"performance": {
			"average_fps": average_fps,
			"minimum_sample_fps": min_fps,
			"p95_frame_time_ms": _percentile(sorted_times, 0.95) * 1000.0
		},
		"samples": _samples.duplicate(true)
	}
	_last_report = report
	if write_report:
		var path := "user://rr003_movement_validation_%d.json" % _started_unix_seconds
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file == null:
			report["write_error"] = "Unable to open report path: %s (error %d)" % [path, FileAccess.get_open_error()]
		else:
			file.store_string(JSON.stringify(report, "\t"))
			file.close()
			report["report_path"] = path
		_last_report = report
	return report


func is_capturing() -> bool:
	return _capturing


func get_sample_count() -> int:
	return _samples.size()


func get_last_report() -> Dictionary:
	return _last_report.duplicate(true)


func _percentile(sorted_values: PackedFloat64Array, percentile: float) -> float:
	if sorted_values.is_empty():
		return 0.0
	var index := clampi(int(ceil(percentile * sorted_values.size())) - 1, 0, sorted_values.size() - 1)
	return sorted_values[index]
