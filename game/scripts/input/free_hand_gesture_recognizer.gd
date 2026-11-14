extends Control
class_name FreeHandGestureRecognizer
## Free-hand swipe/drag recognizer. Emits intent only; gameplay remains authoritative.

signal command_emitted(command: MobileInputCommand)
signal swipe_recognized(direction: Vector2i, action: int)
signal drag_changed(value: Vector2)

const NO_POINTER: int = -2
const MOUSE_POINTER: int = -1

@export var gesture_profile: FreeHandGestureProfile
@export var source_id: StringName = &"gesture_free_hand"
@export var allow_mouse_input: bool = true

var _active_pointer: int = NO_POINTER
var _start_position: Vector2 = Vector2.ZERO
var _current_position: Vector2 = Vector2.ZERO
var _drag_active: bool = false
var _output_vector: Vector2 = Vector2.ZERO
var _sequence_id: int = 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if gesture_profile == null:
		gesture_profile = FreeHandGestureProfile.new()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if begin_pointer(touch.index, touch.position):
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
			update_pointer(drag.index, _viewport_to_local(drag.position))
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if not touch.pressed and touch.index == _active_pointer:
			end_pointer(touch.index)
	elif allow_mouse_input and event is InputEventMouseMotion and _active_pointer == MOUSE_POINTER:
		var motion := event as InputEventMouseMotion
		update_pointer(MOUSE_POINTER, _viewport_to_local(motion.position))
	elif allow_mouse_input and event is InputEventMouseButton and _active_pointer == MOUSE_POINTER:
		var button := event as InputEventMouseButton
		if button.button_index == MOUSE_BUTTON_LEFT and not button.pressed:
			end_pointer(MOUSE_POINTER)


func begin_pointer(pointer_id: int, local_position: Vector2) -> bool:
	if not is_visible_in_tree() or not is_enabled() or _active_pointer != NO_POINTER:
		return false
	if pointer_id == NO_POINTER or not Rect2(Vector2.ZERO, size).has_point(local_position):
		return false
	_active_pointer = pointer_id
	_start_position = local_position
	_current_position = local_position
	_drag_active = false
	_output_vector = Vector2.ZERO
	return true


func update_pointer(pointer_id: int, local_position: Vector2) -> bool:
	if pointer_id != _active_pointer:
		return false
	_current_position = local_position
	if gesture_profile.recognition_mode == FreeHandGestureProfile.RecognitionMode.CONTINUOUS_DRAG:
		_update_drag()
	return true


func end_pointer(pointer_id: int) -> bool:
	if pointer_id != _active_pointer:
		return false
	if gesture_profile.recognition_mode == FreeHandGestureProfile.RecognitionMode.DIRECTIONAL_SWIPE:
		_recognize_swipe()
	elif _drag_active:
		_emit_command(MobileInputAction.Action.MOVE, MobileInputAction.Phase.CANCELED, Vector2.ZERO, 0.0)
		_output_vector = Vector2.ZERO
		drag_changed.emit(Vector2.ZERO)
	_reset_pointer()
	return true


func cancel_active_pointer() -> void:
	if _active_pointer == NO_POINTER:
		return
	if _drag_active:
		_emit_command(MobileInputAction.Action.MOVE, MobileInputAction.Phase.CANCELED, Vector2.ZERO, 0.0)
		_output_vector = Vector2.ZERO
		drag_changed.emit(Vector2.ZERO)
	_reset_pointer()


func is_enabled() -> bool:
	return source_id != &"" and gesture_profile != null and gesture_profile.validate().is_empty()


func has_active_pointer() -> bool:
	return _active_pointer != NO_POINTER


func is_drag_active() -> bool:
	return _drag_active


func get_output_vector() -> Vector2:
	return _output_vector


func _update_drag() -> void:
	var displacement := _current_position - _start_position
	if not _drag_active:
		if displacement.length() < gesture_profile.drag_activation_threshold_px:
			return
		_drag_active = true
		_output_vector = _drag_vector(displacement)
		_emit_command(MobileInputAction.Action.MOVE, MobileInputAction.Phase.STARTED, _output_vector, _output_vector.length())
	else:
		_output_vector = _drag_vector(displacement)
		_emit_command(MobileInputAction.Action.MOVE, MobileInputAction.Phase.PERFORMED, _output_vector, _output_vector.length())
	drag_changed.emit(_output_vector)


func _drag_vector(displacement: Vector2) -> Vector2:
	var distance := displacement.length()
	if distance <= gesture_profile.drag_deadzone_px:
		return Vector2.ZERO
	var scaled_distance := clampf(
		(distance - gesture_profile.drag_deadzone_px)
		/ (gesture_profile.drag_full_scale_distance_px - gesture_profile.drag_deadzone_px),
		0.0,
		1.0
	)
	return Vector2(displacement.x, -displacement.y).normalized() * scaled_distance


func _recognize_swipe() -> void:
	var displacement := _current_position - _start_position
	if displacement.length() < gesture_profile.swipe_threshold_px:
		return
	var direction := Vector2i.ZERO
	if absf(displacement.x) >= absf(displacement.y):
		direction = Vector2i.RIGHT if displacement.x > 0.0 else Vector2i.LEFT
	else:
		direction = Vector2i.DOWN if displacement.y > 0.0 else Vector2i.UP
	var action := gesture_profile.action_for_direction(direction)
	_emit_command(action, MobileInputAction.Phase.STARTED, Vector2.ZERO, 1.0)
	_emit_command(action, MobileInputAction.Phase.PERFORMED, Vector2.ZERO, 1.0)
	swipe_recognized.emit(direction, action)


func _emit_command(action: int, phase: int, movement: Vector2, strength: float) -> void:
	_sequence_id += 1
	var command := MobileInputCommand.new()
	command.action = action
	command.phase = phase
	command.mode = MobileInputAction.Mode.FREE_HAND
	command.vector = movement
	command.strength = strength
	command.source_id = source_id
	command.sequence_id = _sequence_id
	if command.is_valid():
		command_emitted.emit(command)
	else:
		push_error("FreeHandGestureRecognizer generated an invalid command: %s" % "; ".join(command.validate()))


func _reset_pointer() -> void:
	_active_pointer = NO_POINTER
	_start_position = Vector2.ZERO
	_current_position = Vector2.ZERO
	_drag_active = false
	_output_vector = Vector2.ZERO


func _viewport_to_local(viewport_position: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * viewport_position


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		cancel_active_pointer()
	elif what == NOTIFICATION_PREDELETE or what == NOTIFICATION_EXIT_TREE:
		cancel_active_pointer()
