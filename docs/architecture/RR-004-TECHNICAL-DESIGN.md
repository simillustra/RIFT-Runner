# RR-004 — Animation Framework Technical Design

**Status:** Design baseline for implementation  
**Engine:** Godot 4.4.1 · Typed GDScript  
**Dependency:** RR-003 movement state contract  
**Related:** [RR-004 implementation specification](../backlog/RR-004-animation-framework.md), [Character Framework](CHARACTER_FRAMEWORK.md)

## 1. Decisions

1. Use Godot AnimationTree for runtime blending and state-machine playback, backed by AnimationPlayer.
2. Use a shared CharacterAnimationController Node for runtime orchestration.
3. Use typed AnimationProfile Resources for hero-specific semantic clip mappings and tuning.
4. Animation is presentation only. It never applies movement, damage, hit confirmation, cooldowns or authoritative landing.
5. Do not assume a rig, skeleton hierarchy, retargeting setup or third-party animation pack. The first implementation validates the pipeline with a documented test rig/clip set.
6. Expose movement through a read-only typed contract; never read private fields from CharacterMovementController.
7. Animation is local and deterministic; no network or AI dependencies.

## 2. Runtime scene composition

Target scene:

    CharacterActor (CharacterBody3D)
    ├── CollisionShape3D
    ├── VisualRoot (Node3D)
    │   └── CharacterModel (imported scene)
    │       └── Skeleton3D (provided by rig)
    ├── AnimationTree (AnimationTree)
    ├── MovementController (CharacterMovementController)
    └── AnimationController (CharacterAnimationController)

The imported model may own its AnimationPlayer. Do not duplicate skeletons or assume AnimationPlayer must be a direct child of CharacterActor. The controller receives exported NodePaths for AnimationTree, AnimationPlayer and movement provider, resolves them once in _ready(), and validates types.

Migration must preserve the current placeholder scene and RR-003 behavior. A missing visual rig must not prevent offline gameplay from loading; disable animation with one actionable warning.

## 3. Component contracts

### Movement provider

RR-003 currently exposes is_grounded and lane_index, but not a public planar/vertical velocity snapshot or facing contract. RR-004 needs a minimal read-only API, preferably:

    func get_animation_state() -> CharacterAnimationState

The typed state contains:
- planar_velocity: Vector3, world-space with y = 0.
- vertical_velocity: float.
- is_grounded: bool.
- movement_mode: int or shared enum.
- facing_basis: Basis or documented actor-facing transform.

The snapshot is observational only. If a value object is excessive, explicit read-only getters with identical semantics are acceptable. Do not expose private intent or jump-request flags.

### CharacterAnimationController

- Resolve and validate dependencies once.
- Read movement state at a defined update point.
- Convert velocity into actor-local blend coordinates.
- Select semantic locomotion presentation state with thresholds and hysteresis.
- Set AnimationTree parameters and travel the state machine.
- Emit presentation events for footsteps/landing where clips provide markers.
- Disable safely when optional rig resources are unavailable.

It must not call move_and_slide(), write velocity, change collisions, poll input, own the camera, validate combat hits, apply damage, manage cooldowns, perform remote calls, scan files or load resources per frame.

### AnimationProfile

Typed Resource fields:
- Stable profile_id: StringName.
- Optional skeleton_profile_id / rig compatibility key.
- Semantic state-to-animation identifiers or AnimationLibrary clip keys.
- Required and optional state declarations.
- Locomotion thresholds, hysteresis and playback-rate bounds.
- Blend-space directional calibration.
- Optional footstep marker/event names.
- Validation method returning actionable errors.

Profiles contain data, not executable gameplay logic. Reuse clips only where rig compatibility is confirmed.

## 4. Animation graph

Top-level locomotion state machine:

    Locomotion
    ├── Grounded
    │   ├── Idle
    │   ├── Start
    │   ├── Move (BlendSpace2D: forward/back/left/right)
    │   ├── Stop
    │   └── HitReact (temporary presentation overlay or state)
    └── Airborne
        ├── JumpStart
        ├── Rising
        ├── Falling
        └── Landing

Sprint is a presentation variant only when an authoritative sprint state exists. RR-003 does not currently expose sprint intent/state; do not invent sprint gameplay in RR-004. Keep a disabled extension point.

Use AnimationNodeStateMachinePlayback for semantic transitions and AnimationNodeBlendSpace2D for directional movement. Centralize node names and parameter paths; test them against an AnimationTree fixture. Author graph resources as .tres assets, not dynamically every frame.

Grounded truth comes from movement. Rising/falling uses vertical velocity with a configurable dead zone. Landing is entered only after grounded changes from false to true. Idle/run uses separate enter/exit thresholds. One-shot states need explicit interruption and fallback paths. HitReact must not freeze or overwrite movement.

## 5. Coordinate convention

BlendSpace2D uses actor-local planar velocity:
- X negative/positive: left/right.
- Y positive/negative: forward/backward.

Project world planar velocity onto actor-local right/forward axes. Clamp both axes to [-1, 1]. Use actual velocity, not input intent, so collisions, braking and lane transitions are reflected. Confirm the model's forward axis before implementing blend projection; do not assume camera basis equals actor facing.

## 6. Update order

1. Movement controller updates CharacterBody3D in physics.
2. Animation controller samples the resulting state in _process(), or consumes a cached post-physics snapshot.
3. AnimationTree parameters update once per frame.
4. AnimationTree evaluates blending and transitions.

Choose one sampling strategy and test it. Avoid half-updated movement state. Keep pure state mapping functions independently testable.

## 7. Events and ownership

RR-004 implements presentation events only: footstep with marker identifier, jump-takeoff visual and landing visual. Animation markers may notify audio/VFX but cannot cause jump, landing, damage, attack hit, resource consumption or ability release. RR-005 defines combat event authority.

## 8. Fallback and errors

- Missing AnimationTree or required movement provider: disable controller and report one clear error.
- Missing optional clip: use configured fallback and warn once per profile/state.
- Missing required profile mapping: fail profile validation before activation.
- Missing Skeleton3D/model: actor remains playable with animation disabled.
- Invalid parameter path/state-machine node: fail initialization; never spam errors per frame.
- No per-frame loading, filesystem scans or dynamic scene scans.

## 9. Test design

Pure tests: local velocity to directional blend; idle/run hysteresis; vertical velocity to rising/falling; airborne-to-grounded landing transition; clamping; profile required/optional fallback validation.

Scene tests: actor with animation fixture loads; dependencies and playback resolve; synthetic movement snapshots update parameters/state; missing optional rig does not crash; movement velocity, grounded state and collision settings remain unchanged.

Visual fixture: use a redistributable test-safe rig/clip set if available. Otherwise build a minimal in-engine test skeleton/clip fixture or explicitly record visual validation as blocked by asset availability. Headless tests are not proof of visual animation quality.

## 10. Milestones

| Milestone | Output | Gate |
|---|---|---|
| D1 Interface | Read-only movement snapshot and tests | RR-003 regression tests pass |
| D2 Profile | AnimationProfile and validator | Mapping tests pass |
| D3 Graph | AnimationTree state machine and parameter constants | Fixture paths resolve |
| D4 Controller | Typed controller and locomotion mapping | Pure transition tests pass |
| D5 Integration | Animation-ready actor and fallback | Actor loads with/without rig |
| D6 Hero profiles | Vanguard, Phantom, Cipher profiles | All profiles validate |
| D7 Validation | Visual fixture, CI, device report | RR-004 acceptance checklist satisfied |

## 11. Risks and open decisions

- No production rig assets are present in the inspected CharacterActor scene. Retargeting and skeleton naming remain open until licensed assets are selected.
- Sprint is not exposed by RR-003 and must remain disabled.
- Confirm actor forward axis before blend-space projection.
- Animation markers are never gameplay authority.
- Design may proceed while RR-003 device evidence is completed, but do not silently treat that validation as complete.

## 12. Design completion criteria

Scene ownership, dependency direction, read-only movement contract, state graph, parameter paths, profile schema, fallback behavior, test strategy and milestone gates are documented. No unverified production assets or rig assumptions are introduced.
