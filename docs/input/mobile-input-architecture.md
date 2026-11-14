# Mobile Input Architecture

**Status:** RR-006 D1-D2 baseline. The guided fixed-position virtual joystick is implemented; free-hand recognizers and the gameplay router remain deferred.

## Goals

- Support the two product control modes: **Guided** (virtual joystick and explicit action controls) and **Free-hand** (gesture-driven).
- Translate device-specific events into a stable, device-neutral semantic action vocabulary.
- Keep movement, combat, abilities, game state and character health authoritative in their existing gameplay systems.
- Make gesture grammar configurable and testable; do not freeze unvalidated gesture meanings in the input contract.
- Keep input processing local and deterministic. No remote AI, network dependency or asynchronous service is permitted in the input-to-gameplay path.

## Layers and ownership

1. **Device recognizers (RR-006 D2-D4):** joystick, touch, swipe and press recognizers. They own pointer tracking, thresholds, gesture classification and cancellation.
2. **Semantic command (D1):** `MobileInputCommand` carries action, phase, mode, normalized movement vector, strength, optional ability ID, source ID and monotonic sequence ID. It contains intent only.
3. **Input router (later RR-006 milestone):** validates commands, applies context/priority policy, and dispatches supported actions to gameplay interfaces. It must not contain movement physics, attack timing or ability effects.
4. **Gameplay authorities:** `CharacterMovementController` owns movement requests; `HeroCombatController` owns basic attack and ability acceptance/cooldowns; game-state systems own pause/menu state.
5. **Presentation:** HUD, animation and VFX observe gameplay state; they do not reinterpret raw touch input.

## Semantic action vocabulary

| Action | Payload | Intended gameplay endpoint | Notes |
|---|---|---|---|
| MOVE | normalized Vector2 | CharacterMovementController.set_move_intent | Zero vector means neutral/released |
| JUMP | none | CharacterMovementController.request_jump | Buffered/edge policy is a later milestone |
| LANE_LEFT | none | CharacterMovementController.request_lane_change(-1) | Relevant in lane mode |
| LANE_RIGHT | none | CharacterMovementController.request_lane_change(1) | Relevant in lane mode |
| DODGE | none | Future dodge gameplay interface | Reserved; not implemented by D1 |
| BASIC_ATTACK | none | HeroCombatController.execute_basic_attack | Existing combat authority |
| ABILITY_PRIMARY | ability_id | HeroCombatController.activate_ability | ID comes from hero definition/configuration |
| ABILITY_SECONDARY | ability_id | HeroCombatController.activate_ability | ID comes from hero definition/configuration |
| INTERACT | none | Future interaction interface | Reserved |
| PAUSE | none | GameState / pause flow | Must be blocked or handled by context policy |
| CANCEL | none | Active recognizer/router context | Cancels the originating input, not gameplay state by itself |

The vocabulary is deliberately broader than the current gameplay implementation. Reserved actions must return an explicit unsupported result until their gameplay endpoint exists; they must never silently succeed.

## Command contract

- `action`, `phase`, and `mode` use the enums in `MobileInputAction`.
- `phase` is STARTED, PERFORMED or CANCELED. Recognizers must emit CANCELED when a tracked touch is interrupted, focus is lost, the app is paused, or the pointer leaves a valid control region.
- MOVE uses a finite Vector2 with length at most 1.0. The router may clamp small floating-point tolerance but must reject NaN/infinity.
- `strength` is finite and in [0, 1].
- Ability actions require a non-empty stable `ability_id`; the router must verify that the selected hero actually owns it through HeroCombatController.
- `source_id` identifies the recognizer/control (for example, joystick_left or gesture_swipe); it is diagnostic, not an authority.
- `sequence_id` is non-negative and monotonically increasing per input source. It is not wall-clock time and must not be used for gameplay timing.
- Non-MOVE actions carry a zero vector. Commands are validated before dispatch.
- A CANCELED MOVE command must neutralize that source's movement contribution. Later router work must define multi-source arbitration so releasing one finger cannot cancel another active source.

## Action mapping contract

| Control mode | Input | Semantic command |
|---|---|---|
| Guided | virtual joystick | MOVE |
| Guided | explicit jump control | JUMP |
| Guided | explicit dodge control | DODGE |
| Guided | attack control | BASIC_ATTACK |
| Guided | configured ability controls | ABILITY_PRIMARY / ABILITY_SECONDARY |
| Free-hand | directional swipe / drag | MOVE or lane action according to the approved gesture profile |
| Free-hand | tap / multi-tap / press gesture | Configured semantic action; mapping remains playtest-configurable |
| Either | pause/menu control | PAUSE / CANCEL |

This table defines the translation boundary, not the final gesture grammar. Exact swipe directions, tap counts, hard-press availability, gesture timing windows and conflict precedence require device validation and usability playtesting before they become defaults.

## Context, priority and lifecycle rules

- Input is accepted only while the game context allows gameplay input. Pause, menus, dialogs, loading, death and scene transitions must suppress gameplay commands.
- UI-consumed touches must not leak into gameplay recognizers.
- One physical gesture must produce at most one terminal semantic action unless a profile explicitly defines a compound gesture.
- Recognizers must track pointer IDs; multi-touch ownership must be explicit.
- On focus loss, app suspension, scene change, mode switch or control destruction: cancel active recognizers and emit neutral movement for their sources.
- The router must not call movement/combat internals directly; it uses their public request APIs.
- Input commands are processed on the main gameplay thread. No remote calls, awaits, frame-delayed network responses or AI inference.
- Input mode changes are atomic: cancel active commands from the old mode, neutralize movement, then enable the new mode.

## Guided virtual joystick (D2)

- `VirtualJoystick` is a reusable `Control` scene with a fixed center and radial knob.
- It owns one pointer at a time; the first pointer to begin inside its rect owns the control until release/cancel. Additional fingers cannot steal it.
- The output is a normalized Vector2: screen-right is +X and screen-up is +Y, matching the movement controller's local input convention.
- Radial deadzone suppresses accidental drift; the knob clamps to the configured base radius and the output rescales the remaining travel to [0, 1].
- It emits `MobileInputCommand` MOVE events with STARTED, PERFORMED and CANCELED phases, a stable source ID and monotonic sequence IDs. Release, focus loss and tree exit emit a zero-vector cancellation.
- The joystick emits intent only. A later input router (D5/D7) will arbitrate sources and forward accepted MOVE commands to `CharacterMovementController.set_move_intent`.
- The scene is deliberately unanchored; the HUD/layout milestone positions it for device safe areas.

## Non-goals for D1/D2

No joystick UI, gesture recognizer, input buffering, aim assist, haptics, settings screen, device-specific pressure dependency, gameplay dodge implementation or final gesture grammar.

## Planned implementation sequence

- D1: semantic contract, architecture, mapping and CI contract tests.
- D2: guided virtual joystick and movement source lifecycle.
- D3: free-hand directional swipe/drag recognizer.
- D4: tap, double-tap, long/hard-press and triple-tap recognizer with conflict policy.
- D5: gameplay action routing to movement/combat/abilities and hero capability validation.
- D6: mode switching, context suppression, settings and accessibility.
- D7: multi-source arbitration, buffering and lifecycle hardening.
- D8: automated integration tests, device validation and performance baseline.
