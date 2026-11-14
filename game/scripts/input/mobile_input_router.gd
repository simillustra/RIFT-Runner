extends Node
class_name MobileInputRouter
## RR-006 D7 deterministic multi-source arbitration and bounded action buffering.
signal command_routed(command: MobileInputCommand)
signal command_rejected(command: MobileInputCommand, reason: String)
signal command_buffered(command: MobileInputCommand, expires_in: float)
signal command_buffer_expired(command: MobileInputCommand)
signal movement_source_changed(source_id: StringName)
signal pause_requested
signal interaction_requested
signal cancel_requested(source_id: StringName)
@export var character_actor_path: NodePath = NodePath("..")
@export var movement_controller_path: NodePath = NodePath("../MovementController")
@export var hero_combat_controller_path: NodePath = NodePath("../HeroCombatController")
@export var gameplay_input_enabled: bool = true
@export_range(0.0, 1.0, 0.01) var input_buffer_window: float = 0.18
@export_range(1, 32, 1) var max_buffered_commands: int = 8
var _actor: CharacterActor
var _movement: CharacterMovementController
var _combat: HeroCombatController
var _last_sequence_by_source: Dictionary = {}
var _move_sources: Dictionary = {}
var _source_priorities: Dictionary = {}
var _active_move_source: StringName = &""
var _last_rejection := ""
var _input_clock := 0.0
var _buffered: Array[Dictionary] = []
var _buffer_serial := 0
var _flushing := false

func _ready() -> void:
	_actor = get_node_or_null(character_actor_path) as CharacterActor
	_movement = get_node_or_null(movement_controller_path) as CharacterMovementController
	_combat = get_node_or_null(hero_combat_controller_path) as HeroCombatController
	set_process(true)

func _process(delta: float) -> void:
	advance_input_time(delta)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT or what == NOTIFICATION_PREDELETE:
		clear_all_input("focus lost or router destroyed")

func _exit_tree() -> void:
	clear_all_input("router exited tree")

func route_command(command: MobileInputCommand) -> Error:
	_last_rejection = ""
	if command == null: return _reject(null, "Command cannot be null.", ERR_INVALID_PARAMETER)
	var errors := command.validate()
	if not errors.is_empty(): return _reject(command, "; ".join(errors), ERR_INVALID_DATA)
	var previous := int(_last_sequence_by_source.get(command.source_id, -1))
	if command.sequence_id <= previous: return _reject(command, "Stale or duplicate source sequence.", ERR_INVALID_DATA)
	_last_sequence_by_source[command.source_id] = command.sequence_id
	if not gameplay_input_enabled: return _reject(command, "Gameplay input disabled.", ERR_UNAVAILABLE)
	if not _is_actor_ready(): return _reject(command, "Hero gameplay authority unavailable.", ERR_UNCONFIGURED)
	var result := _dispatch(command)
	if result == OK:
		command_routed.emit(command)
		return OK
	if not _flushing and _can_buffer(command, result):
		return _enqueue(command)
	return _reject(command, "Action could not be accepted (error %d)." % result, result)

func set_gameplay_input_enabled(enabled: bool) -> void:
	gameplay_input_enabled = enabled
	if not enabled: clear_all_input("gameplay context disabled")

func set_source_priority(source_id: StringName, priority: int) -> Error:
	if source_id == &"" or priority < -1000 or priority > 1000: return ERR_INVALID_PARAMETER
	_source_priorities[source_id] = priority
	_recompute_move_owner()
	return OK

func get_source_priority(source_id: StringName) -> int:
	return int(_source_priorities.get(source_id, 0))

func get_active_move_source() -> StringName:
	return _active_move_source

func get_active_move_sources() -> PackedStringArray:
	var keys: Array = _move_sources.keys()
	keys.sort()
	var result := PackedStringArray()
	for key: Variant in keys: result.append(String(key))
	return result

func get_buffered_command_count() -> int:
	return _buffered.size()

func get_last_rejection() -> String:
	return _last_rejection

func release_source(source_id: StringName) -> void:
	if source_id == &"": return
	_move_sources.erase(source_id)
	_last_sequence_by_source.erase(source_id)
	_remove_buffered_source(source_id)
	_recompute_move_owner()

func clear_all_input(reason: String = "input cleared") -> void:
	var had_sources := not _move_sources.is_empty() or _active_move_source != &""
	_move_sources.clear()
	_buffered.clear()
	_last_sequence_by_source.clear()
	_active_move_source = &""
	if _movement != null: _movement.set_move_intent(Vector2.ZERO)
	if had_sources: movement_source_changed.emit(&"")
	_last_rejection = reason

func advance_input_time(delta: float) -> void:
	if not is_finite(delta) or delta <= 0.0: return
	_input_clock += delta
	for i in range(_buffered.size() - 1, -1, -1):
		if _input_clock - float(_buffered[i].time) >= input_buffer_window:
			var expired := _buffered[i].command as MobileInputCommand
			_buffered.remove_at(i)
			command_buffer_expired.emit(expired)
	_flush_buffered()

func is_action_supported(action: int) -> bool:
	if _actor == null or _actor.definition == null: return false
	var definition := _actor.definition
	match action:
		MobileInputAction.Action.MOVE: return _movement != null and _movement.movement_mode == CharacterMovementController.MovementMode.FREE
		MobileInputAction.Action.JUMP: return _movement != null
		MobileInputAction.Action.LANE_LEFT, MobileInputAction.Action.LANE_RIGHT: return _movement != null and _movement.movement_mode == CharacterMovementController.MovementMode.LANE
		MobileInputAction.Action.BASIC_ATTACK: return _combat != null and definition.basic_attack != null
		MobileInputAction.Action.ABILITY_PRIMARY, MobileInputAction.Action.ABILITY_SECONDARY:
			var id := definition.get_ability_id_for_slot(action)
			return _combat != null and id != &"" and definition.owns_ability(id)
		MobileInputAction.Action.PAUSE, MobileInputAction.Action.CANCEL: return true
		MobileInputAction.Action.INTERACT: return not get_signal_connection_list("interaction_requested").is_empty()
		MobileInputAction.Action.DODGE: return false
	return false

func _dispatch(command: MobileInputCommand) -> Error:
	if command.action == MobileInputAction.Action.MOVE: return _dispatch_move(command)
	if command.action == MobileInputAction.Action.CANCEL:
		if command.phase != MobileInputAction.Phase.STARTED:
			release_source(command.source_id)
			cancel_requested.emit(command.source_id)
		return OK
	if command.phase != MobileInputAction.Phase.PERFORMED: return OK
	match command.action:
		MobileInputAction.Action.JUMP:
			if not is_action_supported(command.action): return ERR_UNAVAILABLE
			_movement.request_jump()
			return OK
		MobileInputAction.Action.LANE_LEFT, MobileInputAction.Action.LANE_RIGHT:
			if not is_action_supported(command.action): return ERR_UNAVAILABLE
			_movement.request_lane_change(-1 if command.action == MobileInputAction.Action.LANE_LEFT else 1)
			return OK
		MobileInputAction.Action.BASIC_ATTACK:
			if not is_action_supported(command.action): return ERR_UNAVAILABLE
			return _combat.execute_basic_attack()
		MobileInputAction.Action.ABILITY_PRIMARY, MobileInputAction.Action.ABILITY_SECONDARY:
			var expected := _actor.definition.get_ability_id_for_slot(command.action)
			if expected == &"" or not _actor.definition.owns_ability(command.ability_id): return ERR_DOES_NOT_EXIST
			if command.ability_id != expected: return ERR_INVALID_PARAMETER
			return _combat.activate_ability(expected)
		MobileInputAction.Action.PAUSE:
			pause_requested.emit()
			return OK
		MobileInputAction.Action.INTERACT:
			if not is_action_supported(command.action): return ERR_UNAVAILABLE
			interaction_requested.emit()
			return OK
		MobileInputAction.Action.DODGE: return ERR_UNAVAILABLE
	return ERR_INVALID_PARAMETER

func _dispatch_move(command: MobileInputCommand) -> Error:
	if not is_action_supported(MobileInputAction.Action.MOVE): return ERR_UNAVAILABLE
	if command.phase == MobileInputAction.Phase.CANCELED:
		_move_sources.erase(command.source_id)
	else:
		_move_sources[command.source_id] = {"vector": command.vector if command.phase == MobileInputAction.Phase.PERFORMED else Vector2.ZERO, "strength": command.strength if command.phase == MobileInputAction.Phase.PERFORMED else 0.0}
	_recompute_move_owner()
	return OK

func _recompute_move_owner() -> void:
	var old := _active_move_source
	var candidates: Array[StringName] = []
	for key: Variant in _move_sources.keys(): candidates.append(StringName(key))
	candidates.sort_custom(func(a: StringName, b: StringName) -> bool:
		var pa := get_source_priority(a)
		var pb := get_source_priority(b)
		return String(a) < String(b) if pa == pb else pa > pb
	)
	_active_move_source = candidates[0] if not candidates.is_empty() else &""
	if _movement != null:
		if _active_move_source == &"": _movement.set_move_intent(Vector2.ZERO)
		else:
			var item: Dictionary = _move_sources[_active_move_source]
			_movement.set_move_intent((item.vector as Vector2) * float(item.strength))
	if old != _active_move_source: movement_source_changed.emit(_active_move_source)

func _can_buffer(command: MobileInputCommand, result: Error) -> bool:
	if input_buffer_window <= 0.0 or max_buffered_commands <= 0 or (result != ERR_BUSY and result != ERR_UNAVAILABLE): return false
	if command.phase != MobileInputAction.Phase.PERFORMED: return false
	if command.action in [MobileInputAction.Action.MOVE, MobileInputAction.Action.CANCEL, MobileInputAction.Action.PAUSE, MobileInputAction.Action.INTERACT]: return false
	return is_action_supported(command.action)

func _enqueue(command: MobileInputCommand) -> Error:
	for i in range(_buffered.size() - 1, -1, -1):
		var old := _buffered[i].command as MobileInputCommand
		if old.source_id == command.source_id and old.action == command.action: _buffered.remove_at(i)
	if _buffered.size() >= max_buffered_commands: _buffered.pop_front()
	_buffer_serial += 1
	_buffered.append({"command": _copy_command(command), "time": _input_clock, "serial": _buffer_serial})
	command_buffered.emit(command, input_buffer_window)
	return OK

func _flush_buffered() -> void:
	if _flushing or not gameplay_input_enabled or _buffered.is_empty() or not _is_actor_ready(): return
	_flushing = true
	_buffered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ca := a.command as MobileInputCommand
		var cb := b.command as MobileInputCommand
		var pa := get_source_priority(ca.source_id)
		var pb := get_source_priority(cb.source_id)
		if pa != pb: return pa > pb
		if ca.source_id != cb.source_id: return String(ca.source_id) < String(cb.source_id)
		return int(a.serial) < int(b.serial)
	)
	var i := 0
	while i < _buffered.size():
		var command := _buffered[i].command as MobileInputCommand
		var result := _dispatch(command)
		if result == OK:
			_buffered.remove_at(i)
			command_routed.emit(command)
		elif result == ERR_BUSY or result == ERR_UNAVAILABLE: i += 1
		else:
			_buffered.remove_at(i)
			_reject(command, "Buffered action became invalid.", result)
	_flushing = false

func _copy_command(source: MobileInputCommand) -> MobileInputCommand:
	var copy := MobileInputCommand.new()
	copy.action = source.action
	copy.phase = source.phase
	copy.mode = source.mode
	copy.vector = source.vector
	copy.strength = source.strength
	copy.ability_id = source.ability_id
	copy.source_id = source.source_id
	copy.sequence_id = source.sequence_id
	return copy


func _remove_buffered_source(source_id: StringName) -> void:
	for i in range(_buffered.size() - 1, -1, -1):
		var command := _buffered[i].command as MobileInputCommand
		if command.source_id == source_id: _buffered.remove_at(i)

func _is_actor_ready() -> bool:
	if not is_instance_valid(_actor) or _actor.definition == null or not _actor.definition.validate().is_empty(): return false
	var health := _actor.get_node_or_null("HealthComponent") as HealthComponent
	return health != null and not health.is_dead and (_movement != null or _combat != null)

func _reject(command: MobileInputCommand, reason: String, error: Error) -> Error:
	_last_rejection = reason
	if command != null: command_rejected.emit(command, reason)
	return error
