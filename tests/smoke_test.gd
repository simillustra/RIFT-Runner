extends SceneTree
## Built-in headless smoke test for project foundation, character data and movement.

var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_foundation()
	_test_character_framework()
	_test_movement_controller()

	if failures == 0:
		print("RIFT RUNNERS smoke test: PASS")
		quit(0)
	else:
		push_error("Smoke test: %d failure(s)" % failures)
		quit(1)


func _test_foundation() -> void:
	_check(ResourceLoader.exists("res://game/scenes/bootstrap.tscn", "PackedScene"), "bootstrap scene exists")
	_check(root.has_node("EventBus"), "EventBus autoload exists")
	_check(root.has_node("GameState"), "GameState autoload exists")
	_check(root.has_node("SceneRouter"), "SceneRouter autoload exists")
	_check(root.has_node("ConfigService"), "ConfigService autoload exists")
	_check(root.has_node("SaveService"), "SaveService autoload exists")
	if root.has_node("GameState"):
		var game_state: Node = root.get_node("GameState")
		game_state.call("mark_initialized")
		_check(bool(game_state.get("is_initialized")), "GameState initializes")
		_check(int(game_state.get("current_phase")) == 1, "boot transitions to menu")
	if root.has_node("SceneRouter"):
		var scene_router: Node = root.get_node("SceneRouter")
		var missing_scene_result: int = int(scene_router.call("change_scene", "res://missing_scene.tscn"))
		_check(missing_scene_result == ERR_FILE_NOT_FOUND, "SceneRouter rejects missing scenes")
	if root.has_node("ConfigService"):
		var config_service: Node = root.get_node("ConfigService")
		var setting_error: int = int(config_service.call("set_setting", "rr001_smoke_setting", true))
		_check(setting_error == OK, "ConfigService persists a setting")
		_check(bool(config_service.call("get_setting", "rr001_smoke_setting", false)), "ConfigService reads a setting")
	if root.has_node("SaveService"):
		var save_service: Node = root.get_node("SaveService")
		var sample: Dictionary = {"rr001_smoke": true, "schema": 1}
		var save_error: int = int(save_service.call("save_game", sample))
		_check(save_error == OK, "SaveService writes local data")
		var loaded: Dictionary = save_service.call("load_game")
		_check(loaded.get("rr001_smoke", false) == true, "SaveService reads local data")


func _test_character_framework() -> void:
	var roster: CharacterRoster = load("res://game/resources/characters/hero_roster.tres") as CharacterRoster
	_check(roster != null, "hero roster resource loads")
	if roster == null:
		return
	var roster_errors: PackedStringArray = roster.validate()
	_check(roster_errors.is_empty(), "hero roster validates")
	_check(roster.characters.size() == 3, "roster contains three heroes")
	for hero_id: StringName in [&"vanguard", &"phantom", &"cipher"]:
		var hero: CharacterDefinition = roster.get_character(hero_id)
		_check(hero != null, "hero lookup resolves %s" % String(hero_id))
		if hero != null:
			_check(hero.validate().is_empty(), "%s definition validates" % String(hero_id))
			_check(hero.abilities.size() == 1, "%s has one signature ability metadata record" % String(hero_id))
	_check(roster.get_character(&"unknown_hero") == null, "unknown hero lookup returns null")
	var actor_scene: PackedScene = load("res://game/scenes/characters/character_actor.tscn") as PackedScene
	_check(actor_scene != null, "character actor scene loads")
	if actor_scene == null:
		return
	var actor: CharacterActor = actor_scene.instantiate() as CharacterActor
	_check(actor != null, "character actor scene instantiates")
	if actor == null:
		return
	var vanguard: CharacterDefinition = roster.get_character(&"vanguard")
	_check(actor.assign_definition(vanguard) == OK, "actor accepts a valid character definition")
	_check(actor.definition == vanguard, "actor retains its assigned definition")
	_check(actor.assign_definition(null) == ERR_INVALID_PARAMETER, "actor rejects a null definition")
	var invalid_definition := CharacterDefinition.new()
	_check(actor.assign_definition(invalid_definition) == ERR_INVALID_DATA, "actor rejects an invalid definition")
	actor.free()


func _test_movement_controller() -> void:
	var controller_script: Script = load("res://game/scripts/characters/character_movement_controller.gd") as Script
	_check(controller_script != null, "movement controller script loads")
	var actor_scene: PackedScene = load("res://game/scenes/characters/character_actor.tscn") as PackedScene
	if actor_scene == null:
		return
	var actor: CharacterActor = actor_scene.instantiate() as CharacterActor
	if actor == null:
		return
	var controller: CharacterMovementController = actor.get_node_or_null("MovementController") as CharacterMovementController
	_check(controller != null, "movement controller is attached to actor")
	if controller != null:
		_check(controller.validate_configuration().is_empty(), "default movement configuration validates")
		_check(controller.lane_count == 3, "default lane count is three")
		controller.request_lane_change(1)
		_check(controller.lane_index == 2, "lane change advances one lane")
		controller.request_lane_change(1)
		_check(controller.lane_index == 2, "lane change clamps at right boundary")
		controller.request_lane_change(-1)
		_check(controller.lane_index == 1, "lane change returns toward center")
		controller.set_move_intent(Vector2(1.0, 1.0))
		_check(is_equal_approx(controller._move_intent.length(), 1.0), "movement intent is normalized")
		controller.request_jump()
		_check(controller._jump_requested, "jump request is queued for physics tick")
	actor.free()


func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		failures += 1
		push_error("FAIL: %s" % description)
