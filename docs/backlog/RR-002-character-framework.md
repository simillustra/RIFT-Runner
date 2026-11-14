# RR-002 — Character Framework

**Priority:** P0  
**Status:** Accepted / merged  
**Merged PR:** [#2](https://github.com/simillustra/RIFT-Runner/pull/2)  
**Validation follow-up:** Corrected CI workflow merged in [PR #3](https://github.com/simillustra/RIFT-Runner/pull/3).

## Delivered
- Typed resources for character identity, archetype, stats and ability metadata.
- Validated roster with stable ID lookup and duplicate detection.
- CharacterBody3D actor root with capsule collision placeholder and definition assignment.
- Data assets for Vanguard, Phantom and Cipher.
- Headless smoke test for resource loading, validation, lookup and actor assignment.

## Acceptance evidence
- [x] Character resource and actor implementation merged.
- [x] Corrected CI workflow passed on main in run #11.
- [x] Godot 4.4.1 editor import/global script registration step passed.
- [x] Headless smoke test passed on the merged main commit.
- [x] RR-002 validation follow-up accepted; RR-003 unblocked.

## Scope boundary
RR-002 defines character data and actor ownership. Movement is implemented separately under RR-003; animation, combat, ability execution, input, progression, multiplayer and AI remain separate tasks.
