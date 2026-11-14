# Movement Design

**Owner:** RR-003  
**Implementation:** Merged in [PR #4](https://github.com/simillustra/RIFT-Runner/pull/4)  
**CI:** [Run #15](https://github.com/simillustra/RIFT-Runner/actions/runs/43508687806) passed, including the headless movement test suite.  
**Acceptance:** See [RR-003 acceptance checklist](../backlog/RR-003-acceptance-checklist.md).

## Current controller foundation

The `CharacterMovementController` is a typed component attached to the character actor. It currently provides:

- Lane mode with configurable odd lane count, lane width, bounded lane changes and smooth lateral positioning.
- Free mode with normalized intent transformed by a supplied camera basis.
- Configurable acceleration, braking, lateral speed, gravity and jump velocity.
- Grounded and lane-change signals.
- Movement speed sourced from the character definition when available, with a fallback speed.

## Ownership and boundaries

The movement controller owns physical movement integration and movement facts. It does not own input polling, camera rig implementation, animation playback, combat, abilities, dodge, obstacle traversal, procedural generation, multiplayer or remote AI.

Future animation code reads movement state through a typed, read-only contract. It must not infer authoritative grounded state from animation playback.

## Outstanding formal acceptance

CI run #15 proves the headless smoke and movement scripts execute successfully. It does not replace deterministic physics-fixture assertions for gravity, jump, landing, lane convergence and camera-relative movement, nor device validation. Track those checks in the RR-003 acceptance checklist.
