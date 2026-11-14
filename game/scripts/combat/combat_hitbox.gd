extends Area3D
class_name CombatHitbox
## Physics overlap adapter. Eligible overlaps are submitted to AttackExecutor.try_hit().

signal target_hit(hurtbox: CombatHurtbox, applied_damage: float)
signal target_rejected(hurtbox: CombatHurtbox, reason: String)

@export var attack_executor_path: NodePath = NodePath("../AttackExecutor")
@export var attacker_root_path: NodePath = NodePath("..")
@export var attacker_team_id: StringName = &""

var _executor: AttackExecutor
var _attacker_root: Node


func _ready() -> void:
	monitoring = false
	_attacker_root = get_node_or_null(attacker_root_path)
	_executor = get_node_or_null(attack_executor_path) as AttackExecutor
	if _executor == null:
		push_warning("CombatHitbox requires an AttackExecutor at '%s'." % attack_executor_path)
		return
	_executor.active_window_started.connect(_on_active_window_started)
	_executor.active_window_ended.connect(_on_active_window_ended)
	area_entered.connect(_on_area_entered)


func _exit_tree() -> void:
	if is_instance_valid(_executor):
		if _executor.active_window_started.is_connected(_on_active_window_started):
			_executor.active_window_started.disconnect(_on_active_window_started)
		if _executor.active_window_ended.is_connected(_on_active_window_ended):
			_executor.active_window_ended.disconnect(_on_active_window_ended)


func _on_active_window_started(_definition: AttackDefinition) -> void:
	if is_instance_valid(_executor) and _executor.is_active():
		monitoring = true


func _on_active_window_ended(_definition: AttackDefinition) -> void:
	monitoring = false


func _on_area_entered(overlapping_area: Area3D) -> void:
	if not monitoring or not is_instance_valid(_executor) or not _executor.is_active():
		return
	var hurtbox := overlapping_area as CombatHurtbox
	if hurtbox == null:
		return
	if not _is_eligible_target(hurtbox):
		return
	var health := hurtbox.get_health_component()
	if health == null:
		target_rejected.emit(hurtbox, "Hurtbox has no living HealthComponent.")
		return
	var applied_damage := _executor.try_hit(health)
	if applied_damage > 0.0:
		target_hit.emit(hurtbox, applied_damage)
	elif _executor.has_registered_hit(health):
		target_rejected.emit(hurtbox, "Target was already registered for this attack.")
	else:
		target_rejected.emit(hurtbox, "AttackExecutor rejected the hit outside its active window.")


func _is_eligible_target(hurtbox: CombatHurtbox) -> bool:
	if not hurtbox.hurtbox_enabled or not hurtbox.monitorable:
		return false
	var target_root := hurtbox.get_combatant_root()
	if target_root == null or not is_instance_valid(target_root):
		return false
	if _attacker_root != null and target_root == _attacker_root:
		return false
	# Empty team IDs are neutral/unspecified. Only matching explicit teams are friendly.
	if attacker_team_id != &"" and hurtbox.team_id != &"" and attacker_team_id == hurtbox.team_id:
		return false
	return true


func set_hitbox_enabled(enabled: bool) -> void:
	if not enabled:
		monitoring = false
	elif is_instance_valid(_executor) and _executor.is_active():
		monitoring = true
