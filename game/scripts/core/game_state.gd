extends Node
## Minimal application-level state. Gameplay state belongs to gameplay systems.

enum Phase {
	BOOT,
	MENU,
	LOADING,
	PLAYING,
	PAUSED,
	RESULTS,
}

var current_phase: Phase = Phase.BOOT
var is_initialized: bool = false


func set_phase(next_phase: Phase) -> void:
	if current_phase == next_phase:
		return
	var previous_phase: Phase = current_phase
	current_phase = next_phase
	EventBus.game_phase_changed.emit(previous_phase, next_phase)


func mark_initialized() -> void:
	is_initialized = true
	if current_phase == Phase.BOOT:
		set_phase(Phase.MENU)
