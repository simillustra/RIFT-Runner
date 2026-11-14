# RR-005 D5 — Enemy Combat and Boss Damage Interfaces

**Status:** Implementation in review  
**Branch:** `feat/rr-005-d5-enemy-boss-combat`  
**Engine:** Godot 4.4.1 · Typed GDScript

## Goal

Provide reusable enemy combat composition and a boss damage/vulnerability interface while preserving D1 health, D2 attack execution and D3 collision contracts.

## Delivered

- `EnemyCombatController` validates an enemy attack definition and asks its `AttackExecutor` to begin the attack. It rejects missing dependencies, invalid attacks and dead enemies.
- `enemy_combatant.tscn` composes health, attack executor, enemy combat controller, hitbox and hurtbox with the `infected` team identity.
- `BossDamageController` exposes ARMORED, EXPOSED, ENRAGED and DEFEATED phases. Phase transitions set a damage-intake multiplier on D1 health; boss death is driven by the D1 death signal.
- `boss_combatant.tscn` provides the same enemy combat composition plus the boss damage interface and a 1,000 health default.
- D5 tests cover enemy attack phase delegation, dead-enemy rejection, boss phase multipliers, lethal damage and terminal defeated state.

## Ownership and boundaries

- D1 `HealthComponent` remains the sole owner of health, defense, invulnerability and death.
- D2 `AttackExecutor` remains the sole attack-timing and hit-registration authority.
- D3 `CombatHitbox` / `CombatHurtbox` remain responsible for collision overlap and team filtering.
- D5 does not implement enemy perception, navigation, target selection, boss phase scheduling, attack telegraphs, animation, stagger or death presentation. Those belong to RR-008 and RR-005 D6 respectively.
- The boss controller changes only the damage-intake multiplier. It never applies damage or bypasses D1.

## Damage multiplier semantics

The D1 component applies flat defense first, preserving its minimum-one-point rule for positive damage, then applies a non-negative intake multiplier. A zero multiplier is full immunity; the boss defaults are 0.25 armored, 1.5 exposed and 1.0 enraged. These are tuning placeholders, not final balance.

## Acceptance

- [ ] Enemy attacks start only through D2 and respect all D2 phases.
- [ ] Enemy collision continues through D3 hitbox/hurtbox filtering.
- [ ] Dead enemies cannot initiate attacks.
- [ ] Boss phases adjust D1 damage intake without a second health implementation.
- [ ] Boss death is authoritative in D1 and terminal in the boss interface.
- [ ] Godot 4.4.1 CI passes all regression suites.
- [ ] Review and merge.
