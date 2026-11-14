# RR-003 D1 — Deterministic Physics Fixture

**Status:** Implemented; CI verification pending  
**Scope:** Establish a repeatable fixture using Godot's real `CharacterBody3D` collision solver.

## Fixture

`tests/movement_physics_fixture_test.gd` builds a known scene in code:
- A `StaticBody3D` floor with a `BoxShape3D` collision shape.
- A real `CharacterBody3D` with a `CapsuleShape3D`.
- The production `CharacterMovementController` attached to that body.
- Godot physics frames are awaited at the configured project physics tick rate; no mocked floor state or fabricated collision result is used.

## Assertions

- The controller is owned by the real character body.
- The body settles onto the floor at the expected capsule contact height.
- The controller detects grounded state and emits one grounded transition.
- Downward velocity is resolved by floor contact while grounded.
- Moving the body away from the floor causes it to become airborne.
- Gravity produces downward velocity while airborne.
- Grounded/airborne transitions emit once per transition.

## Run locally

```sh
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/movement_physics_fixture_test.gd
```

CI runs this test after editor import and the existing movement regression test.

## Boundaries

D1 establishes the physics fixture and verifies floor contact, grounded-state transitions and gravity. It does **not** close jump launch/airborne jump rejection, lane convergence, free movement, invalid delta/configuration, production actor integration, slopes or device validation. Those remain separate RR-003 acceptance items. A successful headless test is not evidence of mobile-device performance.
