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
		game_state.mark_initialized()
		_check(game_state.is_initialized, "GameState initializes")
		_check(game_state.current_phase == game_state.Phase.MENU, "boot transitions to menu")

	if root.has_node("SaveService"):
		var save_service: Node = root.get_node("SaveService")
		var sample: Dictionary = {"rr001_smoke": true, "schema": 1}
		var save_error: Error = save_service.save_game(sample)
		_check(save_error == OK, "save service writes local data")
		var loaded: Dictionary = save_service.load_game()
		_check(loaded.get("rr001_smoke", false) == true, "save service reads local data")

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
