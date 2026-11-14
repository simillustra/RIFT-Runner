# RR-004 — Animation Framework Implementation Specification

**Priority:** P0  
**Status:** Ready for implementation after RR-003 formal acceptance  
**Dependency:** RR-003 Movement Engine  
**Engine:** Godot 4.4.1  
**Language:** Typed GDScript  
**Target:** Mobile-first, third-person action-survival runner

## 1. Objective

Deliver a data-driven, reusable character animation framework that translates authoritative character and movement state into smooth animation playback. It must support the three initial heroes — Vanguard, Phantom and Cipher — without embedding hero-specific branching in the shared animation controller.

Animation is presentation. It must not become the source of truth for movement, combat, health, input or gameplay state.

## 2. Scope

### Included

- Shared animation controller component for the character actor.
- AnimationTree-based playback and a documented AnimationNodeStateMachine.
- Locomotion states: Idle, Start, Run, Sprint, Stop, JumpStart, Rising, Falling, Landing and HitReact.
- Directional locomotion blending for forward, backward and lateral movement where supported by the supplied animation set.
- Grounded/airborne transitions driven by movement state, not animation guesses.
- Parameterized playback speed and blend values.
- Hero-specific animation resources/profiles for Vanguard, Phantom and Cipher.
- Animation event interface for future combat, ability, footstep and VFX integration.
- Safe fallback behavior when an animation clip or optional profile is missing.
- Headless validation of resources, state transitions and controller integration.
- Documentation of state graph, parameters, event naming and asset import conventions.

### Excluded

- Authoring or purchasing final production character animations.
- Combat combo design, hitbox timing, weapon trails and ability choreography (RR-005).
- Mobile gesture/joystick implementation (RR-006).
- Camera rig and camera shake (separate camera workstream).
- Multiplayer animation replication (RR-012/RR-013).
- Runtime AI animation generation or remote AI calls.
- Full cinematic, facial animation, ragdoll and motion-matching systems.

## 3. Architecture and ownership

Recommended scene ownership:

```text
CharacterActor (CharacterBody3D)
├── VisualRoot (Node3D)
│   ├── Skeleton3D
│   └── AnimationPlayer
├── AnimationTree
├── MovementController
└── AnimationController
```

The exact node paths may follow the final character scene and imported rig, but must be centralized/configurable rather than duplicated across scripts.

Responsibilities:

- `CharacterMovementController`: authoritative velocity, grounded state, lane/free movement and movement mode.
- `CharacterAnimationController`: reads movement/character state and writes AnimationTree parameters; it does not move the actor.
- `AnimationProfile` resource: maps semantic animation states and blend parameters to clips/node paths for a character rig.
- `CharacterDefinition`: identifies the selected hero/profile reference or a stable profile key; avoid hard-coded hero checks in the shared controller.
- `AnimationPlayer`/AnimationTree: playback and blending only.

Use typed signals or a small typed state interface to expose required movement values. Avoid direct cyclic dependencies. If a node path is configurable, validate it during initialization and produce a useful error.

## 4. State model

Minimum semantic states:

| State | Entry condition | Exit condition |
|---|---|---|
| Idle | Grounded and planar speed below idle threshold | Movement exceeds threshold or airborne |
| Start | Grounded movement begins from idle | Start clip completes or locomotion blend takes over |
| Run | Grounded planar speed above run threshold | Idle, Sprint, Stop or airborne |
| Sprint | Sprint intent enabled and speed above sprint threshold | Run, Stop or airborne |
| Stop | Grounded movement intent released while decelerating | Idle or movement resumes |
| JumpStart | A valid jump launch is reported | Rising phase |
| Rising | Airborne and vertical velocity above positive threshold | Apex/Falling |
| Falling | Airborne and vertical velocity at/below falling threshold | Landing |
| Landing | Ground contact regained after airborne state | Idle/Run/Sprint |
| HitReact | Explicit gameplay presentation event | Previous locomotion/air state resumes safely |

Thresholds and transition durations must be exported/configurable with sensible validated defaults. Do not use animation clip completion as the authoritative signal for landing or jump physics.

## 5. AnimationTree parameter contract

Create a centralized parameter-path map and document exact paths. Minimum logical parameters:

- `locomotion/blend_position`: Vector2 for directional locomotion.
- `locomotion/playback_rate`: float, clamped to a safe configured range.
- `conditions/is_grounded`: bool.
- `conditions/is_moving`: bool.
- `conditions/is_sprinting`: bool.
- `conditions/is_rising`: bool.
- `conditions/is_falling`: bool.
- `conditions/landed`: one-shot trigger or explicit state transition.
- `conditions/hit_react`: explicit presentation trigger.

These are logical names; implementation must map them to valid AnimationTree parameter paths and verify paths before writing. Avoid scattering string literals across gameplay scripts.

## 6. Movement integration contract

Read, do not own, the following movement facts:

- Planar velocity and normalized movement direction.
- Vertical velocity.
- Grounded state.
- Movement mode (lane/free) if useful for presentation.
- Sprint state only when a future sprint system exposes it.

Derive animation blend from velocity relative to the character's facing basis, not from raw input alone. Normalize/clamp blend values. Use hysteresis or separate enter/exit thresholds to prevent rapid state flicker near zero speed.

If RR-003 currently lacks a required read-only property or signal, propose the smallest typed interface addition and keep it backward-compatible. Do not silently reach into private controller variables.

## 7. Animation events

Provide a typed, presentation-only event surface for future systems. Initial event identifiers may include:

- `footstep_left`, `footstep_right`
- `jump_takeoff`, `landing`
- `attack_windup`, `attack_impact`, `attack_recovery`
- `ability_start`, `ability_release`

For RR-004, only locomotion events need active implementation. Combat/ability identifiers are reserved contract names and must not trigger gameplay effects until RR-005 owns those behaviors.

Events must not be used to determine whether a jump succeeded, whether damage occurred, or whether an ability is ready. Gameplay systems own those outcomes.

## 8. Resource and asset requirements

- Define a typed `AnimationProfile` Resource with stable profile ID and semantic state-to-animation mapping.
- Validate required locomotion entries and referenced clips/node paths.
- Allow optional clips to fall back to a neutral/default animation without crashing.
- Keep imported source assets immutable; document import settings and naming conventions.
- Do not commit licensed third-party animation assets without confirming project usage rights.
- Avoid duplicate copies of shared animation clips across hero profiles where compatible rigs permit reuse.

## 9. Performance and resilience

- No per-frame resource loading, filesystem scans or network requests.
- Cache AnimationTree, AnimationPlayer and parameter references during setup.
- Do not allocate large temporary collections every frame.
- Clamp playback speed and blend values.
- Missing optional clips produce a warning once; missing required nodes/profile data fail validation clearly.
- Animation must not change collision shape, CharacterBody3D velocity or authoritative gameplay state.

## 10. Test plan

### Unit/resource tests

- [ ] Valid profile loads and validates.
- [ ] Missing required state mapping is rejected with a useful diagnostic.
- [ ] Missing optional mapping uses documented fallback.
- [ ] Invalid parameter paths are detected before runtime writes.
- [ ] Playback speed and blend values are clamped.

### State-transition tests

- [ ] Grounded stationary actor selects Idle.
- [ ] Grounded movement selects Run and updates directional blend.
- [ ] Movement release selects Stop then Idle without flicker.
- [ ] Sprint state is selected only when sprint intent and speed contract are both valid.
- [ ] JumpStart transitions to Rising and then Falling based on movement facts.
- [ ] Landing occurs only after movement reports grounded following airborne state.
- [ ] HitReact returns to the appropriate locomotion/air state.
- [ ] Rapid state changes do not leave the AnimationTree in an invalid state.

### Integration and regression

- [ ] CharacterActor scene loads with animation controller and profile.
- [ ] Vanguard, Phantom and Cipher each resolve a valid profile.
- [ ] Animation controller never changes movement velocity or grounded state.
- [ ] Headless tests pass on Godot 4.4.1 CI after editor import/class registration.
- [ ] A visual test scene demonstrates every implemented transition.
- [ ] No missing-resource, invalid-node-path or AnimationTree runtime errors.

### Device validation

- [ ] Validate on representative low/mid-tier and high-tier Android devices.
- [ ] Record FPS, frame-time spikes, memory behavior and animation transition defects.
- [ ] Verify visual quality and blend behavior at target frame rates.
- [ ] Confirm imported animation compression/retargeting settings are documented.

## 11. Deliverables

1. `AnimationProfile` typed resource and validation.
2. `CharacterAnimationController` typed component.
3. AnimationTree state-machine template and parameter-path contract.
4. Updated CharacterActor integration or a dedicated animation-ready scene.
5. Profiles for Vanguard, Phantom and Cipher (placeholder clips allowed if final assets are unavailable).
6. Automated resource/state/integration tests.
7. Visual animation test scene.
8. `docs/gameplay/animation.md` and architecture updates.
9. CI evidence and device-validation report.

## 12. Acceptance criteria

RR-004 is accepted only when:

- All required deliverables exist and are documented.
- Automated tests cover required profile validation and state transitions.
- Godot 4.4.1 CI import, smoke and animation tests pass.
- The visual test scene demonstrates all implemented locomotion transitions without runtime errors.
- All three hero profiles validate, even if approved placeholder clips are used.
- Animation presentation does not mutate authoritative movement/gameplay state.
- Device validation results and known limitations are recorded.
- PR review confirms scope boundaries and no unrelated RR-005/RR-006 work has leaked into the implementation.

## 13. Suggested implementation sequence

1. Inspect final RR-003 actor/controller API and settle a read-only movement-state contract.
2. Add AnimationProfile resource and validators.
3. Add AnimationTree template and centralized parameter paths.
4. Implement CharacterAnimationController with idle/run/air/landing transitions.
5. Add directional blending, stop/start and sprint-ready extension points.
6. Add hero profiles and fallback behavior.
7. Add deterministic headless tests and visual test scene.
8. Run CI, fix import/runtime warnings, capture device validation.
9. Update backlog and submit a draft PR for review.
