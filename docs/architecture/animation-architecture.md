# Animation Architecture

Animation presents locomotion, combat reactions, traversal transitions and abilities. It consumes actor/gameplay state; it does not own authoritative movement, damage, cooldowns or ability execution.

## RR-004 movement-state contract (D1)

`CharacterMovementController.get_animation_state()` returns a detached `CharacterAnimationState` snapshot containing planar velocity, vertical velocity, grounded state, movement mode and actor facing basis. The snapshot is observational only; mutating the returned value cannot change the actor or controller. Animation consumers must not read private movement-controller fields.

See [RR-004 D1 movement-state contract](../backlog/RR-004-D1-movement-state.md).

## Planned animation architecture

- Godot AnimationTree provides blending and state-machine playback, backed by AnimationPlayer.
- A shared typed CharacterAnimationController consumes the read-only movement-state contract.
- Typed AnimationProfile Resources provide hero-specific semantic clip mappings and tuning.
- AnimationTree parameter paths are centralized and validated during initialization.
- Optional/missing rig assets disable presentation safely without blocking offline gameplay.
- Animation markers emit presentation-only events; gameplay outcomes remain owned by movement/combat systems.

## Boundaries

- RR-003 owns movement physics and grounded truth.
- RR-004 owns animation mapping, blending and presentation events.
- RR-005 owns combat, damage and ability execution.
- RR-006 owns device input.
- RR-012/RR-013 own online/co-op replication.
- Remote AI is never part of the animation update loop.
