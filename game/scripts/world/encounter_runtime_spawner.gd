extends Node
class_name EncounterRuntimeSpawner
## Turns deterministic segment spawn plans into pooled, encounter-scoped enemy instances.
signal encounter_spawned(segment: Node3D, enemy_count: int, seed_value: int)
signal enemy_spawned(enemy: Node3D, definition: EnemySpawnDefinition, segment: Node3D)
signal encounter_released(segment: Node3D, pooled_enemy_count: int)

@export var spawn_director: EncounterSpawnDirector
@export var spawn_definitions: Array[EnemySpawnDefinition] = []
@export_range(0, 64, 1) var max_pooled_enemies: int = 16
@export_range(1, 16, 1) var squad_attack_cap: int = 2
@export_range(0, 20, 1) var difficulty_level: int = 0

var _generator: ProceduralWorldGenerator
var _active_encounters: Dictionary = {}
var _pool_by_definition: Dictionary = {}
var _pooled_enemy_count: int = 0
var _pool_root: Node3D
var _configuration_valid: bool = false

func _ready() -> void:
	_generator = get_parent() as ProceduralWorldGenerator
	if _generator == null:
		push_error("EncounterRuntimeSpawner must be a child of ProceduralWorldGenerator.")
		return
	var configuration_errors := validate_configuration()
	_configuration_valid = configuration_errors.is_empty()
	if not _configuration_valid:
		push_error("EncounterRuntimeSpawner configuration is invalid: %s" % "; ".join(configuration_errors))
	_ensure_pool_root()
	_generator.segment_spawned.connect(_on_segment_spawned)
	_generator.segment_recycled.connect(_on_segment_recycled)
	_generator.generation_reset.connect(_on_generation_reset)
	for child: Node in _generator.get_children():
		var segment := child as Node3D
		if segment != null and segment.has_meta("segment_definition"):
			_on_segment_spawned(segment, segment.get_meta("segment_definition") as WorldSegmentDefinition)

func validate_configuration() -> PackedStringArray:
	var errors := PackedStringArray()
	if spawn_director == null:
		errors.append("spawn_director must be assigned.")
	if spawn_definitions.is_empty():
		errors.append("At least one enemy spawn definition is required.")
	var seen: Dictionary = {}
	for definition: EnemySpawnDefinition in spawn_definitions:
		if definition == null:
			errors.append("spawn_definitions must not contain null entries.")
			continue
		for issue: String in definition.validate():
			errors.append("%s: %s" % [String(definition.definition_id), issue])
		if seen.has(definition.definition_id):
			errors.append("Duplicate enemy definition_id '%s'." % String(definition.definition_id))
		seen[definition.definition_id] = true
	if squad_attack_cap < 0:
		errors.append("squad_attack_cap must not be negative.")
	return errors

func get_active_enemy_count(segment: Node3D = null) -> int:
	if segment != null:
		return _count_enemy_children(_active_encounters.get(segment.get_instance_id()) as Node3D)
	var total := 0
	for value: Variant in _active_encounters.values():
		total += _count_enemy_children(value as Node3D)
	return total

func get_pooled_enemy_count() -> int:
	return _pooled_enemy_count

func get_encounter_root(segment: Node3D) -> Node3D:
	if segment == null or not is_instance_valid(segment):
		return null
	return _active_encounters.get(segment.get_instance_id()) as Node3D

func release_segment(segment: Node3D) -> void:
	if segment == null or not is_instance_valid(segment):
		return
	var segment_id: int = segment.get_instance_id()
	if not _active_encounters.has(segment_id):
		return
	var runtime := _active_encounters[segment_id] as Node3D
	_active_encounters.erase(segment_id)
	var released_count := 0
	if runtime != null and is_instance_valid(runtime):
		for child: Node in runtime.get_children():
			if child is Node3D and not child is EnemySquadCoordinator:
				_pool_enemy(child as Node3D)
				released_count += 1
		if runtime.get_parent() != null:
			runtime.get_parent().remove_child(runtime)
		runtime.free()
	encounter_released.emit(segment, released_count)

func _on_segment_spawned(segment: Node3D, _definition: WorldSegmentDefinition) -> void:
	if segment == null or not is_instance_valid(segment) or not _configuration_valid:
		return
	var segment_instance_id: int = segment.get_instance_id()
	if _active_encounters.has(segment_instance_id):
		return
	var segment_index := int(segment.get_meta("segment_index", 0))
	spawn_director.world_seed = _generator.world_seed
	var plan := spawn_director.build_spawn_plan(segment, segment_index, difficulty_level)
	var spawn_points: Array = plan.get("spawn_points", [])
	var concurrency_cap := maxi(int(plan.get("max_concurrent", 0)), 0)
	var spawn_count := mini(spawn_points.size(), concurrency_cap)
	if spawn_count <= 0:
		return
	var runtime := Node3D.new()
	runtime.name = "EncounterRuntime_%d" % segment_index
	segment.add_child(runtime)
	var coordinator := EnemySquadCoordinator.new()
	coordinator.name = "EnemySquadCoordinator"
	coordinator.max_simultaneous_attackers_per_target = maxi(squad_attack_cap, 1)
	runtime.add_child(coordinator)
	_active_encounters[segment_instance_id] = runtime
	var rng := RandomNumberGenerator.new()
	rng.seed = int(plan.get("seed", 0))
	var spawned := 0
	for index: int in range(spawn_count):
		var definition := _choose_definition(rng)
		if definition == null:
			continue
		var enemy := _acquire_enemy(definition)
		if enemy == null:
			continue
		runtime.add_child(enemy)
		var spawn_transform: Transform3D = spawn_points[index]
		enemy.global_transform = spawn_transform
		enemy.set_meta("spawn_definition_id", definition.definition_id)
		_configure_enemy(enemy, definition, coordinator)
		enemy_spawned.emit(enemy, definition, segment)
		spawned += 1
	encounter_spawned.emit(segment, spawned, int(plan.get("seed", 0)))
	if spawned == 0:
		_active_encounters.erase(segment_instance_id)
		runtime.queue_free()

func _on_segment_recycled(segment: Node3D, _definition: WorldSegmentDefinition) -> void:
	release_segment(segment)

func _on_generation_reset() -> void:
	_active_encounters.clear()
	_clear_pool()

func _choose_definition(rng: RandomNumberGenerator) -> EnemySpawnDefinition:
	var total_weight := 0
	for definition: EnemySpawnDefinition in spawn_definitions:
		if definition != null:
			total_weight += definition.selection_weight
	if total_weight <= 0:
		return null
	var selected := rng.randi_range(1, total_weight)
	for definition: EnemySpawnDefinition in spawn_definitions:
		if definition == null:
			continue
		selected -= definition.selection_weight
		if selected <= 0:
			return definition
	return null

func _configure_enemy(enemy: Node3D, definition: EnemySpawnDefinition, coordinator: EnemySquadCoordinator) -> void:
	var archetype := enemy.get_node_or_null("EnemyArchetypeController") as EnemyArchetypeController
	if archetype != null:
		var result := archetype.apply_profile(definition.archetype_profile)
		if result != OK:
			push_warning("Could not apply archetype '%s' to spawned enemy." % String(definition.definition_id))
	var ai := enemy.get_node_or_null("EnemyAIController") as EnemyAIController
	if ai != null:
		ai.assign_squad_coordinator(coordinator)

func _acquire_enemy(definition: EnemySpawnDefinition) -> Node3D:
	_ensure_pool_root()
	var key: StringName = definition.definition_id
	var bucket: Array = _pool_by_definition.get(key, [])
	if not bucket.is_empty():
		var pooled := bucket.pop_back() as Node3D
		_pool_by_definition[key] = bucket
		_pooled_enemy_count -= 1
		_pool_root.remove_child(pooled)
		_restore_enemy(pooled)
		_reset_enemy_for_spawn(pooled)
		return pooled
	var instance := definition.enemy_scene.instantiate()
	var enemy := instance as Node3D
	if enemy == null:
		instance.free()
		push_warning("Enemy scene '%s' does not have a Node3D root." % String(definition.definition_id))
		return null
	_reset_enemy_for_spawn(enemy)
	return enemy

func _reset_enemy_for_spawn(enemy: Node3D) -> void:
	var health := enemy.get_node_or_null("HealthComponent") as HealthComponent
	if health != null:
		health.reset_health()
	var reactions := enemy.get_node_or_null("CombatReactionController") as CombatReactionController
	if reactions != null:
		reactions.reset_for_spawn()
	var ai := enemy.get_node_or_null("EnemyAIController") as EnemyAIController
	if ai != null:
		ai.reset_for_spawn()
	var body := enemy as CharacterBody3D
	if body != null:
		body.velocity = Vector3.ZERO

func _pool_enemy(enemy: Node3D) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	var definition_id: StringName = enemy.get_meta("spawn_definition_id", &"")
	var ai := enemy.get_node_or_null("EnemyAIController") as EnemyAIController
	if ai != null:
		ai.clear_target()
		ai.assign_squad_coordinator(null)
	var executor := enemy.get_node_or_null("AttackExecutor") as AttackExecutor
	if executor != null:
		executor.cancel_attack()
	_disable_collision_tree(enemy)
	if not enemy.has_meta("_pool_original_process_mode"):
		enemy.set_meta("_pool_original_process_mode", enemy.process_mode)
		enemy.set_meta("_pool_original_process_enabled", enemy.is_processing())
		enemy.set_meta("_pool_original_physics_enabled", enemy.is_physics_processing())
	if enemy.get_parent() != null:
		enemy.get_parent().remove_child(enemy)
	enemy.process_mode = Node.PROCESS_MODE_DISABLED
	enemy.set_process(false)
	enemy.set_physics_process(false)
	enemy.visible = false
	if _pooled_enemy_count >= max_pooled_enemies or definition_id == &"":
		enemy.free()
		return
	_pool_root.add_child(enemy)
	var bucket: Array = _pool_by_definition.get(definition_id, [])
	bucket.append(enemy)
	_pool_by_definition[definition_id] = bucket
	_pooled_enemy_count += 1

func _restore_enemy(enemy: Node3D) -> void:
	enemy.process_mode = int(enemy.get_meta("_pool_original_process_mode", Node.PROCESS_MODE_INHERIT))
	enemy.visible = true
	enemy.set_process(bool(enemy.get_meta("_pool_original_process_enabled", true)))
	enemy.set_physics_process(bool(enemy.get_meta("_pool_original_physics_enabled", true)))
	_restore_collision_tree(enemy)

func _disable_collision_tree(node: Node) -> void:
	if node is CollisionShape3D:
		var shape := node as CollisionShape3D
		if not shape.has_meta("_pool_original_disabled"):
			shape.set_meta("_pool_original_disabled", shape.disabled)
		shape.disabled = true
	elif node is CollisionPolygon3D:
		var polygon := node as CollisionPolygon3D
		if not polygon.has_meta("_pool_original_disabled"):
			polygon.set_meta("_pool_original_disabled", polygon.disabled)
		polygon.disabled = true
	elif node is Area3D:
		var area := node as Area3D
		if not area.has_meta("_pool_original_monitoring"):
			area.set_meta("_pool_original_monitoring", area.monitoring)
			area.set_meta("_pool_original_monitorable", area.monitorable)
		area.monitoring = false
		area.monitorable = false
	for child: Node in node.get_children():
		_disable_collision_tree(child)

func _restore_collision_tree(node: Node) -> void:
	if node is CollisionShape3D:
		var shape := node as CollisionShape3D
		shape.disabled = bool(shape.get_meta("_pool_original_disabled", false))
	elif node is CollisionPolygon3D:
		var polygon := node as CollisionPolygon3D
		polygon.disabled = bool(polygon.get_meta("_pool_original_disabled", false))
	elif node is Area3D:
		var area := node as Area3D
		area.monitoring = bool(area.get_meta("_pool_original_monitoring", true))
		area.monitorable = bool(area.get_meta("_pool_original_monitorable", true))
	for child: Node in node.get_children():
		_restore_collision_tree(child)

func _count_enemy_children(runtime: Node3D) -> int:
	if runtime == null or not is_instance_valid(runtime):
		return 0
	var count := 0
	for child: Node in runtime.get_children():
		if child is Node3D and not child is EnemySquadCoordinator:
			count += 1
	return count

func _clear_pool() -> void:
	if _pool_root != null and is_instance_valid(_pool_root):
		for child: Node in _pool_root.get_children():
			_pool_root.remove_child(child)
			child.free()
	_pool_by_definition.clear()
	_pooled_enemy_count = 0

func _ensure_pool_root() -> void:
	if _pool_root != null and is_instance_valid(_pool_root):
		return
	_pool_root = Node3D.new()
	_pool_root.name = "EnemyPool"
	add_child(_pool_root)
