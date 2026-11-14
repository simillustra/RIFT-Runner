extends SceneTree
## RR-004 D7 automated asset-contract checks.
## Empty fixture clips prove resource/graph wiring only, not visual animation quality.

const PROFILE_PATHS: Array[String] = [
	"res://game/resources/animation_profiles/vanguard_profile.tres",
	"res://game/resources/animation_profiles/phantom_profile.tres",
	"res://game/resources/animation_profiles/cipher_profile.tres",
]
const CLIP_NAMES: Array[StringName] = [
	&"idle",
	&"move",
	&"rising",
	&"falling",
	&"landing",
]

var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var animation_player := AnimationPlayer.new()
	var library := AnimationLibrary.new()
	for clip_name: StringName in CLIP_NAMES:
		var clip := Animation.new()
		clip.length = 0.5
		var error := library.add_animation(clip_name, clip)
		_check(error == OK, "fixture animation '%s' is registered" % String(clip_name))
	animation_player.add_animation_library(&"", library)
	var available_clips := animation_player.get_animation_list()

	for profile_path: String in PROFILE_PATHS:
		var profile := load(profile_path) as AnimationProfile
		_check(profile != null, "%s loads as AnimationProfile" % profile_path)
		if profile == null:
			continue

		var configuration_errors := profile.validate(available_clips)
		_check(configuration_errors.is_empty(), "%s references clips present in its AnimationPlayer library" % String(profile.profile_id))
		var graph := CharacterAnimationGraph.create_state_machine(profile)
		var graph_errors := CharacterAnimationGraph.validate_state_machine(graph)
		_check(graph_errors.is_empty(), "%s produces a valid shared AnimationTree graph" % String(profile.profile_id))
		_check(_graph_clips_exist(graph, animation_player), "%s graph nodes resolve to available animation clips or profile fallback" % String(profile.profile_id))

	animation_player.free()
	if failures == 0:
		print("RR-004 D7 animation asset-contract tests: PASS")
		quit(0)
	else:
		push_error("RR-004 D7 animation asset-contract tests: %d failure(s)" % failures)
		quit(1)


func _graph_clips_exist(machine: AnimationNodeStateMachine, player: AnimationPlayer) -> bool:
	if machine == null:
		return false
	for state_name: StringName in machine.get_node_list():
		var node := machine.get_node(state_name)
		if node is AnimationNodeAnimation:
			if not player.has_animation((node as AnimationNodeAnimation).animation):
				return false
		elif node is AnimationNodeBlendSpace2D:
			var blend_space := node as AnimationNodeBlendSpace2D
			for point_index: int in range(blend_space.get_blend_point_count()):
				var point_node := blend_space.get_blend_point_node(point_index) as AnimationNodeAnimation
				if point_node == null or not player.has_animation(point_node.animation):
					return false
	return true


func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		failures += 1
		push_error("FAIL: %s" % description)
