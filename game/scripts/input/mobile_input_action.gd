extends RefCounted
class_name MobileInputAction
## Semantic action vocabulary shared by guided and free-hand mobile controls.
## Input devices must translate physical gestures into these actions; gameplay
## systems remain authoritative for movement and combat.

enum Action {
	MOVE,
	JUMP,
	LANE_LEFT,
	LANE_RIGHT,
	DODGE,
	BASIC_ATTACK,
	ABILITY_PRIMARY,
	ABILITY_SECONDARY,
	INTERACT,
	PAUSE,
	CANCEL,
}

enum Mode {
	GUIDED,
	FREE_HAND,
}

enum Phase {
	STARTED,
	PERFORMED,
	CANCELED,
}


static func action_name(action: int) -> StringName:
	match action:
		Action.MOVE: return &"move"
		Action.JUMP: return &"jump"
		Action.LANE_LEFT: return &"lane_left"
		Action.LANE_RIGHT: return &"lane_right"
		Action.DODGE: return &"dodge"
		Action.BASIC_ATTACK: return &"basic_attack"
		Action.ABILITY_PRIMARY: return &"ability_primary"
		Action.ABILITY_SECONDARY: return &"ability_secondary"
		Action.INTERACT: return &"interact"
		Action.PAUSE: return &"pause"
		Action.CANCEL: return &"cancel"
	return &"unknown"
