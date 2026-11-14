# RR-005 D1 — Health and Damage Reception Contract

**Status:** Implementation in review  
**Branch:** `feat/rr-005-d1-health-damage-contract`  
**Engine:** Godot 4.4.1 · Typed GDScript

## Goal

Establish a deterministic, reusable health receiver before implementing attack hitboxes, attack timing, abilities or enemy combat. The component owns health state only. It does not decide whether an attack hit.

## Delivered in D1

- Typed `HealthComponent` Node with maximum/current health, defense and optional invulnerability duration.
- Damage reception with defense mitigation, a one-point minimum for positive hits, and a cap at remaining health.
- Temporary invulnerability after an accepted hit, disabled by default.
- Healing, explicit health reset, health ratio and death state.
- Signals for accepted damage, healing and death.
- CharacterActor scene composition with a health component configured from CharacterDefinition stats when available.
- Headless contract tests and CI integration.

## Contract and boundaries

- `apply_damage(raw_damage, source, damage_type)` returns the actual health removed; zero means rejected or blocked.
- `heal(amount)` returns the actual health restored; dead actors cannot be healed until explicitly reset.
- The component does not own hitboxes, hurtboxes, attack windows, target selection, animation events, knockback, stun, score, loot or input.
- No remote AI, networking or physics queries are used.
- Defense currently applies as flat mitigation with a one-point minimum for a positive hit. This is an initial deterministic baseline and may be balanced later.
- Invulnerability is opt-in and defaults to zero to avoid silently changing current gameplay.

## Acceptance checks

- [x] Valid health initialization and health ratio.
- [x] Flat defense mitigation and minimum positive damage.
- [x] Damage rejection during invulnerability.
- [x] Healing cap and dead-state behavior.
- [x] Lethal damage and explicit reset.
- [x] Invalid configuration rejection.
- [x] CharacterActor receives a HealthComponent in its scene composition.
- [ ] Godot 4.4.1 CI passes on this branch.
- [ ] Review and merge.

## Next D2

Implement attack definitions and a deterministic attack executor: attack startup/active/recovery phases, cooldowns, target filtering and one-hit-per-target guarantees. Hit detection must be separate from health reception and must call this D1 contract only after a confirmed overlap.
