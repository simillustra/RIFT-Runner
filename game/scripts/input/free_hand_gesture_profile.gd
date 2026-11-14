extends Resource
class_name FreeHandGestureProfile
## Configurable free-hand recognizer grammar; default bindings are provisional.

enum RecognitionMode { DIRECTIONAL_SWIPE, CONTINUOUS_DRAG }

@export var recognition_mode: RecognitionMode = RecognitionMode.DIRECTIONAL_SWIPE
@export_range(8.0, 256.0, 1.0) var swipe_threshold_px: float = 56.0
@export_range(4.0, 128.0, 1.0) var drag_activation_threshold_px: float = 12.0
@export_range(16.0, 512.0, 1.0) var drag_full_scale_distance_px: float = 120.0
@export_range(0.0, 64.0, 1.0) var drag_deadzone_px: float = 6.0
@export var left_action: int = MobileInputAction.Action.LANE_LEFT
@export var right_action: int = MobileInputAction.Action.LANE_RIGHT
@export var up_action: int = MobileInputAction.Action.JUMP
@export var down_action: int = MobileInputAction.Action.DODGE


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if recognition_mode < RecognitionMode.DIRECTIONAL_SWIPE or recognition_mode > RecognitionMode.CONTINUOUS_DRAG:
		errors.append("recognition_mode is invalid.")
	if not is_finite(swipe_threshold_px) or swipe_threshold_px <= 0.0:
		errors.append("swipe_threshold_px must be finite and greater than zero.")
	if not is_finite(drag_activation_threshold_px) or drag_activation_threshold_px <= 0.0:
		errors.append("drag_activation_threshold_px must be finite and greater than zero.")
	if not is_finite(drag_full_scale_distance_px) or not is_finite(drag_deadzone_px) or drag_full_scale_distance_px <= drag_deadzone_px:
		errors.append("drag_full_scale_distance_px must be finite and exceed drag_deadzone_px.")
	if drag_deadzone_px < 0.0:
		errors.append("drag_deadzone_px cannot be negative.")
	for action in [left_action, right_action, up_action, down_action]:
		if action < MobileInputAction.Action.JUMP or action > MobileInputAction.Action.PAUSE or action == MobileInputAction.Action.ABILITY_PRIMARY or action == MobileInputAction.Action.ABILITY_SECONDARY:
			errors.append("direction bindings must use supported non-MOVE semantic actions.")
			break
	return errors


func action_for_direction(direction: Vector2i) -> int:
	if absi(direction.x) >= absi(direction.y):
		return right_action if direction.x > 0 else left_action
	return down_action if direction.y > 0 else up_action
