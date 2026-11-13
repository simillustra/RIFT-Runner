# RR-002 — Character Framework

**Priority:** P0  
**Status:** Merged; CI validation follow-up open  
**Merged PR:** [#2](https://github.com/simillustra/RIFT-Runner/pull/2)  
**Depends on:** RR-001 — Project Foundation (merged)

## Delivered
- Typed resources for character identity, archetype, stats and ability metadata.
- Validated roster with stable ID lookup and duplicate detection.
- CharacterBody3D actor root with capsule collision placeholder and definition assignment.
- Data assets for Vanguard, Phantom and Cipher.
- Headless smoke test for resource loading, validation, lookup and actor assignment.

## CI follow-up
The merged-head run failed while parsing tests/smoke_test.gd because the Godot global script class cache had not been generated before the test script was loaded. The workflow now performs a headless editor import/class-registration step before running the smoke test. This fix must pass on CI before RR-003 is unblocked.

## Scope boundary
No movement, camera, animation, combat, ability execution, input, progression, multiplayer or AI runtime implementation is included. Ability resources are metadata only.

## Acceptance evidence
- [x] Character resource and actor implementation merged.
- [ ] Corrected CI workflow passes on main.
- [ ] RR-002 validation follow-up reviewed and accepted.
- [ ] RR-003 remains blocked until the follow-up is accepted.
