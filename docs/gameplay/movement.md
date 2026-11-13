# Movement Design

**Owner:** RR-003 (in progress).

## Goal
Implement the first deterministic, testable third-person movement controller for the CharacterActor. Support lane-aware traversal as the default runner mode while preserving camera-relative free movement as an explicit controller mode. Movement is local/offline and must not depend on network or remote AI services.

## Responsibilities
- Separate movement intent/input sampling from physics execution.
- Apply acceleration/deceleration, gravity, jump and grounded/airborne state.
- Support lane targeting with configurable lane count, lane width and bounded transitions.
- Support camera-relative planar movement when free-movement mode is selected.
- Expose stable movement state/signals for later camera and animation consumers without implementing animation or combat.
- Keep tuning configurable and validate invalid settings defensively.

## Initial design constraints
- Use CharacterBody3D and move_and_slide() in the physics tick.
- Use typed GDScript and delta-time-based acceleration.
- Do not read remote AI, Nakama, save data or network state in the movement loop.
- Do not implement dodge, combat, abilities, obstacle traversal, camera rig, animation state machine, procedural level logic or mobile gesture UI in RR-003 unless separately approved.
- CharacterStats.movement_speed remains the baseline speed input; movement tuning must not mutate shared Resource assets at runtime.
- Lane mode constrains lateral position to lane centers; lane changes are bounded and may be requested while airborne. Jump is a separate vertical action.
- Free mode uses a supplied camera basis/direction and normalized planar intent.

## RR-003 acceptance criteria
- [ ] CharacterActor delegates movement to a dedicated typed controller/component or has an equally clear separation of input intent and physics execution.
- [ ] Lane mode supports configurable lane count/width, bounded lane selection and smooth lateral transitions.
- [ ] Free mode supports normalized camera-relative planar movement.
- [ ] Acceleration, braking, gravity and jump are deterministic for a fixed input/delta sequence.
- [ ] Grounded/airborne and lane state are exposed through documented read-only accessors/signals.
- [ ] Invalid configuration is rejected or safely clamped with actionable diagnostics.
- [ ] No movement code depends on network, remote AI, animation or combat.
- [ ] Headless tests cover lane bounds/transitions, movement intent normalization, jump/ground state logic and configuration validation.
- [ ] Existing foundation/character smoke test remains green.
- [ ] Docs and CI evidence are updated.

## Deferred
Animation integration (RR-004), combat and dodge (RR-005), mobile controls (RR-006), procedural world/obstacle interaction (RR-007), enemy logic (RR-008), multiplayer (RR-012/013), AI service integration (RR-014/015).

## Open tuning decisions
Initial values should be conservative defaults and exposed as configuration: lane count 3, lane width 2.0 m, run speed sourced from CharacterStats.movement_speed, lateral transition speed 10 m/s, acceleration 18 m/s², braking 24 m/s², jump velocity 6.5 m/s, gravity 18 m/s². These are prototype defaults, not final balance.
