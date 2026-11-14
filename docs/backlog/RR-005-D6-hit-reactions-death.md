# RR-005 D6 — Hit Reactions, Knockback, Stagger and Death Presentation

**Status:** Implementation in review

**Dependency:** RR-005 D5 branch is included in this feature branch until D5 merges to main.  
**Branch:** `feat/rr-005-d6-hit-reactions-death`  
**Engine:** Godot 4.4.1 · Typed GDScript

## Goal

Translate accepted D1 damage/death events into local, deterministic combat presentation and movement responses. Presentation never confirms hits or applies damage.

## Delivered

- `CombatReactionController` subscribes to D1 `HealthComponent.damaged` and `died`.
- Accepted hits emit presentation signals, request the existing RR-004 HitReact state when an animation rig is available, and calculate directional knockback from the damage source.
- `CharacterMovementController.apply_combat_impulse()` owns the stagger window and world-space impulse for player characters. Locomotion and jump/lane input are suppressed during stagger; gravity and collision movement continue.
- A fallback CharacterBody3D impulse path supports enemy/boss combatants without the hero movement controller.
- Lethal damage marks movement dead, cancels an in-flight D2 attack, disables collision shapes and disables D3 hurtboxes. D1 remains the sole death authority.
- Missing animation rigs are safe; death is exposed as a presentation event for later rig-specific animation/VFX.

## Boundaries

- D1 owns health, damage and death.
- D2 owns attack phase timing and hit registration.
- D3 owns collision detection and target filtering.
- D6 reacts only to accepted D1 events; it never applies damage.
- Enemy perception, navigation and attack decisions remain RR-008.
- Production death clips, ragdoll, VFX/audio assets, pooling and device tuning are not claimed by this milestone. D7 owns tuning and encounter validation.

## Tuning defaults

- Hit stun: 0.28 seconds.
- Horizontal knockback: 4.0 world units/second impulse.
- Vertical impulse: 1.0.
- These are implementation defaults and require playtesting before balance lock.

## Acceptance

- [ ] Accepted damage triggers one hit reaction and knockback event.
- [ ] Stagger suppresses movement intent while preserving gravity/collision.
- [ ] Damage source determines outward knockback direction.
- [ ] Lethal damage disables movement and combat collision and cancels attacks.
- [ ] Missing rig remains safe.
- [ ] Godot 4.4.1 CI passes the full regression suite.
- [ ] Review and merge.
