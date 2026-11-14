extends Node
class_name BossDamageController
## Boss vulnerability phases configure D1 damage intake; they never apply damage directly.

enum Phase {
	ARMORED,
	EXPOSED,
	ENRAGED,
	DEFEATED,
}

signal phase_changed(next_phase: Phase, damage_multiplier: float)

@export var health_component_path: NodePath = NodePath("../HealthComponent")
@export_range(0.0, 10.0, 0.05) var armored_damage_multiplier: float = 0.25
@export_range(0.0, 10.0, 0.05) var exposed_damage_multiplier: float = 1.5
@export_range(0.0, 10.0, 0.05) var enraged_damage_multiplier: float = 1.0

var phase: Phase = Phase.ARMORED
var _health: HealthComponent


func _ready() -> void:
	_health = get_node_or_null(health_component_path) as HealthComponent
	if _health == null:
		push_warning("BossDamageController requires a HealthComponent at '%s'." % health_component_path)
		return
	_health.died.connect(_on_boss_died)
	_apply_phase_multiplier()


## Boss encounter logic owns phase timing and calls this method when its
## telegraph/weak-point/health-threshold rules authorize a transition.
func set_phase(next_phase: Phase) -> Error:
	if not is_instance_valid(_health):
		return ERR_UNCONFIGURED
	if _health.is_dead or phase == Phase.DEFEATED:
		return ERR_UNCONFIGURED
	if next_phase == Phase.DEFEATED:
		return ERR_INVALID_PARAMETER
	if next_phase < Phase.ARMORED or next_phase > Phase.ENRAGED:
		return ERR_INVALID_PARAMETER
	if phase == next_phase:
		return OK
	phase = next_phase
	_apply_phase_multiplier()
	phase_changed.emit(phase, _health.damage_taken_multiplier)
	return OK


func get_damage_multiplier() -> float:
	if not is_instance_valid(_health):
		return 1.0
	return _health.damage_taken_multiplier


func _apply_phase_multiplier() -> void:
	if not is_instance_valid(_health):
		return
	match phase:
		Phase.ARMORED:
			_health.set_damage_taken_multiplier(armored_damage_multiplier)
		Phase.EXPOSED:
			_health.set_damage_taken_multiplier(exposed_damage_multiplier)
		Phase.ENRAGED:
			_health.set_damage_taken_multiplier(enraged_damage_multiplier)


func _on_boss_died(_source: Node) -> void:
	phase = Phase.DEFEATED
	if is_instance_valid(_health):
		_health.set_damage_taken_multiplier(0.0)
	phase_changed.emit(phase, 0.0)
