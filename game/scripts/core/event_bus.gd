extends Node
## Global typed signals for cross-system notifications.
## Keep gameplay ownership local; use this bus only for decoupled events.

signal game_phase_changed(previous_phase: int, next_phase: int)
signal scene_change_requested(scene_path: String)
signal settings_changed(setting_key: String, value: Variant)
signal save_completed(success: bool)
