# RR-003 D3 — Lane Bounds and Convergence Physics

**Status:** Implemented; GitHub Actions verification pending  
**Depends on:** RR-003 D1 real-physics fixture and D2 jump physics

## Scope

D3 verifies the existing lane selection and lateral movement behavior against Godot's real `CharacterBody3D` physics solver. No new lane-control semantics are introduced.

## Deterministic fixture

`tests/movement_lane_physics_test.gd` creates a real character body with capsule collision, a static floor and the production `CharacterMovementController`. It awaits actual physics frames and checks:

- Repeated outward requests clamp at both outer lane indices.
- `lane_changed` emits once for each actual lane-index change, including intermediate lanes, and does not emit for boundary or zero-direction no-ops.
- Lateral movement converges monotonically on the left and right lane centers.
- Position does not overshoot either target center.
- Lateral velocity settles at the target center.

The fixture uses a long floor so the controller's normal forward run velocity does not leave the collision surface during the assertions.

## Validation

CI executes this script after the D1 fixture and D2 jump physics test. Run after editor import:

```sh
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/movement_lane_physics_test.gd
```

## Scope boundary

Free camera-relative movement, diagonal normalization, input release, invalid delta/configuration and actor ownership, production actor integration, slopes and mobile device validation remain open. Passing headless lane physics does not establish mobile performance or RR-003 acceptance.
