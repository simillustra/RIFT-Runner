# Mobile Input Architecture

**Status:** RR-006 D1-D5 implementation baseline. Guided joystick, free-hand swipe/drag, tap/press and deterministic gameplay action routing are implemented. Context/mode management and multi-source arbitration remain future milestones.

## Goals
- Support Guided and Free-hand controls through a device-neutral semantic action vocabulary.
- Keep movement, combat, abilities, game state and health authoritative in existing gameplay systems.
- Keep gesture grammar configurable and deterministic.
- Keep input processing local. No remote AI, network dependency or asynchronous service in the input-to-gameplay path.

## Layers and ownership
1. Device recognizers (D2-D4) own pointer tracking and gesture classification.
2. `MobileInputCommand` (D1) carries action, phase, mode, vector, strength, optional ability ID, source ID and monotonic sequence ID.
3. `MobileInputRouter` (D5) validates commands, applies the currently enabled gameplay-input gate, checks hero capability and dispatches to public gameplay APIs.
4. `CharacterMovementController` owns movement requests; `HeroCombatController` owns attack and ability acceptance/cooldowns; game-state and interaction systems own pause and interaction behavior.
5. HUD, animation and VFX observe gameplay state; they do not reinterpret raw touch input.

## Action routing
| Semantic action | D5 destination | Capability rule |
|---|---|---|
| MOVE | `CharacterMovementController.set_move_intent` | Free movement mode only |
| JUMP | `CharacterMovementController.request_jump` | Movement controller must exist |
| LANE_LEFT / LANE_RIGHT | `request_lane_change(-1/+1)` | Lane movement mode only |
| BASIC_ATTACK | `HeroCombatController.execute_basic_attack` | Hero must define a valid basic attack |
| ABILITY_PRIMARY / SECONDARY | `HeroCombatController.activate_ability` | Explicit slot ID must match an ability owned by active hero |
| PAUSE | `pause_requested` signal | Game-state owner must be connected |
| INTERACT | `interaction_requested` signal | Interaction owner must be connected |
| CANCEL | `cancel_requested` signal | Clears this source's active movement contribution |
| DODGE | Not implemented | Returns `ERR_UNAVAILABLE`; never silently succeeds |

## Validation and lifecycle
- Validate command enum values, finite payloads, vector bounds, ability IDs and source IDs before dispatch.
- Enforce strictly increasing sequence IDs per source to reject stale/replayed commands.
- Require a valid active CharacterDefinition and living HealthComponent.
- Disabling gameplay input rejects new commands and neutralizes active movement.
- D5 permits one MOVE source at a time. A competing source receives `ERR_BUSY`; the owner must cancel before another source can claim movement. This is a safe interim policy, not the final multi-source design.
- Unsupported action or missing integration owner returns an explicit error.
- The router invokes only public request methods. It contains no movement physics, attack timing, ability effects or remote calls.

## Hero capability slots
Each hero resource declares `primary_ability_id` and optional `secondary_ability_id`. The IDs must reference distinct entries in that hero's `abilities` array. The router rejects an ability command unless its ID exactly matches the requested slot and is owned by the active hero.

## Recognizer contracts
- D2 virtual joystick emits normalized MOVE commands with source and sequence metadata.
- D3 swipe/drag recognizer emits configured semantic commands or normalized MOVE.
- D4 tap/press recognizer delays multi-tap classification to resolve tap conflicts and emits discrete semantic commands.
- Recognizers emit intent only; they do not call gameplay controllers or mutate physics.

## Deferred
- D6: atomic mode switching, full gameplay context ownership, settings and accessibility.
- D7: multi-source movement arbitration, deterministic priorities, input buffering and lifecycle hardening.
- D8: integrated automated validation, Android/iOS device acceptance and performance baseline.
