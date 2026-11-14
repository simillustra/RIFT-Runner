extends SceneTree
## RR-004 D6 hero-specific AnimationProfile resource tests.

const PROFILE_PATHS: Array[String] = [
	"res://game/resources/animation_profiles/vanguard_profile.tres",
	"res://game/resources/animation_profiles/phantom_profile.tres",
	"res://game/resources/animation_profiles/cipher_profile.tres",
]
const EXPECTED_IDS: Array[StringName] = [&"vanguard", &"phantom", &"cipher"]

var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var loaded_profiles: Array[AnimationProfile] = []
	for index: int in range(PROFILE_PATHS.size()):
		var profile := load(PROFILE_PATHS[index]) as AnimationProfile
		_check(profile != null, "%s hero profile loads as AnimationProfile" % String(EXPECTED_IDS[index]))
		if profile == null:
			continue
		loaded_profiles.append(profile)
		_check(profile.profile_id == EXPECTED_IDS[index], "%s profile exposes its stable ID" % String(EXPECTED_IDS[index]))
		_check(profile.rig_profile_id != &"", "%s profile declares a rig contract ID" % String(EXPECTED_IDS[index]))
		_check(profile.validate().is_empty(), "%s profile passes configuration validation" % String(EXPECTED_IDS[index]))
		_check(profile.get_clip(&"idle") == &"idle", "%s maps idle to the shared semantic clip contract" % String(EXPECTED_IDS[index]))
		_check(profile.get_clip(&"move") == &"move", "%s maps locomotion to the shared semantic clip contract" % String(EXPECTED_IDS[index]))
		_check(profile.get_clip(&"rising") == &"rising", "%s maps rising to the shared semantic clip contract" % String(EXPECTED_IDS[index]))
		_check(profile.get_clip(&"falling") == &"falling", "%s maps falling to the shared semantic clip contract" % String(EXPECTED_IDS[index]))
		_check(profile.get_clip(&"landing") == &"landing", "%s maps landing to the shared semantic clip contract" % String(EXPECTED_IDS[index]))

	_check(loaded_profiles.size() == 3, "all three hero profiles load")
	if loaded_profiles.size() == 3:
		var profile_ids: Array[StringName] = []
		var rig_ids: Array[StringName] = []
		for profile: AnimationProfile in loaded_profiles:
			profile_ids.append(profile.profile_id)
			rig_ids.append(profile.rig_profile_id)
		_check(profile_ids.size() == 3 and not profile_ids.has(&""), "all hero profile IDs are populated")
		_check(rig_ids[0] != rig_ids[1] and rig_ids[0] != rig_ids[2] and rig_ids[1] != rig_ids[2], "each hero has a distinct rig profile contract")
		_check(loaded_profiles[0].reference_move_speed != loaded_profiles[1].reference_move_speed, "Vanguard and Phantom locomotion tuning is independently configurable")
		_check(loaded_profiles[1].reference_move_speed != loaded_profiles[2].reference_move_speed, "Phantom and Cipher locomotion tuning is independently configurable")

	if failures == 0:
		print("RR-004 D6 hero AnimationProfile tests: PASS")
		quit(0)
	else:
		push_error("RR-004 D6 hero AnimationProfile tests: %d failure(s)" % failures)
		quit(1)


func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		failures += 1
		push_error("FAIL: %s" % description)
