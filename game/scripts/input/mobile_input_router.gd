extends Node
class_name MobileInputRouter
## RR-006 D5 deterministic semantic-command router.
## Dispatches intent to existing gameplay authorities; it contains no game physics.

signal command_routed(command: MobileInputCommand)
signal command_rejected(command: MobileInputCommand, reason: String)
signal pause_requested
signal interaction_requested
signal cancel_requested(source_id: StringName)

@export var character_actor_path: NodePath = NodePath("..")
@export var movement_controller_path: NodePath = NodePath("../MovementController")
@export var hero_combat_controller_path: NodePath = NodePath("../HeroCombatController")
@export var gameplay_input_enabled: bool = true

var _actor: CharacterActor
var _movement: CharacterMovementController
var _combat: HeroCombatController
var _last_sequence_by_source: Dictionary = {}
var _active_move_source: StringName = &""
var _last_rejection: String = ""


func _ready() -> void:
	_actor = get_node_or_null(character_actor_path) as CharacterActor
	_movement = get_node_or_null(movement_controller_path) as CharacterMovementController
	_combat = get_node_or_null(hero_combat_controller_path) as HeroCombatController


func route_command(command: MobileInputCommand) -> Error:
	_last_rejection = ""
	if command == null:
		return _reject(null, "Command cannot be null.", ERR_INVALID_PARAMETER)
	var errors := command.validate()
	if not errors.is_empty():
		return _reject(command, "; ".join(errors), ERR_INVALID_DATA)
	var previous_sequence := int(_last_sequence_by_source.get(command.source_id, -1))
	if command.sequence_id <= previous_sequence:
		return _reject(command, "Stale or duplicate sequence_id for source '%s'." % String(command.source_id), ERR_INVALID_DATA)
	_last_sequence_by_source[command.source_id] = command.sequence_id
	if not gameplay_input_enabled:
		return _reject(command, "Gameplay input is currently disabled.", ERR_UNAVAILABLE)
	if not _is_actor_ready():
		return _reject(command, "Active hero, health or required gameplay authority is unavailable.", ERR_UNCONFIGURED)

	var result := _dispatch(command)
	if result == OK:
		command_routed.emit(command)
	else:
		_reject(command, "Action '%s' is unsupported or could not be accepted (error %d)." % [String(MobileInputAction.action_name(command.action)), result], result)
	return result


func set_gameplay_input_enabled(enabled: bool) -> void:
	gameplay_input_enabled = enabled
	if not enabled:
		_neutralize_movement()


func is_action_supported(action: int) -> bool:
	if _actor == null or _actor.definition == null:
		return false
	var definition := _actor.definition
	match action:
		MobileInputAction.Action.MOVE:
			return _movement != null and _movement.movement_mode == CharacterMovementController.MovementMode.FREE
		MobileInputAction.Action.JUMP:
			return _movement != null
		MobileInputAction.Action.LANE_LEFT, MobileInputAction.Action.LANE_RIGHT:
			return _movement != null and _movement.movement_mode == CharacterMovementController.MovementMode.LANE
		MobileInputAction.Action.BASIC_ATTACK:
			return _combat != null and definition.basic_attack != null
		MobileInputAction.Action.ABILITY_PRIMARY, MobileInputAction.Action.ABILITY_SECONDARY:
			var ability_id := definition.get_ability_id_for_slot(action)
			return _combat != null and ability_id != &"" and definition.owns_ability(ability_id)
		MobileInputAction.Action.PAUSE:
			return not get_signal_connection_list("pause_requested").is_empty()
		MobileInputAction.Action.INTERACT:
			return not get_signal_connection_list("interaction_requested").is_empty()
		MobileInputAction.Action.CANCEL:
			return true
		MobileInputAction.Action.DODGE:
			return false
	return false


func get_last_rejection() -> String:
	return _last_rejection


func get_active_move_source() -> StringName:
	return _active_move_source


func _dispatch(command: MobileInputCommand) -> Error:
	if command.action == MobileInputAction.Action.MOVE:
		return _dispatch_move(command)
	if command.phase == MobileInputAction.Phase.CANCELED:
		return OK
	if command.phase == MobileInputAction.Phase.STARTED:
		return OK

	match command.action:
		MobileInputAction.Action.JUMP:
			if not is_action_supported(command.action):
				return ERR_UNAVAILABLE
			_movement.request_jump()
			return OK
		MobileInputAction.Action.LANE_LEFT:
			if not is_action_supported(command.action):
				return ERR_UNAVAILABLE
			_movement.request_lane_change(-1)
			return OK
		MobileInputAction.Action.LANE_RIGHT:
			if not is_action_supported(command.action):
				return ERR_UNAVAILABLE
			_movement.request_lane_change(1)
			return OK
		MobileInputAction.Action.BASIC_ATTACK:
			if not is_action_supported(command.action):
				return ERR_UNAVAILABLE
			return _combat.execute_basic_attack()
		MobileInputAction.Action.ABILITY_PRIMARY, MobileInputAction.Action.ABILITY_SECONDARY:
			var expected_id := _actor.definition.get_ability_id_for_slot(command.action)
			if expected_id == &"" or not _actor.definition.owns_ability(command.ability_id):
				return ERR_DOES_NOT_EXIST
			if command.ability_id != expected_id:
				return ERR_INVALID_PARAMETER
			return _combat.activate_ability(expected_id)
		MobileInputAction.Action.PAUSE:
			if not is_action_supported(command.action):
				return ERR_UNAVAILABLE
			pause_requested.emit()
			return OK
		MobileInputAction.Action.INTERACT:
			if not is_action_supported(command.action):
				return ERR_UNAVAILABLE
			interaction_requested.emit()
			return OK
		MobileInputAction.Action.CANCEL:
			if _active_move_source == command.source_id:
				_neutralize_movement()
			cancel_requested.emit(command.source_id)
			return OK
		MobileInputAction.Action.DODGE:
			return ERR_UNAVAILABLE
	return ERR_INVALID_PARAMETER


func _dispatch_move(command: MobileInputCommand) -> Error:
	if not is_action_supported(MobileInputAction.Action.MOVE):
		return ERR_UNAVAILABLE
	if command.phase == MobileInputAction.Phase.CANCELED:
		if _active_move_source == command.source_id:
			_neutralize_movement()
			return OK
		return ERR_DOES_NOT_EXIST
	if _active_move_source != &"" and _active_move_source != command.source_id:
		return ERR_BUSY
	_active_move_source = command.source_id
	_movement.set_move_intent(command.vector if command.phase == MobileInputAction.Phase.PERFORMED else Vector2.ZERO)
	return OK


func _is_actor_ready() -> bool:
	if not is_instance_valid(_actor) or _actor.definition == null:
		return false
	if _actor.definition.validate().size() > 0:
		return false
	var health := _actor.get_node_or_null("HealthComponent") as HealthComponent
	if health == null or health.is_dead:
		return false
	return _movement != null or _combat != null


func _neutralize_movement() -> void:
	if _movement != null:
		_movement.set_move_intent(Vector2.ZERO)
	_active_move_source = &""


func _reject(command: MobileInputCommand, reason: String, error: Error) -> Error:
	_last_rejection = reason
	if command != null:
		command_rejected.emit(command, reason)
	return error
