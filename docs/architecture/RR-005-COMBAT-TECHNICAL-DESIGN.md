# RR-005 — Combat System Technical Design

**Status:** D1 merged; D2 implementation in review  
**Engine:** Godot 4.4.1 · Typed GDScript  
**Dependencies:** RR-002 CharacterActor/CharacterDefinition, RR-003 movement, RR-004 presentation interface

## Goals

Build deterministic, local combat for the offline-first vertical slice. The initial combat loop must support player melee/ranged attacks, enemy damage reception, hero abilities, readable hit feedback and boss encounters without coupling gameplay authority to animation assets or remote services.

## Architecture boundaries

1. Combat simulation is authoritative in local Godot gameplay code.
2. Health/damage reception, attack execution, hit detection, abilities and presentation are separate responsibilities.
3. Animation is presentation-only. Animation may display a hit reaction but cannot confirm a hit, apply damage or own cooldowns.
4. Attack definitions are data resources; runtime attack execution is typed GDScript.
5. All combat timing uses deterministic gameplay timers/physics ticks, not animation completion callbacks.
6. Remote AI services are excluded from combat, enemy decisions, damage and frame-critical loops.
7. Networking/Nakama is not introduced in RR-005; future replication must preserve server-authoritative validation for competitive or co-op play.

## Component model

```text
CharacterActor
├── MovementController
├── AnimationIntegration (optional)
└── HealthComponent
    ↑ receives accepted damage from
AttackExecutor
├── AttackDefinition (data)
└── confirmed target submission (D3 hit detection)
```

## Milestones

| Milestone | Scope | Gate |
|---|---|---|
| D1 | Health/damage receiver, defense, healing, death and invulnerability contract | Merged; CI passed |
| D2 | AttackDefinition and deterministic attack executor with startup/active/recovery/cooldown | Timing and repeat-hit tests; CI/review pending |
| D3 | Hit detection, target filtering and one-hit-per-target handling | Collision/query fixture tests pass |
| D4 | Hero combat moves and ability execution hooks for Vanguard, Phantom and Cipher | Ability/cooldown tests pass |
| D5 | Enemy combat receiver and boss damage interfaces | Enemy fixture and boss tests pass |
| D6 | Hit reactions, knockback/stagger/death presentation integration | Gameplay state remains authoritative without a rig |
| D7 | Combat tuning, mobile performance and end-to-end encounter validation | Device evidence and combat acceptance checklist complete |

## D1 health contract

`HealthComponent` owns maximum/current health, flat defense, optional invulnerability, healing and death. It exposes `apply_damage`, `heal`, `reset_health`, `get_health_ratio` and signals. It does not decide whether an attack hit.

Flat defense is the initial baseline: accepted positive damage is `max(raw_damage - defense, 1)`, capped at remaining health. Invulnerability defaults to zero and is explicitly configured. This baseline is subject to later combat balancing.

## D2 attack contract

`AttackDefinition` is a typed Resource containing stable identity, damage amount/type and phase durations. `AttackExecutor` owns the state sequence:

`IDLE → STARTUP → ACTIVE → RECOVERY → COOLDOWN → IDLE`

The executor rejects attack requests while busy and rejects invalid definitions. `try_hit(HealthComponent)` is the sole D2 damage entry point; it is valid only during ACTIVE, registers a target once per attack instance and delegates actual damage to D1. D2 accepts externally confirmed targets and does not perform collision queries. D3 owns hit detection and target filtering.

Timer stepping carries excess delta through phase boundaries. Cooldown begins after recovery. Startup/recovery/cooldown may be zero; active duration must be positive.

## Non-goals

No production animation pack, skeletal retargeting, mobile touch controls, multiplayer replication, loot economy, procedural enemy behavior or AI-generated combat decisions are part of D1/D2. RR-004 D7 visual/device evidence remains a separate open sign-off item.
