# Mobile Input Architecture

**Status:** RR-006 D1-D6 implementation baseline. Guided joystick, free-hand swipe/drag, tap/press recognition, gameplay routing and local mode/context/settings management are implemented in the stacked feature series. Multi-source arbitration and device acceptance remain open.

## Goals

- Support Guided and Free-hand controls through a device-neutral semantic action vocabulary.
- Keep movement, combat, abilities, game state and health authoritative in existing gameplay systems.
- Keep gesture grammar configurable and deterministic.
- Keep input processing local. No remote AI, network dependency or asynchronous service in the input-to-gameplay path.

## Layers and ownership

1. Device recognizers (D2-D4) own pointer tracking and gesture classification.
2. `MobileInputCommand` (D1) carries action, phase, mode, vector, strength, optional ability ID, source ID and monotonic sequence ID.
3. `MobileInputRouter` (D5) validates commands, checks hero capability and dispatches to public gameplay APIs.
4. `MobileInputContextController` (D6) owns mode selection, gameplay context suppression, registered recognizer lifecycle and player settings. It gates the router; it does not replace gameplay validation.
5. `CharacterMovementController` owns movement requests; `HeroCombatController` owns attack and ability acceptance/cooldowns; game-state and interaction systems own pause and interaction behavior.
6. HUD, animation and VFX observe gameplay state; they do not reinterpret raw touch input.

## Action routing

| Semantic action | D5 destination | Capability rule |
|---|---|---|
| MOVE | `CharacterMovementController.set_move_intent` | Free movement mode only |
| JUMP | `CharacterMovementController.request_jump` | Movement controller must exist |
| LANE_LEFT / LANE_RIGHT | `request_lane_change(-1/+1)` | Lane movement mode only |
| BASIC_ATTACK | `HeroCombatController.execute_basic_attack` | Hero must define a valid basic attack |
| ABILITY_PRIMARY / SECONDARY | `HeroCombatController.activate_ability` | Explicit slot ID must match an ability owned by active hero |
| PAUSE | `pause_requested` signal | Game-state owner handles pause |
| INTERACT | `interaction_requested` signal | Interaction owner must be connected |
| CANCEL | `cancel_requested` signal | Clears this source's active movement contribution |
| DODGE | Not implemented | Returns `ERR_UNAVAILABLE` |

## D6 modes and contexts

- Modes are `GUIDED` and `FREE_HAND`. Every registered Control is associated with exactly one mode.
- Only the selected mode's controls are visible, process input and receive pointer interaction.
- Contexts are `GAMEPLAY`, `PAUSED`, `MENU`, `DIALOG`, `LOADING`, `DEAD`, `TRANSITION` and `CUTSCENE`. Only GAMEPLAY enables the gameplay router and recognizers.
- A mode/context transition cancels all active recognizers while the old router state can still receive cancellation, disables routing (which neutralizes movement), updates state and control visibility, then enables the router only if the resulting context is GAMEPLAY.
- A command is accepted only when its registered control mode, command mode and active mode agree. Commands from stale/inactive modes are rejected.
- UI/game-state owners must call `set_context` on pause, menu, dialog, loading, death, transition and cutscene entry/exit. The controller is the authoritative gate for the input stack.

## Settings and accessibility

`MobileInputSettings` validates and persists:
- Left/right joystick-side preference, exposed through `left_handed_layout_requested` for the HUD safe-area layout owner.
- Joystick scale and radial deadzone.
- Swipe/drag sensitivity.
- Long-press and multi-tap timing.
- High-contrast joystick rendering.

Settings are stored locally with Godot `ConfigFile` at `user://mobile_input_settings.cfg`. Invalid settings are rejected. User overrides are applied to duplicated gesture profiles so shared default Resources are not mutated. The HUD must consume the handedness signal and position controls inside platform safe areas; the context controller does not assume screen dimensions.

Haptics, remappable action layouts, screen-reader narration and automated focus navigation are not implemented by D6 and must not be represented as supported accessibility features.

## Validation and lifecycle

- Validate command enum values, finite payloads, vector bounds, ability IDs and source IDs before dispatch.
- Enforce strictly increasing sequence IDs per source to reject stale/replayed commands.
- Require a valid active CharacterDefinition and living HealthComponent.
- Disabling gameplay input rejects commands and neutralizes active movement.
- D5 permits one MOVE source at a time. A competing source receives `ERR_BUSY`; D7 will introduce deterministic multi-source arbitration.
- Unsupported actions and missing integration owners return explicit errors.
- Recognizers emit intent only; they do not call gameplay controllers or mutate physics.

## Implemented sequence

- D1: semantic command contract and CI tests.
- D2: guided virtual joystick.
- D3: free-hand directional swipe/drag recognizer.
- D4: tap/press recognition.
- D5: gameplay action routing and hero capability validation.
- D6: atomic mode switching, gameplay context suppression, local settings and accessibility preferences.
- D7: multi-source movement arbitration, input buffering and lifecycle hardening.
- D8: integrated automated validation, Android/iOS device acceptance and performance baseline.
