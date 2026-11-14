extends Resource
class_name AnimationProfile
## Data-only mapping from semantic character animation states to clip identifiers.
## The profile never owns playback or gameplay state.

const KNOWN_STATES: Array[StringName] = [
	&"idle",
	&"start",
	&"move",
	&"stop",
	&"jump_start",
	&"rising",
	&"falling",
	&"landing",
	&"hit_react",
	&"sprint",
]

@export var profile_id: StringName = &""
@export var rig_profile_id: StringName = &""
@export var state_clips: Dictionary = {
	&"idle": &"idle",
	&"move": &"move",
	&"rising": &"rising",
	&"falling": &"falling",
	&"landing": &"landing",
}
@export var required_states: Array[StringName] = [
	&"idle",
	&"move",
	&"rising",
	&"falling",
	&"landing",
]
@export var fallback_clip: StringName = &"idle"

@export_group("Locomotion Tuning")
@export_range(0.0, 5.0, 0.01) var idle_enter_speed: float = 0.12
@export_range(0.0, 5.0, 0.01) var idle_exit_speed: float = 0.20
@export_range(0.1, 20.0, 0.1) var reference_move_speed: float = 5.0
@export_range(0.1, 5.0, 0.05) var playback_rate_min: float = 0.65
@export_range(0.1, 5.0, 0.05) var playback_rate_max: float = 1.50


## Returns all profile configuration errors. If available_clips is supplied,
## every mapped clip (including fallback) must exist in that clip-name list.
func validate(available_clips: PackedStringArray = PackedStringArray()) -> PackedStringArray:
	var errors := PackedStringArray()

	if profile_id == &"":
		errors.append("profile_id is required.")

	if fallback_clip == &"":
		errors.append("fallback_clip is required.")
	elif not available_clips.is_empty() and not available_clips.has(String(fallback_clip)):
		errors.append("fallback_clip '%s' is not present in the supplied animation library." % String(fallback_clip))

	for state_name: StringName in required_states:
		if not KNOWN_STATES.has(state_name):
			errors.append("required_states contains unknown state '%s'." % String(state_name))
			continue
		if not state_clips.has(state_name) or StringName(state_clips[state_name]) == &"":
			errors.append("Required state '%s' has no clip mapping." % String(state_name))

	for state_variant: Variant in state_clips.keys():
		var state_name := StringName(state_variant)
		if not KNOWN_STATES.has(state_name):
			errors.append("state_clips contains unknown state '%s'." % String(state_name))
			continue
		var clip_name := StringName(state_clips[state_variant])
		if clip_name == &"":
			errors.append("State '%s' maps to an empty clip identifier." % String(state_name))
		elif not available_clips.is_empty() and not available_clips.has(String(clip_name)):
			errors.append("State '%s' references missing clip '%s'." % [String(state_name), String(clip_name)])

	if idle_enter_speed > idle_exit_speed:
		errors.append("idle_enter_speed must be less than or equal to idle_exit_speed.")
	if reference_move_speed <= 0.0:
		errors.append("reference_move_speed must be greater than zero.")
	if playback_rate_min <= 0.0:
		errors.append("playback_rate_min must be greater than zero.")
	if playback_rate_max < playback_rate_min:
		errors.append("playback_rate_max must be greater than or equal to playback_rate_min.")

	return errors


## Returns the configured clip or the fallback clip for an optional/missing state.
func get_clip(state_name: StringName) -> StringName:
	if state_clips.has(state_name):
		var clip_name := StringName(state_clips[state_name])
		if clip_name != &"":
			return clip_name
	return fallback_clip


## Converts movement speed to a bounded playback rate using profile tuning.
func get_playback_rate(planar_speed: float) -> float:
	if reference_move_speed <= 0.0:
		return playback_rate_min
	var normalized_speed := maxf(planar_speed, 0.0) / reference_move_speed
	return clampf(normalized_speed, playback_rate_min, playback_rate_max)
