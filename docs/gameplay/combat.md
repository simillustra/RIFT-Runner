# Combat Design

**Owner:** RR-005  
**Status:** D1-D4 merged; D5 enemy and boss interfaces in review.

## Combat principles

- Separate attack intent, attack timing, hit detection, damage reception and presentation.
- Local Godot gameplay code remains authoritative for offline-first combat.
- Animation may present an attack or hit reaction but cannot confirm a hit or apply damage.
- Hit detection submits confirmed targets to the attack executor; only the executor applies attack damage through HealthComponent.
- Remote AI and network services are excluded from real-time combat decisions.

## Current contracts

### Health and damage reception (D1)

`HealthComponent` owns maximum/current health, flat defense, optional invulnerability, healing and death. It exposes `apply_damage`, `heal`, `reset_health` and health ratio. Damage is mitigated by flat defense with a one-point minimum for positive hits, capped at remaining health. D5 adds a non-negative damage-intake multiplier after defense; the default is 1.0 and zero is immunity.

### Attack definition and execution (D2)

`AttackDefinition` describes damage type/amount and startup, active, recovery and cooldown durations. `AttackExecutor` enforces:

`IDLE → STARTUP → ACTIVE → RECOVERY → COOLDOWN → IDLE`

Hits are accepted only during ACTIVE; each target can be registered once per attack instance.

### Collision and target filtering (D3)

- `CombatHitbox` is an Area3D adapter enabled only by D2 active-window signals.
- `CombatHurtbox` is an Area3D receiver marker resolving a living D1 HealthComponent.
- Self and explicitly same-team targets are filtered before submission.
- Eligible overlap events call `AttackExecutor.try_hit()`; D3 never applies damage directly.
- Disabled, dead and missing-health targets are not submitted.

### Hero combat (D4)

Vanguard, Phantom and Cipher define their own basic attacks and signature ability metadata. `HeroCombatController` delegates attacks to D2 and exposes ability lifecycle signals.

### Enemy combat and boss damage (D5)

- `EnemyCombatController.request_attack()` validates enemy state and attack data, then delegates to D2 `AttackExecutor`.
- Reusable enemy and boss combatant scenes compose health, executor, controller, hitbox and hurtbox.
- `BossDamageController` provides ARMORED, EXPOSED, ENRAGED and DEFEATED phases. It changes D1's damage-intake multiplier and listens to D1 death; it never applies damage itself.
- Enemy target selection and boss phase scheduling are owned by later enemy AI/encounter work, not this interface.

## Planned

- D6: hit reactions, knockback/stagger/death presentation.
- D7: combat tuning, mobile performance and end-to-end encounter validation.

Weapon sets, combos, dodge windows, stamina/poise and final damage balancing remain to be designed in their respective milestones.
