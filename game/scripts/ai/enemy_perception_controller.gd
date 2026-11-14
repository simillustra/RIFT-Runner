extends Node
class_name EnemyPerceptionController
## Local deterministic target scanner. No network or remote inference dependency.
signal target_acquired(target: Node3D)
signal target_lost(previous_target: Node3D)
@export var enemy_ai_controller_path: NodePath = NodePath("../EnemyAIController")
@export var candidate_group: StringName = &"player"
@export_range(1.0, 200.0, 0.1) var perception_range: float = 18.0
@export_range(0.02, 2.0, 0.01) var scan_interval_seconds: float = 0.15
@export var require_line_of_sight: bool = false
@export_flags_3d_physics var line_of_sight_collision_mask: int = 1
@export_range(0.0, 5.0, 0.05) var eye_height: float = 1.4
@export_range(0.0, 5.0, 0.05) var target_aim_height: float = 1.0
var _ai: EnemyAIController
var _scan_remaining: float = 0.0
var _actor: Node3D

func _ready() -> void:
	_actor = get_parent() as Node3D
	_ai = get_node_or_null(enemy_ai_controller_path) as EnemyAIController
	if _ai == null: push_warning("EnemyPerceptionController requires an EnemyAIController at '%s'." % enemy_ai_controller_path)
	if candidate_group == &"": push_warning("EnemyPerceptionController candidate_group must not be empty.")

func _physics_process(delta: float) -> void:
	if delta <= 0.0 or _ai == null or _ai.current_state == EnemyAIController.State.DEAD: return
	_scan_remaining -= delta
	if _scan_remaining > 0.0: return
	_scan_remaining = scan_interval_seconds
	refresh_perception()

func refresh_perception() -> Node3D:
	if _ai == null or _actor == null or _ai.current_state == EnemyAIController.State.DEAD: return null
	var best_target: Node3D
	var best_distance := perception_range
	for candidate_node: Node in get_tree().get_nodes_in_group(candidate_group):
		var candidate := candidate_node as Node3D
		if candidate == null or not is_instance_valid(candidate) or candidate.is_queued_for_deletion(): continue
		if candidate == _actor or _actor.is_ancestor_of(candidate): continue
		if not _is_candidate_alive(candidate): continue
		var distance := _actor.global_position.distance_to(candidate.global_position)
		if distance > perception_range or distance >= best_distance: continue
		if require_line_of_sight and not _has_line_of_sight(candidate): continue
		best_distance = distance
		best_target = candidate
	var previous_target := _ai.target
	if best_target == null:
		if is_instance_valid(previous_target):
			_ai.clear_target()
			target_lost.emit(previous_target)
		return null
	if previous_target != best_target:
		_ai.set_target(best_target)
		target_acquired.emit(best_target)
	return best_target

func _is_candidate_alive(candidate: Node3D) -> bool:
	var health_node := candidate.find_child("HealthComponent", true, false)
	if health_node is HealthComponent:
		return not (health_node as HealthComponent).is_dead
	return true

func _has_line_of_sight(candidate: Node3D) -> bool:
	var world := _actor.get_world_3d()
	if world == null: return false
	var origin := _actor.global_position + Vector3.UP * eye_height
	var destination := candidate.global_position + Vector3.UP * target_aim_height
	var exclusions: Array[RID] = []
	if _actor is CollisionObject3D: exclusions.append((_actor as CollisionObject3D).get_rid())
	var query := PhysicsRayQueryParameters3D.create(origin, destination, line_of_sight_collision_mask, exclusions)
	var hit := world.direct_space_state.intersect_ray(query)
	if hit.is_empty(): return false
	var collider := hit.get("collider") as Node
	return collider == candidate or (collider != null and candidate.is_ancestor_of(collider))
