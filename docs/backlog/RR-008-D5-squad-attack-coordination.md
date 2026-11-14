# RR-008 D5 — Squad Attack Coordination

**Status:** Implementation in progress · Godot 4.4.1 · Typed GDScript

## Goal

Prevent groups of enemies from committing every melee attack against the same target at once. The coordinator arbitrates a bounded number of attack slots per target; enemy brains remain deterministic and retain ownership of their state transitions.

## Runtime contract

- `EnemySquadCoordinator` is an encounter-scoped Node shared by enemies in the same local squad.
- `max_simultaneous_attackers_per_target` bounds active melee attackers independently for each target.
- `EnemyAIController.squad_coordinator_path` is optional. Without a coordinator, enemies retain the existing solo behavior.
- An enemy reserves a slot immediately before requesting an attack from `EnemyCombatController`.
- The slot is held through the existing `AttackExecutor` startup, active, recovery and cooldown phases.
- The slot is released on attack completion, target change/loss, stagger, death, or a rejected attack request.
- Waiting enemies retry using the existing bounded retry interval; no polling loop or remote AI service is introduced.

## Ownership boundaries

The coordinator does not select targets, move enemies, apply damage, alter attack timings, or own enemy state. RR-005 remains authoritative for hit detection, attack phases and damage. RR-008 D1 remains authoritative for state transitions. The coordinator only grants/revokes per-target attack capacity.

## Acceptance

- A one-attacker cap prevents a second enemy from starting an attack against the same target.
- Completing the first attack releases capacity and allows a waiting enemy to attack.
- Stagger and death cancel an in-flight attack and release its slot.
- Independent targets receive independent capacity buckets.
- Invalid members/targets and stale member references are rejected or cleaned safely.
- Existing RR-005 and RR-008 tests remain green.

## Integration

Add one `EnemySquadCoordinator` under the encounter root and set each participating enemy's `EnemyAIController.squad_coordinator_path` to that node. Configure the cap per encounter. A value of 1 is a conservative starting point for melee packs; tune after encounter playtesting. Ranged/projectile attack scheduling and group navigation are not part of D5.
