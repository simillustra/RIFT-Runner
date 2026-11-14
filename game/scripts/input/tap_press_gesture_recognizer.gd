extends Control
class_name TapPressGestureRecognizer
## Tap, multi-tap, long-press and optional pressure-aware hard-press recognizer.
## Emits semantic intent only; it never invokes gameplay controllers.

signal command_emitted(command: MobileInputCommand)
signal gesture_recognized(gesture: StringName, action: int)

const NO_POINTER: int = -2
const MOUSE_POINTER: int = -1

@export var gesture_profile: TapPressGestureProfile
@export var source_id: StringName = &"gesture_tap_press"
@export var allow_mouse_input: bool = true

var _active_pointer: int = NO_POINTER
var _press_origin: Vector2 = Vector2.ZERO
var _press_elapsed: float = 0.0
var _press_pressure: float = 0.0
var _long_press_fired: bool = false
var _hard_press_fired: bool = false
var _pending_tap_count: int = 0
var _multi_tap_remaining: float = 0.0
var _sequence_id: int = 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if gesture_profile == null:
		gesture_profile = TapPressGestureProfile.new()


func _process(delta: float) -> void:
	advance_time(delta)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if begin_pointer(touch.index, touch.position, touch.pressure):
				accept_event()
		elif end_pointer(touch.index):
			accept_event()
	elif allow_mouse_input and event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.button_index == MOUSE_BUTTON_LEFT:
			if button.pressed:
				if begin_pointer(MOUSE_POINTER, button.position):
					accept_event()
			elif end_pointer(MOUSE_POINTER):
				accept_event()


func _input(event: InputEvent) -> void:
	if _active_pointer == NO_POINTER:
		return
	if event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _active_pointer:
			update_pointer(drag.index, _viewport_to_local(drag.position), drag.pressure)
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.index == _active_pointer:
			if touch.pressed:
				update_pressure(touch.index, touch.pressure)
			else:
				end_pointer(touch.index)
	elif allow_mouse_input and event is InputEventMouseMotion and _active_pointer == MOUSE_POINTER:
		var motion := event as InputEventMouseMotion
		update_pointer(MOUSE_POINTER, _viewport_to_local(motion.position))
	elif allow_mouse_input and event is InputEventMouseButton and _active_pointer == MOUSE_POINTER:
		var button := event as InputEventMouseButton
		if button.button_index == MOUSE_BUTTON_LEFT and not button.pressed:
			end_pointer(MOUSE_POINTER)


func begin_pointer(pointer_id: int, local_position: Vector2, pressure: float = 0.0) -> bool:
	if not is_enabled() or not is_visible_in_tree() or _active_pointer != NO_POINTER:
		return false
	if pointer_id == NO_POINTER or not Rect2(Vector2.ZERO, size).has_point(local_position):
		return false
	_active_pointer = pointer_id
	_press_origin = local_position
	_press_elapsed = 0.0
	_press_pressure = clampf(pressure, 0.0, 1.0)
	_long_press_fired = false
	_hard_press_fired = false
	if gesture_profile.enable_hard_press:
		_evaluate_hard_press()
	return true


func update_pointer(pointer_id: int, local_position: Vector2, pressure: float = -1.0) -> bool:
	if pointer_id != _active_pointer:
		return false
	if pressure >= 0.0:
		update_pressure(pointer_id, pressure)
	if local_position.distance_to(_press_origin) > gesture_profile.movement_tolerance_px:
		_reset_active_pointer()
	return true


func update_pressure(pointer_id: int, pressure: float) -> bool:
	if pointer_id != _active_pointer or not is_finite(pressure):
		return false
	_press_pressure = clampf(pressure, 0.0, 1.0)
	_evaluate_hard_press()
	return true


func end_pointer(pointer_id: int) -> bool:
	if pointer_id != _active_pointer:
		return false
	var was_recognized := _long_press_fired or _hard_press_fired
	_reset_active_pointer()
	if not was_recognized:
		_pending_tap_count = mini(_pending_tap_count + 1, 3)
		_multi_tap_remaining = gesture_profile.multi_tap_window_seconds
		if _pending_tap_count >= 3:
			_flush_pending_taps()
	return true


func cancel_active_pointer() -> void:
	_reset_active_pointer()
	_pending_tap_count = 0
	_multi_tap_remaining = 0.0


func advance_time(delta: float) -> void:
	if delta <= 0.0 or not is_finite(delta):
		return
	if _active_pointer != NO_POINTER and not _long_press_fired and not _hard_press_fired:
		_press_elapsed += delta
		if _press_elapsed >= gesture_profile.long_press_seconds:
			_long_press_fired = true
			_emit_action(&"long_press", gesture_profile.long_press_action)
	if _pending_tap_count > 0:
		_multi_tap_remaining = maxf(_multi_tap_remaining - delta, 0.0)
		if _multi_tap_remaining <= 0.0:
			_flush_pending_taps()


func is_enabled() -> bool:
	return source_id != &"" and gesture_profile != null and gesture_profile.validate().is_empty()


func has_active_pointer() -> bool:
	return _active_pointer != NO_POINTER


func get_pending_tap_count() -> int:
	return _pending_tap_count


func _evaluate_hard_press() -> void:
	if not gesture_profile.enable_hard_press or _hard_press_fired or _long_press_fired:
		return
	if _press_pressure >= gesture_profile.hard_press_pressure_threshold:
		_hard_press_fired = true
		_emit_action(&"hard_press", gesture_profile.hard_press_action)


func _flush_pending_taps() -> void:
	if _pending_tap_count <= 0:
		return
	var gesture: StringName
	var action: int
	match _pending_tap_count:
		1:
			gesture = &"tap"
			action = gesture_profile.tap_action
		2:
			gesture = &"double_tap"
			action = gesture_profile.double_tap_action
		_:
			gesture = &"triple_tap"
			action = gesture_profile.triple_tap_action
	_pending_tap_count = 0
	_multi_tap_remaining = 0.0
	_emit_action(gesture, action)


func _emit_action(gesture: StringName, action: int) -> void:
	for phase in [MobileInputAction.Phase.STARTED, MobileInputAction.Phase.PERFORMED]:
		_sequence_id += 1
		var command := MobileInputCommand.new()
		command.action = action
		command.phase = phase
		command.mode = MobileInputAction.Mode.FREE_HAND
		command.vector = Vector2.ZERO
		command.strength = 1.0
		command.source_id = source_id
		command.sequence_id = _sequence_id
		if command.is_valid():
			command_emitted.emit(command)
		else:
			push_error("TapPressGestureRecognizer generated an invalid command: %s" % "; ".join(command.validate()))
	gesture_recognized.emit(gesture, action)


func _reset_active_pointer() -> void:
	_active_pointer = NO_POINTER
	_press_origin = Vector2.ZERO
	_press_elapsed = 0.0
	_press_pressure = 0.0
	_long_press_fired = false
	_hard_press_fired = false


func _viewport_to_local(viewport_position: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * viewport_position


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		cancel_active_pointer()
	elif what == NOTIFICATION_PREDELETE or what == NOTIFICATION_EXIT_TREE:
		cancel_active_pointer()
