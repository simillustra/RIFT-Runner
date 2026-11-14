# RR-005 D3 — Collision-Based Hit Detection and Target Filtering

**Status:** Implementation in review  
**Branch:** `feat/rr-005-d3-collision-hit-detection`  
**Engine:** Godot 4.4.1 · Typed GDScript

## Goal

Connect physics overlap detection to the D2 attack executor while preserving D2 timing and D1 health ownership.

## Delivered

- `CombatHitbox`: Area3D adapter that monitors only during D2's active-window signals.
- `CombatHurtbox`: Area3D target volume that resolves a living D1 HealthComponent.
- Explicit same-team filtering when both combatants have a non-empty team ID.
- Self-target filtering using combatant roots.
- Disabled/dead/missing-health targets are rejected.
- Every eligible overlap is submitted through `AttackExecutor.try_hit()`; no hitbox code calls `HealthComponent.apply_damage()`.
- D2 retains one-hit-per-target-per-attack registration, including repeated overlap callbacks.
- Headless physics fixture tests and CI integration.

## Collision setup

- Hitbox collision mask must include the hurtbox collision layer.
- Hurtboxes are `monitorable`; hitboxes are `monitoring` only while the executor is ACTIVE.
- Attach a `CombatHurtbox` Area3D beneath a combatant root and point `health_component_path` to its HealthComponent (default sibling path).
- Attach a `CombatHitbox` Area3D beneath the attacker root, with an `AttackExecutor` sibling (default paths).
- Assign explicit team IDs to enable friendly-fire filtering. Empty IDs are neutral/unspecified and do not match.

## Ownership guarantees

- D3 does not start attacks, advance timers, change attack phases, or apply damage.
- D2 remains authoritative for startup, active, recovery, cooldown and duplicate target registration.
- D1 remains authoritative for defense, invulnerability, health and death.
- Animation events do not confirm hits. The executor's active-window signals gate physics monitoring.

## Acceptance

- [ ] Physics overlap reaches `AttackExecutor.try_hit()` only during ACTIVE.
- [ ] Startup and recovery cannot damage targets.
- [ ] Same-team and self targets are filtered.
- [ ] Disabled, dead and missing-health targets are rejected.
- [ ] Repeated overlap cannot damage a target more than once per attack.
- [ ] Godot 4.4.1 CI passes all regression suites.
- [ ] Review and merge.

## Next

D4: hero combat moves and ability execution hooks for Vanguard, Phantom and Cipher.
