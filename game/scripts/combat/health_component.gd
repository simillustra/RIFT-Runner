extends Node
class_name HealthComponent
## Authoritative health and damage-reception component.
## This component owns health only; attack detection and hit confirmation belong to combat actors.

signal damaged(applied_damage: float, remaining_health: float, source: Node, damage_type: StringName)
signal healed(applied_healing: float, remaining_health: float)
signal died(source: Node)

@export_range(1.0, 10000.0, 1.0) var max_health: float = 100.0
@export_range(0.0, 1000.0, 0.1) var defense: float = 0.0
@export_range(0.0, 10.0, 0.01) var invulnerability_seconds: float = 0.0

var current_health: float = 100.0
var is_dead: bool = false
var _invulnerability_remaining: float = 0.0
var damage_taken_multiplier: float = 1.0


func _ready() -> void:
	current_health = max_health
	is_dead = false


func configure(maximum_health: float, defense_value: float) -> Error:
	if maximum_health <= 0.0 or defense_value < 0.0:
		return ERR_INVALID_PARAMETER
	max_health = maximum_health
	defense = defense_value
	current_health = max_health
	is_dead = false
	_invulnerability_remaining = 0.0
	return OK


## Applies damage after defense and temporary invulnerability.
## Positive hits always deal at least one point after defense.
## Returns the amount actually removed from health; zero means rejected/blocked.
func apply_damage(raw_damage: float, source: Node = null, damage_type: StringName = &"physical") -> float:
	if is_dead or raw_damage <= 0.0 or _invulnerability_remaining > 0.0:
		return 0.0
	var mitigated_damage := maxf(raw_damage - defense, 1.0)
	var scaled_damage := mitigated_damage * damage_taken_multiplier
	if scaled_damage <= 0.0:
		return 0.0
	var applied_damage := minf(scaled_damage, current_health)
	if applied_damage <= 0.0:
		return 0.0
	current_health = maxf(current_health - applied_damage, 0.0)
	if invulnerability_seconds > 0.0:
		_invulnerability_remaining = invulnerability_seconds
	damaged.emit(applied_damage, current_health, source, damage_type)
	if current_health <= 0.0:
		is_dead = true
		died.emit(source)
	return applied_damage


## Restores health up to max_health. Dead actors require an explicit reset.
func heal(amount: float) -> float:
	if is_dead or amount <= 0.0:
		return 0.0
	var applied_healing := minf(amount, max_health - current_health)
	if applied_healing <= 0.0:
		return 0.0
	current_health += applied_healing
	healed.emit(applied_healing, current_health)
	return applied_healing


## Sets a non-negative damage intake scale. Zero makes the receiver immune.
func set_damage_taken_multiplier(multiplier: float) -> Error:
	if multiplier < 0.0:
		return ERR_INVALID_PARAMETER
	damage_taken_multiplier = multiplier
	return OK


func reset_health() -> void:
	current_health = max_health
	is_dead = false
	_invulnerability_remaining = 0.0


## Public deterministic timer step; also called automatically by _process.
func update_timers(delta: float) -> void:
	if delta <= 0.0:
		return
	_invulnerability_remaining = maxf(_invulnerability_remaining - delta, 0.0)


func _process(delta: float) -> void:
	update_timers(delta)


func get_health_ratio() -> float:
	return 0.0 if max_health <= 0.0 else current_health / max_health
