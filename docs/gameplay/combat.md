# Combat Design

**Owner:** RR-005  
**Status:** D1 health reception, D2 attack timing and D3 collision adapter implemented; D3 review pending.

## Combat principles

- Separate attack intent, attack timing, hit detection, damage reception and presentation.
- Local Godot gameplay code remains authoritative for offline-first combat.
- Animation may present an attack or hit reaction but cannot confirm a hit or apply damage.
- Hit detection submits confirmed targets to the attack executor; only the executor applies attack damage through HealthComponent.
- Remote AI and network services are excluded from real-time combat decisions.

## Current contracts

### Health and damage reception (D1)

`HealthComponent` owns maximum/current health, flat defense, optional invulnerability, healing and death. It exposes `apply_damage`, `heal`, `reset_health` and health ratio. Damage is mitigated by flat defense with a one-point minimum for positive hits and capped at remaining health.

### Attack definition and execution (D2)

`AttackDefinition` describes damage type/amount and startup, active, recovery and cooldown durations. `AttackExecutor` enforces:

`IDLE → STARTUP → ACTIVE → RECOVERY → COOLDOWN → IDLE`

Hits are accepted only during ACTIVE; each target can be registered once per attack instance. D2 does not perform collision detection.

### Collision and target filtering (D3)

- `CombatHitbox` is an Area3D adapter enabled only by D2 active-window signals.
- `CombatHurtbox` is an Area3D receiver marker resolving a living D1 HealthComponent.
- Self and explicitly same-team targets are filtered before submission.
- Eligible overlap events call `AttackExecutor.try_hit()`; D3 never applies damage directly.
- Disabled, dead and missing-health targets are not submitted.

## Planned

- D4: hero combat moves and ability execution hooks for Vanguard, Phantom and Cipher.
- D5: enemy combat receiver and boss damage interfaces.
- D6: hit reactions, knockback/stagger/death presentation.
- D7: combat tuning, mobile performance and end-to-end encounter validation.

Weapon sets, combos, dodge windows, stamina/poise and final damage balancing remain to be designed in their respective milestones.
