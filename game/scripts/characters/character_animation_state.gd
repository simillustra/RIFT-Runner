extends RefCounted
class_name CharacterAnimationState
## Read-only-by-contract snapshot of movement facts consumed by presentation systems.
## This object is a detached value snapshot; changing it never changes the actor/controller.

var planar_velocity: Vector3
var vertical_velocity: float
var is_grounded: bool
var movement_mode: int
var facing_basis: Basis


func _init(
	planar_velocity_value: Vector3 = Vector3.ZERO,
	vertical_velocity_value: float = 0.0,
	is_grounded_value: bool = false,
	movement_mode_value: int = 0,
	facing_basis_value: Basis = Basis.IDENTITY
) -> void:
	planar_velocity = Vector3(
		planar_velocity_value.x,
		0.0,
		planar_velocity_value.z
	)
	vertical_velocity = vertical_velocity_value
	is_grounded = is_grounded_value
	movement_mode = movement_mode_value
	facing_basis = facing_basis_value
