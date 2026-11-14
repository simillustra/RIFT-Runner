# Combat Design

**Owner:** RR-005  
**Status:** D1 health reception and D2 attack timing implemented; D2 review pending.

## Combat principles

- Separate attack intent, attack timing, hit detection, damage reception and presentation.
- Local Godot gameplay code remains authoritative for offline-first combat.
- Animation may present an attack or hit reaction but cannot confirm a hit or apply damage.
- Hit detection submits confirmed targets to the attack executor; only the executor applies attack damage through HealthComponent.
- Remote AI and network services are excluded from real-time combat decisions.

## Current contracts

### Health and damage reception (D1)

`HealthComponent` owns maximum/current health, flat defense, optional invulnerability, healing and death. It exposes `apply_damage`, `heal`, `reset_health` and health ratio. Damage is mitigated by flat defense with a one-point minimum for positive damage and capped at remaining health.

### Attack definition and execution (D2)

`AttackDefinition` describes damage type/amount and startup, active, recovery and cooldown durations. `AttackExecutor` enforces the phase sequence:

`IDLE → STARTUP → ACTIVE → RECOVERY → COOLDOWN → IDLE`

Zero startup/recovery/cooldown are allowed; active duration must be positive. Cooldown begins after recovery. Explicit hit registration is accepted only during ACTIVE, and each target can be registered once per attack instance. D2 does not perform collision detection.

## Planned

- D3: physics-based hit detection and target filtering.
- D4: hero combat moves and ability execution hooks for Vanguard, Phantom and Cipher.
- D5: enemy combat receiver and boss damage interfaces.
- D6: hit reactions, knockback/stagger/death presentation.
- D7: combat tuning, mobile performance and end-to-end encounter validation.

Weapon sets, combos, dodge windows, stamina/poise and final damage balancing remain to be designed in their respective milestones.
