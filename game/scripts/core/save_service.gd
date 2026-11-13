extends Node
## Versioned local save foundation. Do not store credentials or platform secrets here.

const SAVE_PATH: String = "user://profile_save.json"
const SAVE_VERSION: int = 1


func save_game(payload: Dictionary) -> Error:
	var document: Dictionary = {
		"version": SAVE_VERSION,
		"payload": payload,
	}
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Unable to open save file for writing (error %d)." % FileAccess.get_open_error())
		EventBus.save_completed.emit(false)
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(document, "\t"))
	var error: Error = file.get_error()
	file.close()
	EventBus.save_completed.emit(error == OK)
	return error


func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("Unable to open save file (error %d)." % FileAccess.get_open_error())
		return {}
	var raw: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(raw)
	if not parsed is Dictionary:
		push_warning("Save file is invalid JSON or has an unexpected root type.")
		return {}
	var document: Dictionary = parsed
	if int(document.get("version", -1)) != SAVE_VERSION:
		push_warning("Save version is unsupported; ignoring existing save.")
		return {}
	var payload: Variant = document.get("payload", {})
	return payload if payload is Dictionary else {}
