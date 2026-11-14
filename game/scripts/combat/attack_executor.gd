extends Node
class_name AttackExecutor
## Deterministic attack phase controller.
## Hit detection is external; confirmed targets are submitted through try_hit() during ACTIVE only.

enum Phase {
	IDLE,
	STARTUP,
	ACTIVE,
	RECOVERY,
	COOLDOWN,
}

signal phase_changed(next_phase: Phase)
signal attack_started(definition: AttackDefinition, source: Node)
signal active_window_started(definition: AttackDefinition)
signal active_window_ended(definition: AttackDefinition)
signal hit_confirmed(target: HealthComponent, applied_damage: float)
signal attack_finished(definition: AttackDefinition)
signal attack_rejected(reason: String)

var phase: Phase = Phase.IDLE
var active_definition: AttackDefinition
var attack_source: Node
var _phase_remaining: float = 0.0
var _hit_targets: Dictionary = {}


func is_ready() -> bool:
	return phase == Phase.IDLE


func is_active() -> bool:
	return phase == Phase.ACTIVE


func begin_attack(definition: AttackDefinition, source: Node = null) -> Error:
	if not is_ready():
		attack_rejected.emit("Executor is not ready.")
		return ERR_BUSY
	if definition == null:
		attack_rejected.emit("AttackDefinition is required.")
		return ERR_INVALID_PARAMETER
	var validation_errors := definition.validate()
	if not validation_errors.is_empty():
		attack_rejected.emit("; ".join(validation_errors))
		return ERR_INVALID_DATA

	active_definition = definition
	attack_source = source if source != null else get_parent()
	_hit_targets.clear()
	attack_started.emit(active_definition, attack_source)
	if definition.startup_seconds > 0.0:
		_set_phase(Phase.STARTUP, definition.startup_seconds)
	else:
		_enter_active()
	return OK


## Called by the future hit-detection layer after it confirms an eligible overlap.
## A target is registered once per attack instance, even if it rejects damage.
func try_hit(target: HealthComponent) -> float:
	if phase != Phase.ACTIVE or active_definition == null or target == null:
		return 0.0
	if not is_instance_valid(target):
		return 0.0
	var target_id: int = target.get_instance_id()
	if _hit_targets.has(target_id):
		return 0.0
	_hit_targets[target_id] = true
	var applied_damage := target.apply_damage(
		active_definition.damage,
		attack_source,
		active_definition.damage_type
	)
	if applied_damage > 0.0:
		hit_confirmed.emit(target, applied_damage)
	return applied_damage


func has_registered_hit(target: HealthComponent) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	return _hit_targets.has(target.get_instance_id())


## Deterministic timer step. Large deltas may cross multiple phases without losing time.
func update_timers(delta: float) -> void:
	if delta <= 0.0 or phase == Phase.IDLE:
		return
	var remaining_delta := delta
	var transition_guard := 0
	while phase != Phase.IDLE and remaining_delta >= 0.0 and transition_guard < 8:
		transition_guard += 1
		if _phase_remaining > remaining_delta:
			_phase_remaining -= remaining_delta
			return
		remaining_delta -= _phase_remaining
		_phase_remaining = 0.0
		_advance_phase()
		if remaining_delta <= 0.0:
			return


func _process(delta: float) -> void:
	update_timers(delta)


func cancel_attack() -> void:
	if phase == Phase.IDLE:
		return
	var previous_definition := active_definition
	if phase == Phase.ACTIVE:
		active_window_ended.emit(previous_definition)
	_clear_attack()
	_set_phase(Phase.IDLE, 0.0)
	if previous_definition != null:
		attack_finished.emit(previous_definition)


func _enter_active() -> void:
	_set_phase(Phase.ACTIVE, active_definition.active_seconds)
	active_window_started.emit(active_definition)


func _advance_phase() -> void:
	match phase:
		Phase.STARTUP:
			_enter_active()
		Phase.ACTIVE:
			active_window_ended.emit(active_definition)
			if active_definition.recovery_seconds > 0.0:
				_set_phase(Phase.RECOVERY, active_definition.recovery_seconds)
			else:
				_enter_cooldown_or_finish()
		Phase.RECOVERY:
			_enter_cooldown_or_finish()
		Phase.COOLDOWN:
			var finished_definition := active_definition
			_clear_attack()
			_set_phase(Phase.IDLE, 0.0)
			if finished_definition != null:
				attack_finished.emit(finished_definition)


func _enter_cooldown_or_finish() -> void:
	if active_definition.cooldown_seconds > 0.0:
		_set_phase(Phase.COOLDOWN, active_definition.cooldown_seconds)
	else:
		var finished_definition := active_definition
		_clear_attack()
		_set_phase(Phase.IDLE, 0.0)
		if finished_definition != null:
			attack_finished.emit(finished_definition)


func _clear_attack() -> void:
	active_definition = null
	attack_source = null
	_phase_remaining = 0.0
	_hit_targets.clear()


func _set_phase(next_phase: Phase, duration: float) -> void:
	if phase == next_phase:
		_phase_remaining = duration
		return
	phase = next_phase
	_phase_remaining = duration
	phase_changed.emit(phase)
