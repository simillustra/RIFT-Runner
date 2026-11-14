# RR-005 D4 — Hero Combat Moves and Ability Execution Hooks

**Status:** Implementation in review  
**Branch:** `feat/rr-005-d4-hero-combat-abilities`  
**Engine:** Godot 4.4.1 · Typed GDScript

## Goal

Provide data-driven basic attacks and a shared ability execution contract for Vanguard, Phantom and Cipher. Keep attack timing/damage in D2 and collision/hit filtering in D3.

## Delivered

- Hero-specific `AttackDefinition` resources:
  - Vanguard: Heavy Strike — 24 physical damage, deliberate startup/recovery.
  - Phantom: Precision Strike — 20 physical damage, faster startup and recovery.
  - Cipher: Pulse Strike — 18 energy damage, balanced timing.
- `CharacterDefinition.basic_attack` links a hero's basic attack profile.
- `HeroCombatController.execute_basic_attack()` delegates to D2 `AttackExecutor.begin_attack()`.
- `HeroCombatController.activate_ability(ability_id)` resolves only abilities declared by the active hero.
- Ability cooldown and duration tracking with deterministic timer stepping.
- Ability lifecycle signals let gameplay effect systems subscribe without coupling to the controller.
- Dead/unconfigured heroes, unknown abilities, active duplicates and cooldown attempts are rejected.
- Headless tests cover all three heroes, attack profile validation, D2 phase locking, ability activation, duration and cooldown.

## Ability effect boundary

D4 emits `ability_activated`, `ability_effect_started` and `ability_effect_ended`. It does not yet implement the gameplay-specific stat/defense/evasion modifiers. Those effects can subscribe to this stable contract in a later milestone. No ability bypasses D1 health or D2/D3 attack flow.

## Ownership

- D1: health, defense, invulnerability and death.
- D2: attack phases, timing, damage and duplicate target registration.
- D3: physics hit detection and target filtering.
- D4: hero attack data, ability lookup, activation, duration and cooldown orchestration.

## Acceptance

- [ ] Each hero has a valid unique basic attack profile.
- [ ] Basic attacks start through D2 only.
- [ ] Only the active hero's declared signature ability can be activated.
- [ ] Cooldown and duration are deterministic and tested.
- [ ] Dead actors and cooldown/duplicate requests are rejected.
- [ ] Godot 4.4.1 CI passes all regression suites.
- [ ] Review and merge.

## Next

D5: enemy combat and boss damage interfaces.
