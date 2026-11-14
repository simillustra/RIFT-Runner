extends SceneTree
## RR-004 D2 AnimationProfile resource and validation tests.

var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var profile := load("res://tests/fixtures/animation_profiles/valid_animation_profile.tres") as AnimationProfile
	_check(profile != null, "AnimationProfile fixture loads as the typed resource")
	if profile == null:
		quit(1)
		return

	_check(profile.validate().is_empty(), "valid profile passes configuration validation")
	_check(profile.profile_id == &"test_default", "profile exposes stable profile ID")
	_check(profile.get_clip(&"move") == &"run", "semantic state resolves to configured clip")
	_check(profile.get_clip(&"start") == profile.fallback_clip, "unmapped optional state resolves to fallback")
	_check(is_equal_approx(profile.get_playback_rate(0.0), profile.playback_rate_min), "playback rate clamps at minimum")
	_check(is_equal_approx(profile.get_playback_rate(100.0), profile.playback_rate_max), "playback rate clamps at maximum")

	var clip_names := PackedStringArray(["idle", "run", "jump_rise", "jump_fall", "land"])
	_check(profile.validate(clip_names).is_empty(), "profile validates against available clip names")

	var missing_required := profile.duplicate(true) as AnimationProfile
	missing_required.state_clips.erase(&"move")
	_check(_contains_error(missing_required.validate(), "Required state 'move'"), "missing required mapping is rejected")

	var missing_clip := profile.duplicate(true) as AnimationProfile
	missing_clip.state_clips[&"move"] = &"run_missing"
	_check(_contains_error(missing_clip.validate(clip_names), "missing clip 'run_missing'"), "missing referenced clip is rejected")

	var unknown_state := profile.duplicate(true) as AnimationProfile
	unknown_state.state_clips[&"teleport"] = &"teleport"
	_check(_contains_error(unknown_state.validate(), "unknown state 'teleport'"), "unknown semantic state is rejected")

	var invalid_thresholds := profile.duplicate(true) as AnimationProfile
	invalid_thresholds.idle_enter_speed = 0.5
	invalid_thresholds.idle_exit_speed = 0.2
	_check(_contains_error(invalid_thresholds.validate(), "idle_enter_speed"), "invalid idle hysteresis thresholds are rejected")

	var invalid_rates := profile.duplicate(true) as AnimationProfile
	invalid_rates.playback_rate_min = 1.5
	invalid_rates.playback_rate_max = 1.0
	_check(_contains_error(invalid_rates.validate(), "playback_rate_max"), "invalid playback-rate range is rejected")

	if failures == 0:
		print("RR-004 D2 AnimationProfile tests: PASS")
		quit(0)
	else:
		push_error("RR-004 D2 AnimationProfile tests: %d failure(s)" % failures)
		quit(1)


func _contains_error(errors: PackedStringArray, expected_fragment: String) -> bool:
	for error_message: String in errors:
		if error_message.contains(expected_fragment):
			return true
	return false


func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		failures += 1
		push_error("FAIL: %s" % description)
