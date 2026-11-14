# RR-003 D4 — Camera-relative Free Movement Physics

**Status:** Implemented; CI verification pending  
**Depends on:** D1 real-physics fixture, D2 jump/grounded physics, D3 lane bounds and convergence

## Scope

D4 adds deterministic physics coverage for the existing FREE movement mode. It does not introduce input polling, camera ownership, animation, combat or touch UI.

## Real-physics fixture

`tests/movement_free_physics_test.gd` creates a real `CharacterBody3D`, capsule collider, static floor and production `CharacterMovementController`, then awaits Godot physics frames.

Assertions cover:

- Grounded fixture and FREE mode.
- Forward intent follows a camera basis rotated by 90 degrees.
- Camera pitch is flattened so movement remains planar.
- Cardinal and diagonal input reach the same configured run-speed magnitude.
- Diagonal components are normalized rather than producing a faster resultant velocity.
- Releasing movement intent applies braking until planar velocity settles at zero.

## Validation

CI imports the project and runs:

```sh
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/movement_free_physics_test.gd
```

## Remaining RR-003 scope

Invalid delta/configuration and actor ownership tests, production actor scene integration, representative slopes/collision arena, full regression and Android/iOS device validation remain open. D4 passing does not by itself accept RR-003.
