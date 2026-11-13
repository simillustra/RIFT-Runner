extends Node
## Centralized scene transitions with basic path validation.

var _transition_in_progress: bool = false


func change_scene(scene_path: String) -> Error:
	if _transition_in_progress:
		push_warning("Scene transition ignored: another transition is in progress.")
		return ERR_BUSY
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path, "PackedScene"):
		push_error("Scene does not exist or is not a PackedScene: %s" % scene_path)
		return ERR_FILE_NOT_FOUND

	_transition_in_progress = true
	EventBus.scene_change_requested.emit(scene_path)
	var result: Error = get_tree().change_scene_to_file(scene_path)
	_transition_in_progress = false
	return result
