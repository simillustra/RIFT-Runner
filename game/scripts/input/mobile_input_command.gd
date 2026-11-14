extends RefCounted
class_name MobileInputCommand
## Device-neutral input event. It contains intent only and never mutates gameplay.

var action: int = MobileInputAction.Action.MOVE
var phase: int = MobileInputAction.Phase.PERFORMED
var mode: int = MobileInputAction.Mode.GUIDED
var vector: Vector2 = Vector2.ZERO
var strength: float = 1.0
var ability_id: StringName = &""
var source_id: StringName = &"unknown"
var sequence_id: int = 0


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if action < MobileInputAction.Action.MOVE or action > MobileInputAction.Action.CANCEL:
		errors.append("action is outside the MobileInputAction.Action enum.")
	if phase < MobileInputAction.Phase.STARTED or phase > MobileInputAction.Phase.CANCELED:
		errors.append("phase is outside the MobileInputAction.Phase enum.")
	if mode < MobileInputAction.Mode.GUIDED or mode > MobileInputAction.Mode.FREE_HAND:
		errors.append("mode is outside the MobileInputAction.Mode enum.")
	if not is_finite(strength) or strength < 0.0 or strength > 1.0:
		errors.append("strength must be finite and between 0 and 1.")
	if not is_finite(vector.x) or not is_finite(vector.y):
		errors.append("vector components must be finite.")
	if action == MobileInputAction.Action.MOVE and vector.length() > 1.001:
		errors.append("MOVE vector must be normalized to a maximum length of 1.")
	if action != MobileInputAction.Action.MOVE and not vector.is_zero_approx():
		errors.append("Only MOVE commands may carry a movement vector.")
	if (action == MobileInputAction.Action.ABILITY_PRIMARY or action == MobileInputAction.Action.ABILITY_SECONDARY) and ability_id == &"":
		errors.append("Ability actions require a non-empty ability_id.")
	if sequence_id < 0:
		errors.append("sequence_id cannot be negative.")
	if source_id == &"":
		errors.append("source_id cannot be empty.")
	return errors


func is_valid() -> bool:
	return validate().is_empty()
