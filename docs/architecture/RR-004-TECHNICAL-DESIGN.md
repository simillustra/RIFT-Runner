# RR-004 — Animation Framework Technical Design

**Status:** Implementation baseline  
**Engine:** Godot 4.4.1 · Typed GDScript  
**Dependency:** RR-003 movement state contract

## Decisions

1. Use Godot AnimationTree for runtime blending and AnimationPlayer for clip playback.
2. Use a shared CharacterAnimationController Node for runtime orchestration.
3. Use typed AnimationProfile Resources for rig-specific semantic clip mappings and tuning.
4. Animation is presentation only. It never applies movement, damage, hit confirmation, cooldowns or authoritative landing.
5. Do not assume a production rig, skeleton hierarchy, retargeting setup or third-party animation pack.
6. Expose movement through a read-only typed contract.
7. Animation is local and deterministic; no network or AI dependencies.

## Runtime scene composition

```text
CharacterActor (CharacterBody3D)
├── CollisionShape3D
├── VisualPlaceholder (or imported VisualRoot)
├── MovementController
└── AnimationIntegration (optional rig adapter)
    └── CharacterAnimationControllerRuntime (created only when rig dependencies exist)
```

The rig's AnimationPlayer and AnimationTree may be siblings under the actor or configured through exported NodePaths. A missing rig is supported, not fatal.

## Component contracts

### CharacterMovementController
Owns authoritative velocity, grounded state, lane/free movement and movement mode. Exposes a detached CharacterAnimationState snapshot.

### CharacterAnimationIntegration
- Resolves MovementController, AnimationTree, AnimationPlayer and AnimationProfile once in _ready().
- If both animation nodes are absent, stays disabled without errors.
- If rig setup is partial or required configuration is missing, emits an actionable warning and remains disabled.
- When configured, creates and owns a CharacterAnimationController and assigns typed references.
- Never mutates CharacterBody3D or movement state.

### CharacterAnimationController
Reads the movement snapshot, converts world planar velocity into actor-local blend coordinates, selects semantic animation states, and writes only AnimationTree parameters/playback.

### AnimationProfile
A typed Resource mapping semantic states to clip identifiers, fallback clip and locomotion/playback tuning. Profiles contain data, not executable gameplay logic.

## Fallback behavior

- No AnimationTree and no AnimationPlayer: integration remains disabled silently; CharacterActor and movement load normally.
- Partial rig configuration: integration remains disabled with one warning.
- Missing movement provider or profile: integration remains disabled with one warning.
- Missing production Skeleton3D/model: actor remains playable; visual quality is not implied by headless tests.
- No per-frame resource loading, filesystem scans or remote calls.

## Validation strategy

- Resource and graph tests validate profile mappings and centralized graph paths.
- D4 controller tests validate state selection and playback behavior.
- D5 integration tests validate actor loading with and without animation nodes, adapter wiring and movement-state immutability.
- D7 visual/device validation remains mandatory before RR-004 acceptance.

## Milestones

| Milestone | Output | Gate |
|---|---|---|
| D1 Interface | Read-only movement snapshot and tests | RR-003 regression tests pass |
| D2 Profile | AnimationProfile and validator | Mapping tests pass |
| D3 Graph | AnimationTree state machine and parameter constants | Fixture paths resolve |
| D4 Controller | Typed controller and locomotion mapping | Headless state tests pass |
| D5 Integration | Animation-ready actor and no-rig fallback | Actor loads with/without rig |
| D6 Hero profiles | Vanguard, Phantom, Cipher profiles | All profiles validate |
| D7 Validation | Visual fixture, CI and device report | RR-004 acceptance checklist satisfied |
