extends Area3D
class_name CombatHurtbox
## Damage-receiving collision volume. It never applies damage itself.

@export var health_component_path: NodePath = NodePath("../HealthComponent")
@export var combatant_root_path: NodePath = NodePath("..")
@export var team_id: StringName = &""
@export var hurtbox_enabled: bool = true


func _ready() -> void:
	monitorable = true


func get_health_component() -> HealthComponent:
	if not hurtbox_enabled or not is_instance_valid(self):
		return null
	var component := get_node_or_null(health_component_path) as HealthComponent
	if component == null or component.is_dead:
		return null
	return component


func get_combatant_root() -> Node:
	return get_node_or_null(combatant_root_path)


func set_hurtbox_enabled(enabled: bool) -> void:
	hurtbox_enabled = enabled
	monitorable = enabled
