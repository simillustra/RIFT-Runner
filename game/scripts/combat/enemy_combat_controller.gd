extends Node
class_name EnemyCombatController
## Enemy attack entry point. D2 remains authoritative for attack timing and damage.

signal attack_requested(definition: AttackDefinition)
signal attack_rejected(reason: String)

@export var attack_executor_path: NodePath = NodePath("../AttackExecutor")
@export var health_component_path: NodePath = NodePath("../HealthComponent")
@export var attack_definition: AttackDefinition

var _executor: AttackExecutor
var _health: HealthComponent


func _ready() -> void:
	_executor = get_node_or_null(attack_executor_path) as AttackExecutor
	_health = get_node_or_null(health_component_path) as HealthComponent
	if _executor == null:
		push_warning("EnemyCombatController requires an AttackExecutor at '%s'." % attack_executor_path)
	if _health == null:
		push_warning("EnemyCombatController requires a HealthComponent at '%s'." % health_component_path)


## Called by enemy behavior/AI when an attack opportunity is confirmed.
## Collision and target selection remain the responsibility of D3 hitboxes.
func request_attack() -> Error:
	if not is_instance_valid(_executor) or not is_instance_valid(_health):
		attack_rejected.emit("Enemy combat dependencies are not configured.")
		return ERR_UNCONFIGURED
	if _health.is_dead:
		attack_rejected.emit("Dead enemies cannot attack.")
		return ERR_UNCONFIGURED
	if attack_definition == null:
		attack_rejected.emit("Enemy AttackDefinition is not configured.")
		return ERR_UNCONFIGURED
	var errors := attack_definition.validate()
	if not errors.is_empty():
		attack_rejected.emit("; ".join(errors))
		return ERR_INVALID_DATA
	var result := _executor.begin_attack(attack_definition, get_parent())
	if result == OK:
		attack_requested.emit(attack_definition)
	else:
		attack_rejected.emit("AttackExecutor rejected the request (error %d)." % result)
	return result
