extends SceneTree
## RR-004 D7 production rig validator contract tests.
const PROFILE_PATH := "res://game/resources/animation_profiles/vanguard_profile.tres"
const REQUIRED_CLIPS: Array[StringName] = [&"idle", &"move", &"rising", &"falling", &"landing"]
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var rig_root := Node3D.new()
	rig_root.name = "HeroRig"
	var skeleton := Skeleton3D.new()
	skeleton.name = "Skeleton3D"
	skeleton.add_bone("Root")
	skeleton.add_bone("Spine")
	skeleton.set_bone_parent(1, 0)
	rig_root.add_child(skeleton)
	var animation_player := AnimationPlayer.new()
	animation_player.name = "AnimationPlayer"
	animation_player.root_node = NodePath("..")
	rig_root.add_child(animation_player)
	root.add_child(rig_root)
	await process_frame
	var library := AnimationLibrary.new()
	for clip_name: StringName in REQUIRED_CLIPS:
		var animation := Animation.new()
		animation.length = 1.0
		var track_index := animation.add_track(Animation.TYPE_POSITION_3D)
		animation.track_set_path(track_index, NodePath("Skeleton3D:Spine"))
		animation.position_track_insert_key(track_index, 0.0, Vector3.ZERO)
		_check(library.add_animation(clip_name, animation) == OK, "fixture clip '%s' registers" % String(clip_name))
	animation_player.add_animation_library(&"", library)
	var profile := load(PROFILE_PATH) as AnimationProfile
	_check(profile != null, "Vanguard AnimationProfile loads")
	if profile == null:
		quit(1)
		return
	var errors := AnimationRigValidator.validate_rig(rig_root, animation_player, skeleton, profile, &"humanoid_vanguard")
	_check(errors.is_empty(), "valid Skeleton3D bone tracks satisfy the rig contract")
	var mismatch := AnimationRigValidator.validate_rig(rig_root, animation_player, skeleton, profile, &"humanoid_phantom")
	_check(_contains_error(mismatch, "Rig profile mismatch"), "validator rejects an incompatible hero rig profile")
	var idle := animation_player.get_animation(&"idle")
	idle.track_set_path(0, NodePath("Skeleton3D:MissingBone"))
	var missing_bone := AnimationRigValidator.validate_rig(rig_root, animation_player, skeleton, profile)
	_check(_contains_error(missing_bone, "missing bone 'MissingBone'"), "validator identifies tracks targeting missing bones")
	idle.track_set_path(0, NodePath("MissingSkeleton:Spine"))
	var missing_node := AnimationRigValidator.validate_rig(rig_root, animation_player, skeleton, profile)
	_check(_contains_error(missing_node, "cannot resolve node path"), "validator identifies tracks targeting missing nodes")
	idle.track_set_path(0, NodePath("Skeleton3D:Spine"))
	var invalid_root := AnimationPlayer.new()
	invalid_root.name = "InvalidRootAnimationPlayer"
	invalid_root.root_node = NodePath("MissingRoot")
	rig_root.add_child(invalid_root)
	var root_errors := AnimationRigValidator.validate_rig(rig_root, invalid_root, skeleton, profile)
	_check(_contains_error(root_errors, "root_node"), "validator rejects an unresolved AnimationPlayer root")
	rig_root.queue_free()
	await process_frame
	if failures == 0:
		print("RR-004 D7 production rig validator: PASS")
		quit(0)
	else:
		push_error("RR-004 D7 production rig validator: %d failure(s)" % failures)
		quit(1)

func _contains_error(errors: PackedStringArray, fragment: String) -> bool:
	for error_text: String in errors:
		if error_text.contains(fragment):
			return true
	return false

func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		failures += 1
		push_error("FAIL: %s" % description)
