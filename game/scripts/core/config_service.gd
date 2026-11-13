extends Node
## Typed-access configuration facade. Settings persist in user://settings.cfg.

const SETTINGS_PATH: String = "user://settings.cfg"
const SECTION: String = "settings"

var _values: Dictionary = {
	"master_volume": 1.0,
	"music_volume": 0.8,
	"sfx_volume": 1.0,
	"vibration_enabled": true,
	"graphics_preset": "balanced",
}


func _ready() -> void:
	load_settings()


func get_setting(key: String, fallback: Variant = null) -> Variant:
	return _values.get(key, fallback)


func set_setting(key: String, value: Variant) -> Error:
	_values[key] = value
	var config := ConfigFile.new()
	var load_error: Error = config.load(SETTINGS_PATH)
	if load_error != OK and load_error != ERR_FILE_NOT_FOUND:
		return load_error
	for setting_key: Variant in _values:
		config.set_value(SECTION, str(setting_key), _values[setting_key])
	var save_error: Error = config.save(SETTINGS_PATH)
	if save_error == OK:
		EventBus.settings_changed.emit(key, value)
	return save_error


func load_settings() -> Error:
	var config := ConfigFile.new()
	var error: Error = config.load(SETTINGS_PATH)
	if error == ERR_FILE_NOT_FOUND:
		return OK
	if error != OK:
		push_warning("Could not load settings.cfg (error %d)." % error)
		return error
	for key: Variant in _values.keys():
		_values[key] = config.get_value(SECTION, str(key), _values[key])
	return OK
