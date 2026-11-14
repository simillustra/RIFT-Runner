# RR-004 D1 — Movement Animation State Contract

**Status:** Implemented in the RR-004 D1 branch; CI/device validation pending.

## API

`CharacterMovementController.get_animation_state() -> CharacterAnimationState` returns a detached snapshot with:

- `planar_velocity: Vector3` — actor world-space X/Z velocity with Y forced to zero.
- `vertical_velocity: float` — actor world-space vertical velocity.
- `is_grounded: bool` — controller's latest grounded result.
- `movement_mode: int` — value from `CharacterMovementController.MovementMode`.
- `facing_basis: Basis` — actor's global transform basis at snapshot time.

`CharacterAnimationState` is a typed RefCounted value object. It contains copied values and has no reference back to the actor/controller. It is read-only by contract: consumers may inspect it, but must not use it to mutate gameplay state. A newly requested snapshot reflects the latest actor/controller values.

If the movement controller has not resolved its CharacterBody3D parent, the getter returns a safe zero-velocity/default-basis snapshot while preserving the controller's current grounded and movement-mode values.

## Ownership

The movement controller remains the only owner of movement physics and grounded state. Animation/presentation consumers must treat the snapshot as input-only. This API does not expose move intent, queued jump requests, internal actor references or mutable controller configuration.

## Tests

`tests/movement_test.gd` verifies snapshot type, planar/vertical separation, grounded state, movement mode, facing basis and snapshot detachment, alongside existing RR-003 regression checks.

Run after editor import/class registration:

```sh
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/movement_test.gd
```

The implementation is not considered validated until the repository CI runs these commands successfully.