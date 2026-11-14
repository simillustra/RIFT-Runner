# RR-008 D6 — Encounter-level tactical coordination

## Objective
Coordinate complete enemy encounters using deterministic, local Godot decisions. This milestone composes pursuer, skirmisher and ranged archetypes; reserves distinct target approach sectors; supports controlled flanking and standoff; and closes lifecycle gaps across death, despawn, pooling and invalid targets.

## Runtime ownership
- `EnemySquadCoordinator` is instantiated once per runtime encounter by `EncounterRuntimeSpawner`.
- Spawned enemies register in spawn order using their authored `EnemyArchetypeProfile.engagement_policy`. Role capacities and fallback order are deterministic.
- The coordinator owns role membership, target-scoped attack slots, approach-sector reservations and retreat membership. Its default approach radius is 1.5 m so pursuers remain inside the baseline melee attack envelope; authored skirmisher/ranged preferred distances expand that radius.
- `EnemyAIController` owns local state transitions and timers. `EnemyChaseController` owns local steering and consumes the assigned approach position.
- The spawner owns encounter lifetime. Pool release unregisters members and releases every claim before the enemy is detached; reuse resets AI state before registration in the new encounter.

## Tactical behavior
- PURSUER prefers a forward engagement sector.
- SKIRMISHER prefers lateral sectors to establish a flank rather than converge on the same point.
- RANGED prefers a rear standoff sector and uses its authored preferred distance. Projectile/ranged attack execution remains a separate combat capability and is not implied by this positioning milestone.
- Occupied sectors are skipped. Each member keeps its sector while the target remains unchanged; target changes release the previous claim.
- Attack slots remain separately capped per target.
- A low-health enemy may retreat once per encounter. It moves directly away until it reaches `retreat_distance`, reports disengagement, waits a deterministic recovery interval, then re-enters CHASE. Death remains terminal.

## Determinism and safety
- No network, LLM, remote AI or asynchronous service is called by perception, tactical decisions, movement or combat.
- Role assignment follows spawn order and fixed capacity/fallback rules. Sector assignment follows fixed role preference arrays and lowest available sector.
- Invalid targets are cleared on the next decision step. Dead or pooled members release attack, approach and retreat claims and are removed from role counts.
- Coordinator cleanup also prunes freed instance IDs before answering counts or reservations.

## Automated validation
`tests/encounter_tactical_coordination_d6_test.gd` covers role composition, capacity fallback, distinct and stable approach sectors, attack-slot compatibility, stagger release, low-health retreat, retreat steering, recovery/re-engagement, target invalidation and death cleanup. The RR-007 runtime spawner suite also asserts that an authored archetype policy becomes the spawned AI's encounter role. CI runs both after project import/class registration.

## Gameplay validation still required
Automated tests validate deterministic contracts, not tactical quality. Before acceptance, record gameplay captures for:
1. A mixed pursuer/skirmisher/ranged encounter in Infected City.
2. A mixed encounter in Alien Facility with navigation obstacles.
3. Multiple enemies attempting to approach the same hero without sector overlap or obvious circling.
4. Low-health retreat and re-engagement under pressure, including stagger and lethal damage during retreat.
5. Segment recycle/reuse while an enemy is attacking, flanking, retreating and dead.
6. Android low/mid-tier and iOS profiling for pathfinding, physics and frame time.

Record seed, device, build, archetype composition, encounter duration and observed defects. No device-performance or gameplay-fairness sign-off is claimed by CI alone.
