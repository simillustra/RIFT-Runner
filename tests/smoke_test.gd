extends SceneTree
## Built-in headless foundation smoke test; no third-party test addon required.

var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
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

	if failures == 0:
		print("RR-001 smoke test: PASS")
		quit(0)
	else:
		push_error("RR-001 smoke test: %d failure(s)" % failures)
		quit(1)


func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		failures += 1
		push_error("FAIL: %s" % description)
