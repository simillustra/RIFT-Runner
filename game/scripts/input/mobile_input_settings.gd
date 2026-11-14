extends Resource
class_name MobileInputSettings
## Player-facing control and accessibility preferences for RR-006.

enum JoystickSide { LEFT, RIGHT }

@export var joystick_side: JoystickSide = JoystickSide.RIGHT
@export_range(0.75, 1.75, 0.05) var joystick_scale: float = 1.0
@export_range(0.0, 0.35, 0.01) var joystick_deadzone: float = 0.12
@export_range(0.5, 1.75, 0.05) var gesture_sensitivity: float = 1.0
@export_range(0.15, 0.8, 0.01) var long_press_seconds: float = 0.55
@export_range(0.15, 0.6, 0.01) var multi_tap_window_seconds: float = 0.28
@export var high_contrast_controls: bool = false


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if joystick_side < JoystickSide.LEFT or joystick_side > JoystickSide.RIGHT:
		errors.append("joystick_side is invalid.")
	if not is_finite(joystick_scale) or joystick_scale < 0.75 or joystick_scale > 1.75:
		errors.append("joystick_scale must be between 0.75 and 1.75.")
	if not is_finite(joystick_deadzone) or joystick_deadzone < 0.0 or joystick_deadzone > 0.35:
		errors.append("joystick_deadzone must be between 0 and 0.35.")
	if not is_finite(gesture_sensitivity) or gesture_sensitivity < 0.5 or gesture_sensitivity > 1.75:
		errors.append("gesture_sensitivity must be between 0.5 and 1.75.")
	if not is_finite(long_press_seconds) or long_press_seconds < 0.15 or long_press_seconds > 0.8:
		errors.append("long_press_seconds must be between 0.15 and 0.8.")
	if not is_finite(multi_tap_window_seconds) or multi_tap_window_seconds < 0.15 or multi_tap_window_seconds > 0.6:
		errors.append("multi_tap_window_seconds must be between 0.15 and 0.6.")
	return errors
