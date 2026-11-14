# Combat Design

**Owner:** RR-005  
**Status:** D1-D4 merged; D5 CI passed and is in review; D6 hit-reaction implementation in review.

## Combat principles

- Separate attack intent, attack timing, hit detection, damage reception and presentation.
- Local Godot gameplay code remains authoritative for offline-first combat.
- Animation may present an attack or hit reaction but cannot confirm a hit or apply damage.
- Hit detection submits confirmed targets to the attack executor; only the executor applies attack damage through HealthComponent.
- Remote AI and network services are excluded from real-time combat decisions.

## Current contracts

### Health and damage reception (D1)

`HealthComponent` owns maximum/current health, flat defense, optional invulnerability, healing and death. It exposes `apply_damage`, `heal`, `reset_health` and health ratio. Damage is mitigated by flat defense, then the D5 damage-intake multiplier is applied.

### Attack definition and execution (D2)

`AttackDefinition` describes damage type/amount and startup, active, recovery and cooldown durations. `AttackExecutor` enforces `IDLE → STARTUP → ACTIVE → RECOVERY → COOLDOWN → IDLE`; hits are accepted only during ACTIVE and each target can be registered once per attack.

### Collision and target filtering (D3)

`CombatHitbox` is enabled only by D2 active-window signals. `CombatHurtbox` resolves a living D1 HealthComponent. Self and same-team targets are filtered before submission. D3 never applies damage directly.

### Hero combat (D4)

Vanguard, Phantom and Cipher define basic attacks and signature ability metadata. `HeroCombatController` delegates attacks to D2 and exposes ability lifecycle signals.

### Enemy combat and boss damage (D5)

`EnemyCombatController` delegates enemy attacks to D2. Boss phases modify D1 damage intake; boss death is driven by D1. Enemy/boss combatant scenes reuse the same D1-D3 contracts.

### Hit reactions and death presentation (D6)

- `CombatReactionController` subscribes to accepted D1 damage/death events.
- Hit reaction requests the existing RR-004 HitReact animation state when a rig is available.
- Directional knockback derives from the damage source. CharacterMovementController owns player stagger and impulse integration; CharacterBody3D fallback supports enemies/bosses without that movement controller.
- Stagger temporarily suppresses movement intent while gravity and collision movement continue.
- D1 death marks movement dead, cancels D2 attacks, disables collision shapes and disables D3 hurtboxes. A death presentation signal is emitted for future visual/audio assets.
- D6 does not apply damage, choose targets or implement enemy AI.

## Planned

- D7: combat tuning, mobile performance and end-to-end encounter validation.
