# RR-003 — Movement Engine

**Priority:** P0  
**Status:** In progress  
**Depends on:** RR-001 and RR-002 (accepted/merged)

## Objective
Deliver a deterministic, typed movement foundation for the CharacterActor. The initial implementation provides lane-constrained runner movement and a camera-basis-relative free-movement mode.

## Scope
- Dedicated CharacterMovementController child component.
- Configurable odd lane count, lane width and bounded lane switching.
- Speed sourced from assigned CharacterDefinition.stats.movement_speed with a safe fallback.
- Acceleration/braking for free movement, gravity and jump request handling.
- Grounded and lane-change signals.
- Configuration validation and headless regression coverage.

## Acceptance criteria
- [ ] Controller is attached to CharacterActor and uses CharacterBody3D physics.
- [ ] Lane changes are bounded and transition smoothly to lane centers.
- [ ] Free movement uses normalized camera-relative planar intent.
- [ ] Acceleration, braking, gravity and jump are applied in physics_step.
- [ ] Grounded and lane state changes are observable.
- [ ] Invalid configuration is diagnosed.
- [ ] No network, remote AI, animation, combat or mobile UI dependency.
- [ ] CI editor import and headless smoke test pass.

## Explicitly out of scope
Dodge, combat, abilities, animation, camera rig, obstacle traversal, touch controls, procedural world generation, multiplayer and AI service integration.
