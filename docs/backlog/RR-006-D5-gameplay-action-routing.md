# RR-006 D5 — Gameplay Action Routing and Hero Capability Validation

## Objective
Route validated semantic input commands into existing gameplay authorities and validate the selected hero's supported actions before dispatch.

## Architecture
- `MobileInputRouter` receives `MobileInputCommand` objects from recognizers.
- It validates command schema, per-source monotonic sequence IDs, gameplay-input enablement, active hero definition and health.
- It dispatches through public APIs only:
  - MOVE / JUMP / LANE_LEFT / LANE_RIGHT → `CharacterMovementController`.
  - BASIC_ATTACK / ABILITY_PRIMARY / ABILITY_SECONDARY → `HeroCombatController`.
  - PAUSE / INTERACT → integration signals consumed by game-state or interaction owners.
  - CANCEL → clears movement owned by the originating source and emits a cancellation signal.
- Hero `CharacterDefinition` now declares explicit primary and secondary ability slots. Slot IDs must refer to abilities owned by that hero; duplicate slot assignments are invalid.
- Unsupported actions (currently DODGE and unbound INTERACT/PAUSE) return an explicit error. They never silently succeed.
- No movement physics, combat timing, ability effects, network calls or AI inference are implemented in the router.

## Movement-source boundary
D5 supports one active MOVE source at a time. A different source receives `ERR_BUSY` until the active source sends CANCELED. This deliberately safe baseline prevents one recognizer from overwriting or clearing another source's movement. D7 will replace the single-source guard with deterministic multi-source arbitration and input buffering.

## Acceptance criteria
- [ ] All commands are validated before routing.
- [ ] Stale/duplicate sequence IDs are rejected per source.
- [ ] Disabled gameplay input rejects commands and neutralizes movement.
- [ ] MOVE lifecycle reaches CharacterMovementController and cancellation clears its owning source.
- [ ] JUMP and lane actions respect movement mode and use public request APIs.
- [ ] Basic attacks delegate to HeroCombatController.
- [ ] Ability slots are explicit in each hero resource and validated against owned abilities.
- [ ] Ability commands cannot invoke another hero's ability or bypass cooldown checks.
- [ ] PAUSE/INTERACT require a connected owner signal; unsupported actions return an explicit error.
- [ ] Dead/missing hero state rejects input.
- [ ] Tests cover Vanguard, Phantom and Cipher plus stale commands, source ownership, unsupported actions and context disable.
- [ ] CI imports project and runs D1-D5 tests with Godot 4.4.1.

## Test plan
1. Load all hero resources and validate their ability-slot mappings.
2. Route MOVE STARTED/PERFORMED/CANCELED and reject competing sources.
3. Route JUMP and lane changes; reject vector MOVE in lane mode.
4. Route basic attack and each hero's primary ability through combat authority.
5. Reject mismatched/unowned ability IDs, duplicate sequence IDs and unsupported DODGE.
6. Verify PAUSE/INTERACT signal integration and disabled gameplay input.
7. Run complete existing regression suite.

## Deferred
- Multi-source aggregation, source priorities and buffering: D7.
- Mode switching, menus/pause/death context ownership, settings and accessibility: D6.
- Dodge and interaction gameplay systems: later gameplay milestones.
- Physical-device latency, touch behavior and accessibility validation: D8.
