extends Control
class_name VirtualJoystick
## Fixed-position radial joystick. Emits semantic MOVE commands only;
## CharacterMovementController remains the movement authority.

signal vector_changed(value: Vector2)
signal command_emitted(command: MobileInputCommand)

@export_range(16.0, 160.0, 1.0) var base_radius: float = 64.0
@export_range(8.0, 64.0, 1.0) var knob_radius: float = 24.0
@export_range(0.0, 0.8, 0.01) var deadzone: float = 0.12
@export var source_id: StringName = &"joystick_primary"
@export var allow_mouse_input: bool = true
@export var joystick_mode: MobileInputAction.Mode = MobileInputAction.Mode.GUIDED
@export var base_color: Color = Color(0.12, 0.16, 0.22, 0.58)
@export var knob_color: Color = Color(0.72, 0.82, 0.96, 0.88)

const NO_POINTER: int = -2
const MOUSE_POINTER: int = -1

var _active_pointer: int = NO_POINTER
var _knob_offset: Vector2 = Vector2.ZERO
var _output_vector: Vector2 = Vector2.ZERO
var _sequence_id: int = 0


func _ready() -> void:
	custom_minimum_size = Vector2(160.0, 160.0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if begin_pointer(touch.index, touch.position):
				accept_event()
		else:
			if end_pointer(touch.index):
				accept_event()
	elif allow_mouse_input and event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_LEFT:
			if mouse_button.pressed:
				if begin_pointer(MOUSE_POINTER, mouse_button.position):
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
	_update_from_position(local_position, MobileInputAction.Phase.STARTED)
	return true


func update_pointer(pointer_id: int, local_position: Vector2) -> bool:
	if pointer_id != _active_pointer:
		return false
	_update_from_position(local_position, MobileInputAction.Phase.PERFORMED)
	return true


func end_pointer(pointer_id: int) -> bool:
	if pointer_id != _active_pointer:
		return false
	_active_pointer = NO_POINTER
	_knob_offset = Vector2.ZERO
	_output_vector = Vector2.ZERO
	_emit_command(MobileInputAction.Phase.CANCELED)
	vector_changed.emit(Vector2.ZERO)
	queue_redraw()
	return true


func cancel_active_pointer() -> void:
	if _active_pointer != NO_POINTER:
		end_pointer(_active_pointer)


func is_enabled() -> bool:
	return source_id != &"" and base_radius > 0.0 and knob_radius > 0.0 and deadzone >= 0.0 and deadzone < 1.0


func get_output_vector() -> Vector2:
	return _output_vector


func has_active_pointer() -> bool:
	return _active_pointer != NO_POINTER


func _update_from_position(local_position: Vector2, phase: int) -> void:
	var center := size * 0.5
	var displacement := local_position - center
	var clamped := displacement.limit_length(base_radius)
	_knob_offset = clamped
	var raw := clamped / base_radius
	var magnitude := raw.length()
	if magnitude <= deadzone:
		_output_vector = Vector2.ZERO
	else:
		var scaled_magnitude := clampf((magnitude - deadzone) / (1.0 - deadzone), 0.0, 1.0)
		_output_vector = Vector2(raw.x, -raw.y).normalized() * scaled_magnitude
	_emit_command(phase)
	vector_changed.emit(_output_vector)
	queue_redraw()


func _emit_command(phase: int) -> void:
	_sequence_id += 1
	var command := MobileInputCommand.new()
	command.action = MobileInputAction.Action.MOVE
	command.phase = phase
	command.mode = joystick_mode
	command.vector = Vector2.ZERO if phase == MobileInputAction.Phase.CANCELED else _output_vector
	command.strength = command.vector.length()
	command.source_id = source_id
	command.sequence_id = _sequence_id
	if command.is_valid():
		command_emitted.emit(command)
	else:
		push_error("VirtualJoystick generated an invalid MobileInputCommand: %s" % "; ".join(command.validate()))


func _viewport_to_local(viewport_position: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * viewport_position


func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, base_radius, base_color)
	draw_arc(center, base_radius, 0.0, TAU, 48, Color(0.72, 0.82, 0.96, 0.45), 2.0)
	draw_circle(center + _knob_offset, knob_radius, knob_color)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		cancel_active_pointer()
	elif what == NOTIFICATION_PREDELETE or what == NOTIFICATION_EXIT_TREE:
		cancel_active_pointer()
