# RR-003 D2 — Jump and Grounded Physics

**Status:** Implemented; GitHub Actions verification pending  
**Depends on:** RR-003 D1 real-physics fixture

## Behavior

- A jump request is consumed on the next movement physics tick.
- A jump launches only when the real `CharacterBody3D` is grounded.
- A jump request received while airborne is discarded; it does not reset upward velocity or create a second launch.
- Gravity is applied while airborne. While grounded, negative vertical velocity is cleared and gravity is not accumulated.
- The existing `grounded_changed` signal continues to emit only when the controller's grounded state changes, including takeoff and landing.

## Deterministic fixture

`tests/movement_jump_physics_test.gd` uses a real `CharacterBody3D`, capsule collision shape, static floor and production `CharacterMovementController`. It awaits actual Godot physics frames and checks:

1. Initial floor contact and one grounded transition.
2. Downward velocity resolution and stable vertical velocity while standing.
3. Grounded jump launch at the configured `jump_velocity`.
4. Takeoff transition to airborne.
5. Airborne jump rejection while gravity continues from the prior upward velocity.
6. Landing and exactly one grounded transition.
7. Stable grounded state without repeated transition signals.

The test uses a bounded landing wait rather than assuming an exact frame count for the full jump arc.

## Validation

CI runs the D2 script after the D1 physics fixture. Run after editor import:

```sh
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/movement_jump_physics_test.gd
```

## Scope boundary

D2 does not complete lane boundary/convergence physics, free-camera movement assertions, invalid delta/ownership tests, production actor integration, slopes or mobile device validation. Those remain open RR-003 acceptance work. Headless physics CI is not device evidence.
