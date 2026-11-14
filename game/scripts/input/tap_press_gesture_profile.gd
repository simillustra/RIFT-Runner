extends Resource
class_name TapPressGestureProfile
## Configurable tap/press grammar. Defaults are provisional and should be playtested.

@export_range(0.05, 1.0, 0.01) var multi_tap_window_seconds: float = 0.28
@export_range(0.05, 1.0, 0.01) var long_press_seconds: float = 0.55
@export_range(2.0, 64.0, 1.0) var movement_tolerance_px: float = 18.0
@export var tap_action: int = MobileInputAction.Action.BASIC_ATTACK
@export var double_tap_action: int = MobileInputAction.Action.DODGE
@export var triple_tap_action: int = MobileInputAction.Action.INTERACT
@export var long_press_action: int = MobileInputAction.Action.CANCEL
@export var enable_hard_press: bool = false
@export_range(0.0, 1.0, 0.01) var hard_press_pressure_threshold: float = 0.75
@export var hard_press_action: int = MobileInputAction.Action.PAUSE


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if not is_finite(multi_tap_window_seconds) or multi_tap_window_seconds <= 0.0:
		errors.append("multi_tap_window_seconds must be finite and greater than zero.")
	if not is_finite(long_press_seconds) or long_press_seconds <= 0.0:
		errors.append("long_press_seconds must be finite and greater than zero.")
	if not is_finite(movement_tolerance_px) or movement_tolerance_px <= 0.0:
		errors.append("movement_tolerance_px must be finite and greater than zero.")
	if not is_finite(hard_press_pressure_threshold) or hard_press_pressure_threshold < 0.0 or hard_press_pressure_threshold > 1.0:
		errors.append("hard_press_pressure_threshold must be between zero and one.")
	for action in [tap_action, double_tap_action, triple_tap_action, long_press_action, hard_press_action]:
		if action <= MobileInputAction.Action.MOVE or action > MobileInputAction.Action.CANCEL:
			errors.append("tap/press bindings must use supported non-MOVE semantic actions.")
			break
	return errors
