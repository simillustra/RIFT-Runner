extends Node
class_name MobileInputContextController
## RR-006 D6 owner for atomic control-mode and gameplay-context transitions.

enum Context {
	GAMEPLAY,
	PAUSED,
	MENU,
	DIALOG,
	LOADING,
	DEAD,
	TRANSITION,
	CUTSCENE,
}

signal control_mode_changed(mode: int)
signal context_changed(context: int)
signal settings_changed(settings: MobileInputSettings)
signal left_handed_layout_requested(enabled: bool)
signal input_command_rejected(command: MobileInputCommand, reason: String)

@export var router_path: NodePath = NodePath("../MobileInputRouter")
@export var settings_file_path: String = "user://mobile_input_settings.cfg"

var control_mode: int = MobileInputAction.Mode.GUIDED
var context: Context = Context.GAMEPLAY
var settings: MobileInputSettings
var _router: MobileInputRouter
var _registered_controls: Array[Dictionary] = []


func _ready() -> void:
	_router = get_node_or_null(router_path) as MobileInputRouter
	settings = MobileInputSettings.new()
	load_settings()
	_apply_settings_to_controls()
	_refresh_controls()
	if _router != null:
		_router.set_gameplay_input_enabled(context == Context.GAMEPLAY)


func register_control(control: Control, mode: int) -> Error:
	if control == null or not is_instance_valid(control):
		return ERR_INVALID_PARAMETER
	if mode < MobileInputAction.Mode.GUIDED or mode > MobileInputAction.Mode.FREE_HAND:
		return ERR_INVALID_PARAMETER
	for entry: Dictionary in _registered_controls:
		if entry.control == control:
			return ERR_ALREADY_EXISTS
	if not control.has_signal("command_emitted"):
		return ERR_INVALID_PARAMETER
	var original_mouse_filter: int = control.mouse_filter
	var original_profile: Resource
	if control is FreeHandGestureRecognizer:
		original_profile = (control as FreeHandGestureRecognizer).gesture_profile
	elif control is TapPressGestureRecognizer:
		original_profile = (control as TapPressGestureRecognizer).gesture_profile
	var callback := Callable(self, "_on_command_emitted").bind(mode)
	control.connect("command_emitted", callback)
	_registered_controls.append({
		"control": control,
		"mode": mode,
		"original_mouse_filter": original_mouse_filter,
		"original_profile": original_profile,
		"callback": callback,
	})
	_apply_settings_to_control(control)
	_refresh_controls()
	return OK


func unregister_control(control: Control) -> void:
	if control == null:
		return
	_cancel_control(control)
	for index: int in range(_registered_controls.size() - 1, -1, -1):
		var entry: Dictionary = _registered_controls[index]
		if entry.control == control:
			if is_instance_valid(control) and control.is_connected("command_emitted", entry.callback):
				control.disconnect("command_emitted", entry.callback)
			if is_instance_valid(control):
				control.mouse_filter = Control.MOUSE_FILTER_IGNORE
				control.visible = false
				control.set_process(false)
				control.set_process_input(false)
			_registered_controls.remove_at(index)
			break


func set_control_mode(mode: int) -> Error:
	if mode < MobileInputAction.Mode.GUIDED or mode > MobileInputAction.Mode.FREE_HAND:
		return ERR_INVALID_PARAMETER
	if control_mode == mode:
		return OK
	_cancel_all_controls()
	if _router != null:
		_router.set_gameplay_input_enabled(false)
	control_mode = mode
	_refresh_controls()
	if _router != null:
		_router.set_gameplay_input_enabled(context == Context.GAMEPLAY)
	control_mode_changed.emit(control_mode)
	return OK


func set_context(next_context: int) -> Error:
	if next_context < Context.GAMEPLAY or next_context > Context.CUTSCENE:
		return ERR_INVALID_PARAMETER
	if context == next_context:
		return OK
	_cancel_all_controls()
	if _router != null:
		_router.set_gameplay_input_enabled(false)
	context = next_context
	_refresh_controls()
	if _router != null:
		_router.set_gameplay_input_enabled(context == Context.GAMEPLAY)
	context_changed.emit(context)
	return OK


func update_settings(next_settings: MobileInputSettings) -> Error:
	if next_settings == null:
		return ERR_INVALID_PARAMETER
	if not next_settings.validate().is_empty():
		return ERR_INVALID_DATA
	settings = next_settings.duplicate(true) as MobileInputSettings
	_apply_settings_to_controls()
	settings_changed.emit(settings)
	left_handed_layout_requested.emit(settings.joystick_side == MobileInputSettings.JoystickSide.LEFT)
	return OK


func save_settings() -> Error:
	if settings == null or not settings.validate().is_empty():
		return ERR_INVALID_DATA
	var config := ConfigFile.new()
	config.set_value("input", "joystick_side", settings.joystick_side)
	config.set_value("input", "joystick_scale", settings.joystick_scale)
	config.set_value("input", "joystick_deadzone", settings.joystick_deadzone)
	config.set_value("input", "gesture_sensitivity", settings.gesture_sensitivity)
	config.set_value("input", "long_press_seconds", settings.long_press_seconds)
	config.set_value("input", "multi_tap_window_seconds", settings.multi_tap_window_seconds)
	config.set_value("input", "high_contrast_controls", settings.high_contrast_controls)
	return config.save(settings_file_path)


func load_settings() -> Error:
	var config := ConfigFile.new()
	var load_error := config.load(settings_file_path)
	if load_error != OK:
		return load_error
	var candidate := MobileInputSettings.new()
	candidate.joystick_side = int(config.get_value("input", "joystick_side", candidate.joystick_side))
	candidate.joystick_scale = float(config.get_value("input", "joystick_scale", candidate.joystick_scale))
	candidate.joystick_deadzone = float(config.get_value("input", "joystick_deadzone", candidate.joystick_deadzone))
	candidate.gesture_sensitivity = float(config.get_value("input", "gesture_sensitivity", candidate.gesture_sensitivity))
	candidate.long_press_seconds = float(config.get_value("input", "long_press_seconds", candidate.long_press_seconds))
	candidate.multi_tap_window_seconds = float(config.get_value("input", "multi_tap_window_seconds", candidate.multi_tap_window_seconds))
	candidate.high_contrast_controls = bool(config.get_value("input", "high_contrast_controls", candidate.high_contrast_controls))
	if not candidate.validate().is_empty():
		return ERR_INVALID_DATA
	settings = candidate
	_apply_settings_to_controls()
	settings_changed.emit(settings)
	return OK


func get_active_context() -> int:
	return context


func _on_command_emitted(command: MobileInputCommand, registered_mode: int) -> void:
	if command == null:
		return
	if context != Context.GAMEPLAY:
		input_command_rejected.emit(command, "Gameplay context is suppressed.")
		return
	if registered_mode != control_mode or command.mode != control_mode:
		input_command_rejected.emit(command, "Command does not belong to the active control mode.")
		return
	if _router == null:
		input_command_rejected.emit(command, "MobileInputRouter is unavailable.")
		return
	var result := _router.route_command(command)
	if result != OK:
		input_command_rejected.emit(command, _router.get_last_rejection())


func _cancel_all_controls() -> void:
	for entry: Dictionary in _registered_controls:
		var control := entry.control as Control
		if is_instance_valid(control):
			_cancel_control(control)


func _cancel_control(control: Control) -> void:
	if control.has_method("cancel_active_pointer"):
		control.call("cancel_active_pointer")


func _refresh_controls() -> void:
	for entry: Dictionary in _registered_controls:
		var control := entry.control as Control
		if not is_instance_valid(control):
			continue
		var enabled := context == Context.GAMEPLAY and int(entry.mode) == control_mode
		control.visible = enabled
		control.mouse_filter = int(entry.original_mouse_filter) if enabled else Control.MOUSE_FILTER_IGNORE
		control.set_process(enabled)
		control.set_process_input(enabled)


func _apply_settings_to_controls() -> void:
	for entry: Dictionary in _registered_controls:
		var control := entry.control as Control
		if is_instance_valid(control):
			_apply_settings_to_control(control)
	left_handed_layout_requested.emit(settings.joystick_side == MobileInputSettings.JoystickSide.LEFT)


func _apply_settings_to_control(control: Control) -> void:
	if settings == null:
		return
	if control is VirtualJoystick:
		var joystick := control as VirtualJoystick
		joystick.base_radius = 64.0 * settings.joystick_scale
		joystick.knob_radius = 24.0 * settings.joystick_scale
		joystick.deadzone = settings.joystick_deadzone
		if settings.high_contrast_controls:
			joystick.base_color = Color(0.02, 0.02, 0.02, 0.92)
			joystick.knob_color = Color(1.0, 1.0, 1.0, 1.0)
		else:
			joystick.base_color = Color(0.12, 0.16, 0.22, 0.58)
			joystick.knob_color = Color(0.72, 0.82, 0.96, 0.88)
	elif control is FreeHandGestureRecognizer:
		var recognizer := control as FreeHandGestureRecognizer
		var original_profile := _get_original_profile(control) as FreeHandGestureProfile
		if original_profile != null:
			var profile := original_profile.duplicate(true) as FreeHandGestureProfile
			profile.swipe_threshold_px = clampf(profile.swipe_threshold_px / settings.gesture_sensitivity, 8.0, 256.0)
			profile.drag_activation_threshold_px = clampf(profile.drag_activation_threshold_px / settings.gesture_sensitivity, 4.0, 128.0)
			recognizer.gesture_profile = profile
	elif control is TapPressGestureRecognizer:
		var tap_recognizer := control as TapPressGestureRecognizer
		var original_profile := _get_original_profile(control) as TapPressGestureProfile
		if original_profile != null:
			var profile := original_profile.duplicate(true) as TapPressGestureProfile
			profile.long_press_seconds = settings.long_press_seconds
			profile.multi_tap_window_seconds = settings.multi_tap_window_seconds
			tap_recognizer.gesture_profile = profile


func _get_original_profile(control: Control) -> Resource:
	for entry: Dictionary in _registered_controls:
		if entry.control == control:
			return entry.original_profile as Resource
	return null
