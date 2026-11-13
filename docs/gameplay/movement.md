# Movement Design

**Owner:** RR-003 (in progress).

## Goal
Implement a deterministic, testable third-person movement controller for CharacterActor. Support lane-aware traversal as the default runner mode while preserving camera-basis-relative free movement as an explicit controller mode. Movement is local/offline and never depends on network or remote AI services.

## Implemented foundation
CharacterMovementController is a dedicated child Node of CharacterActor. It owns movement intent, lane selection, jump requests, movement configuration, grounded state and physics integration. It uses CharacterBody3D.move_and_slide() during physics ticks.

## Responsibilities
- Separate movement intent/input sampling from physics execution.
- Apply acceleration/deceleration, gravity, jump and grounded/airborne state.
- Support lane targeting with configurable odd lane count, lane width and bounded transitions.
- Support camera-basis-relative planar movement when free-movement mode is selected.
- Expose movement state/signals for later camera and animation consumers without implementing animation or combat.
- Keep tuning configurable and validate invalid settings defensively.

## Constraints
- Use CharacterBody3D and move_and_slide() in the physics tick.
- Use typed GDScript and delta-time-based acceleration.
- No remote AI, Nakama, save-data or network state in the movement loop.
- No dodge, combat, abilities, obstacle traversal, camera rig, animation state machine, procedural level logic or mobile gesture UI in RR-003.
- CharacterStats.movement_speed is read as baseline speed; shared Resource assets are never mutated.
- Lane mode moves laterally toward lane centers; lane changes may be requested while airborne.
- Free mode uses a supplied camera Basis and normalized planar intent.

## Prototype defaults
Three lanes, 2.0 m lane width, movement speed from CharacterStats (fallback 5.0), lateral transition speed 10 m/s, acceleration 18 m/s², braking 24 m/s², jump velocity 6.5 m/s and gravity 18 m/s². These are prototype tuning values, not final balance.

## Remaining RR-003 work
Exercise physics-step behavior in Godot CI/device runtime; refine floor/ground detection and test jump/gravity/acceleration against a deterministic physics fixture. Validate on mobile hardware before tuning for production.
