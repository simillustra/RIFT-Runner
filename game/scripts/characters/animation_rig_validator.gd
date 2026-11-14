extends RefCounted
class_name AnimationRigValidator
## Validates an imported hero rig against its AnimationProfile and AnimationPlayer.
## Asset-contract validation only; it does not claim visual quality.

static func validate_rig(rig_root: Node, animation_player: AnimationPlayer, skeleton: Skeleton3D, profile: AnimationProfile, expected_rig_profile_id: StringName = &"") -> PackedStringArray:
	var errors := PackedStringArray()
	if rig_root == null or not is_instance_valid(rig_root):
		errors.append("A valid rig_root node is required.")
		return errors
	if animation_player == null or not is_instance_valid(animation_player):
		errors.append("A valid AnimationPlayer is required.")
		return errors
	if skeleton == null or not is_instance_valid(skeleton):
		errors.append("A valid Skeleton3D is required.")
		return errors
	if not rig_root.is_ancestor_of(animation_player) and rig_root != animation_player:
		errors.append("AnimationPlayer must be inside the supplied rig_root.")
	if not rig_root.is_ancestor_of(skeleton) and rig_root != skeleton:
		errors.append("Skeleton3D must be inside the supplied rig_root.")
	if skeleton.get_bone_count() == 0:
		errors.append("Skeleton3D contains no bones.")
	if profile == null:
		errors.append("A typed AnimationProfile is required.")
		return errors
	if profile.rig_profile_id == &"":
		errors.append("AnimationProfile.rig_profile_id must be assigned.")
	elif expected_rig_profile_id != &"" and profile.rig_profile_id != expected_rig_profile_id:
		errors.append("Rig profile mismatch: expected '%s', received '%s'." % [String(expected_rig_profile_id), String(profile.rig_profile_id)])
	var animation_root := animation_player.get_node_or_null(animation_player.root_node)
	if animation_root == null:
		errors.append("AnimationPlayer.root_node '%s' does not resolve." % String(animation_player.root_node))
		return errors
	var clip_names := animation_player.get_animation_list()
	for profile_error: String in profile.validate(clip_names):
		errors.append("Profile: %s" % profile_error)
	var clips_to_check: Array[StringName] = []
	for clip_variant: Variant in profile.state_clips.values():
		var clip_name := StringName(clip_variant)
		if clip_name != &"" and not clips_to_check.has(clip_name):
			clips_to_check.append(clip_name)
	if profile.fallback_clip != &"" and not clips_to_check.has(profile.fallback_clip):
		clips_to_check.append(profile.fallback_clip)
	for clip_name: StringName in clips_to_check:
		if not animation_player.has_animation(clip_name):
			continue
		var animation := animation_player.get_animation(clip_name)
		if animation == null:
			errors.append("Animation '%s' could not be loaded." % String(clip_name))
			continue
		if animation.length <= 0.0:
			errors.append("Animation '%s' has zero duration." % String(clip_name))
		for track_index: int in range(animation.get_track_count()):
			_validate_track(animation_root, skeleton, animation, track_index, clip_name, errors)
	return errors


static func _validate_track(animation_root: Node, expected_skeleton: Skeleton3D, animation: Animation, track_index: int, clip_name: StringName, errors: PackedStringArray) -> void:
	var track_path := animation.track_get_path(track_index)
	var path_parts := String(track_path).split(":")
	var node_path := NodePath(path_parts[0])
	var target_node := animation_root if path_parts[0].is_empty() or path_parts[0] == "." else animation_root.get_node_or_null(node_path)
	if target_node == null:
		errors.append("Animation '%s' track %d cannot resolve node path '%s'." % [String(clip_name), track_index, String(track_path)])
		return
	var track_type := animation.track_get_type(track_index)
	var is_skeleton_track := track_type == Animation.TYPE_POSITION_3D or track_type == Animation.TYPE_ROTATION_3D or track_type == Animation.TYPE_SCALE_3D
	if not is_skeleton_track:
		return
	if target_node != expected_skeleton:
		errors.append("Animation '%s' track %d targets a node other than the configured rig Skeleton3D." % [String(clip_name), track_index])
		return
	if path_parts.size() < 2 or path_parts[1].is_empty():
		errors.append("Animation '%s' track %d has no bone subname in path '%s'." % [String(clip_name), track_index, String(track_path)])
		return
	if expected_skeleton.find_bone(path_parts[1]) < 0:
		errors.append("Animation '%s' track %d references missing bone '%s'." % [String(clip_name), track_index, path_parts[1]])
