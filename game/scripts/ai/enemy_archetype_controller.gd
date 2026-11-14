extends Node
class_name EnemyArchetypeController
## Applies a Resource-defined archetype to existing AI and chase controllers.
signal archetype_applied(archetype_id: StringName)
@export var profile: EnemyArchetypeProfile
@export var enemy_ai_controller_path: NodePath = NodePath("../EnemyAIController")
@export var chase_controller_path: NodePath = NodePath("../EnemyChaseController")
var _ai: EnemyAIController
var _chase: EnemyChaseController

func _ready() -> void:
	_ai = get_node_or_null(enemy_ai_controller_path) as EnemyAIController
	_chase = get_node_or_null(chase_controller_path) as EnemyChaseController
	if profile != null:
		apply_profile(profile)

func apply_profile(next_profile: EnemyArchetypeProfile) -> Error:
	if next_profile == null or not next_profile.validate().is_empty():
		return ERR_INVALID_DATA
	if _ai == null: _ai = get_node_or_null(enemy_ai_controller_path) as EnemyAIController
	if _chase == null: _chase = get_node_or_null(chase_controller_path) as EnemyChaseController
	if _ai == null or _chase == null:
		return ERR_UNCONFIGURED
	profile = next_profile
	_ai.detection_range = profile.detection_range
	_ai.attack_range = profile.attack_range
	_ai.lose_target_range = profile.lose_target_range
	_ai.retreat_enabled = profile.can_retreat
	_chase.move_speed = profile.move_speed
	_chase.preferred_attack_distance = profile.preferred_attack_distance
	_chase.acceleration = profile.acceleration
	_chase.turn_speed = profile.turn_speed
	_chase.engagement_policy = profile.engagement_policy
	archetype_applied.emit(profile.archetype_id)
	return OK
