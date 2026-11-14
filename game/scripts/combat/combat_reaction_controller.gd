extends Node
class_name CombatReactionController
## Converts authoritative HealthComponent events into local movement/animation presentation.
## It never applies damage and is safe when optional rig assets are absent.

signal hit_reacted(applied_damage: float, damage_type: StringName)
signal stagger_started(duration: float)
signal knockback_applied(impulse: Vector3)
signal death_presented

@export var health_component_path: NodePath = NodePath("../HealthComponent")
@export var movement_controller_path: NodePath = NodePath("../MovementController")
@export var animation_integration_path: NodePath = NodePath("../AnimationIntegration")
@export var attack_executor_path: NodePath = NodePath("../AttackExecutor")
@export_range(0.0, 2.0, 0.01) var hit_stun_seconds: float = 0.28
@export_range(0.0, 30.0, 0.1) var knockback_strength: float = 4.0
@export_range(0.0, 10.0, 0.1) var vertical_knockback: float = 1.0
@export var disable_collision_on_death: bool = true

var _health: HealthComponent
var _movement: CharacterMovementController
var _animation_integration: CharacterAnimationIntegration
var _executor: AttackExecutor
var _actor: Node3D
var _dead: bool = false
var _fallback_stagger_remaining: float = 0.0


func _ready() -> void:
	_actor = get_parent() as Node3D
	_health = get_node_or_null(health_component_path) as HealthComponent
	_movement = get_node_or_null(movement_controller_path) as CharacterMovementController
	_animation_integration = get_node_or_null(animation_integration_path) as CharacterAnimationIntegration
	_executor = get_node_or_null(attack_executor_path) as AttackExecutor
	if _health == null:
		push_warning("CombatReactionController requires a HealthComponent.")
		return
	_health.damaged.connect(_on_damaged)
	_health.died.connect(_on_died)


func _exit_tree() -> void:
	if is_instance_valid(_health):
		if _health.damaged.is_connected(_on_damaged):
			_health.damaged.disconnect(_on_damaged)
		if _health.died.is_connected(_on_died):
			_health.died.disconnect(_on_died)


func _physics_process(delta: float) -> void:
	if _movement != null or _dead or delta <= 0.0 or _fallback_stagger_remaining <= 0.0:
		return
	_fallback_stagger_remaining = maxf(_fallback_stagger_remaining - delta, 0.0)
	var body := _actor as CharacterBody3D
	if body != null:
		body.move_and_slide()


func _on_damaged(applied_damage: float, _remaining_health: float, source: Node, damage_type: StringName) -> void:
	if _dead or applied_damage <= 0.0:
		return
	hit_reacted.emit(applied_damage, damage_type)
	var animation_controller := _animation_integration.get_runtime_controller() if is_instance_valid(_animation_integration) else null
	if animation_controller != null:
		animation_controller.play_hit_react()
	var impulse := _calculate_knockback(source)
	if not impulse.is_zero_approx():
		if is_instance_valid(_movement):
			_movement.apply_combat_impulse(impulse, hit_stun_seconds)
		else:
			var body := _actor as CharacterBody3D
			if body != null:
				body.velocity += impulse
				_fallback_stagger_remaining = maxf(_fallback_stagger_remaining, hit_stun_seconds)
		knockback_applied.emit(impulse)
	if hit_stun_seconds > 0.0:
		stagger_started.emit(hit_stun_seconds)


func _calculate_knockback(source: Node) -> Vector3:
	if knockback_strength <= 0.0 or _actor == null:
		return Vector3.ZERO
	var direction := -_actor.global_transform.basis.z
	if source is Node3D:
		direction = _actor.global_position - (source as Node3D).global_position
	direction.y = 0.0
	if direction.is_zero_approx():
		direction = -_actor.global_transform.basis.z
	direction = direction.normalized()
	return direction * knockback_strength + Vector3.UP * vertical_knockback


func _on_died(_source: Node) -> void:
	if _dead:
		return
	_dead = true
	_fallback_stagger_remaining = 0.0
	if is_instance_valid(_movement):
		_movement.set_dead()
	if is_instance_valid(_executor):
		_executor.cancel_attack()
	if disable_collision_on_death:
		_disable_combat_collision()
	death_presented.emit()


func _disable_combat_collision() -> void:
	if _actor == null:
		return
	for node: Node in _actor.find_children("*", "CollisionShape3D", true, false):
		var shape := node as CollisionShape3D
		if shape != null:
			shape.set_deferred("disabled", true)
	for node: Node in _actor.find_children("*", "CombatHurtbox", true, false):
		var hurtbox := node as CombatHurtbox
		if hurtbox != null:
			hurtbox.set_hurtbox_enabled(false)


func is_dead() -> bool:
	return _dead


func get_fallback_stagger_remaining() -> float:
	return _fallback_stagger_remaining
