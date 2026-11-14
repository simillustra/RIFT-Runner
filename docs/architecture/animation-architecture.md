# Animation Architecture

Animation presents locomotion, combat reactions, traversal transitions and abilities. It consumes actor/gameplay state; it does not own authoritative movement, damage, cooldowns or ability execution.

## RR-004 design baseline

- Godot 4.4.1 AnimationTree provides blending and state-machine playback, backed by AnimationPlayer.
- A shared typed CharacterAnimationController consumes a read-only movement-state contract.
- Typed AnimationProfile Resources provide hero-specific semantic clip mappings and tuning.
- AnimationTree parameter paths are centralized and validated during initialization.
- Optional/missing rig assets disable presentation safely without blocking offline gameplay.
- Animation markers emit presentation-only events; gameplay outcomes remain owned by movement/combat systems.

See [RR-004 Technical Design](RR-004-TECHNICAL-DESIGN.md) and [ADR-006](adr/ADR-006-animation-framework.md).

## Current asset state

The CharacterActor currently contains a visual placeholder and movement controller. No production Skeleton3D, AnimationPlayer, AnimationTree graph or hero animation clips are present in the inspected main-branch scene. Rig compatibility and retargeting remain open pending asset selection.

## Boundaries

- RR-003 owns movement physics and grounded truth.
- RR-004 owns animation mapping, blending and presentation events.
- RR-005 owns combat, damage and ability execution.
- RR-006 owns device input.
- RR-012/RR-013 own online/co-op replication.
- Remote AI is never part of the animation update loop.
