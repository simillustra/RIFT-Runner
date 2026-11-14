extends SceneTree
## RR-003 D6 production CharacterActor integration and collision-arena validation.

const PHYSICS_STEPS: int = 180
const START_POSITION := Vector3(-1.5, 0.95, 0.0)
const WALL_CENTER_X: float = 2.8
var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var floor_body := _make_static_box("ArenaFloor", Vector3(30.0, 0.2, 30.0), Vector3(0.0, -0.1, 0.0))
	root.add_child(floor_body)

	# A 12-degree ramp rises toward +X. Its collision is part of the arena,
	# not a mocked grounded flag or a scripted height adjustment.
	var ramp := _make_static_box("ArenaSlope", Vector3(5.0, 0.2, 6.0), Vector3(0.0, 0.55, 0.0))
	ramp.rotation.z = deg_to_rad(12.0)
	root.add_child(ramp)

	var wall := _make_static_box("ArenaWall", Vector3(0.2, 5.0, 8.0), Vector3(WALL_CENTER_X, 2.5, 0.0))
	root.add_child(wall)

	var packed_actor := load("res://game/scenes/characters/character_actor.tscn") as PackedScene
	_check(packed_actor != null, "production CharacterActor scene resource loads")
	if packed_actor == null:
		quit(1)
		return

	var actor := packed_actor.instantiate() as CharacterActor
	_check(actor != null, "production scene instantiates as CharacterActor")
	if actor == null:
		quit(1)
		return
	actor.name = "RR003D6ProductionActor"
	actor.definition = load("res://game/resources/characters/heroes/vanguard.tres") as CharacterDefinition
	actor.position = START_POSITION
	var movement := actor.get_node_or_null("MovementController") as CharacterMovementController
	_check(movement != null, "production actor scene contains its movement controller")
	_check(_count_movement_controllers(actor) == 1, "production actor has exactly one movement controller")
	_check(movement != null and movement.get_parent() == actor, "movement controller is directly owned by CharacterActor")
	_check(actor.get_node_or_null("CollisionShape3D") is CollisionShape3D, "production actor has its capsule collision shape")
	_check(actor.get_node_or_null("HealthComponent") is HealthComponent, "production actor retains its health component")
	_check(actor.get_node_or_null("AttackExecutor") is AttackExecutor, "production actor retains its attack executor")
	_check(actor.get_node_or_null("HeroCombatController") is HeroCombatController, "production actor retains its hero combat controller")
	_check(actor.get_node_or_null("CombatReactionController") is CombatReactionController, "production actor retains its combat reaction controller")

	movement.movement_mode = CharacterMovementController.MovementMode.FREE
	root.add_child(actor)
	await process_frame
	await physics_frame

	_check(movement.is_operational(), "production movement controller initializes with valid CharacterBody3D ownership")
	_check(actor.definition != null and actor.definition.character_id == &"vanguard", "production actor receives the Vanguard character definition")
	_check(actor.definition != null and actor.definition.stats != null and is_equal_approx(movement._get_run_speed(), actor.definition.stats.movement_speed), "movement speed is sourced from the assigned CharacterDefinition")
	var health := actor.get_node("HealthComponent") as HealthComponent
	_check(health != null and is_equal_approx(health.max_health, actor.definition.stats.max_health), "CharacterActor configures health from the same character definition")
	_check(movement.is_grounded and actor.is_on_floor(), "production actor establishes real collision contact in the slope arena")

	# Local +X intent climbs the ramp. CharacterBody3D's solver must preserve
	# floor contact and stop the capsule against the vertical wall.
	movement.set_camera_basis(Basis.IDENTITY)
	movement.set_move_intent(Vector2.RIGHT)
	var initial_y := actor.global_position.y
	var highest_y := initial_y
	for _step in range(PHYSICS_STEPS):
		await physics_frame
		highest_y = maxf(highest_y, actor.global_position.y)
		if actor.global_position.x >= WALL_CENTER_X - 0.65:
			break

	_check(highest_y > initial_y + 0.25, "production actor climbs the collision-backed slope")
	_check(actor.global_position.x < WALL_CENTER_X - 0.25, "production capsule is blocked by the arena wall")
	_check(actor.is_on_floor() and movement.is_grounded, "production actor retains grounded contact on the slope")
	_check(actor.velocity.x < 0.5, "wall collision prevents continued horizontal movement through the obstacle")

	movement.set_move_intent(Vector2.ZERO)
	actor.queue_free()
	floor_body.queue_free()
	ramp.queue_free()
	wall.queue_free()
	await process_frame

	if failures == 0:
		print("RR-003 D6 actor integration and collision arena: PASS")
		quit(0)
	else:
		push_error("RR-003 D6 actor integration and collision arena: %d failure(s)" % failures)
		quit(1)


func _make_static_box(body_name: String, dimensions: Vector3, world_position: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = body_name
	body.position = world_position
	var collision := CollisionShape3D.new()
	collision.name = "%sCollision" % body_name
	var shape := BoxShape3D.new()
	shape.size = dimensions
	collision.shape = shape
	body.add_child(collision)
	return body


func _count_movement_controllers(node: Node) -> int:
	var count := 0
	for child: Node in node.find_children("*", "CharacterMovementController", true, false):
		if child is CharacterMovementController:
			count += 1
	return count


func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		failures += 1
		push_error("FAIL: %s" % description)
