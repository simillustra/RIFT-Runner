# Enemy Design
**Owner:** RR-008. **Status:** D1-D2 merged; D3 local chase steering and navigation adapter implemented, CI pending.

Enemy behavior is deterministic, local and data-driven. Enemy brains never depend on remote inference or network availability. Combat delegates to RR-005; health/death remain owned by HealthComponent; hit reactions remain owned by CombatReactionController.

## State model
IDLE → ALERT → CHASE → ATTACK, with interrupt states STAGGERED and terminal DEAD. Perception selects the nearest valid player target. EnemyAIController owns state transitions; EnemyChaseController owns CharacterBody3D horizontal steering while in CHASE.

## Chase and navigation
A configured NavigationAgent3D is used when it has a valid navigation map. Without one, direct steering provides a deterministic fallback but does not avoid walls or obstacles. The controller brakes inside preferred attack distance so the enemy does not continuously push into the player. RR-005 owns attack execution and damage.

## Vertical-slice archetypes
Five archetypes are planned. Their detailed roles, attack patterns, telegraphs, counters, environment interactions and tuning remain to be authored before archetype implementation. Avoid encoding archetype-specific branches in the shared state machine; use later behavior policies/resources.

## Delivery sequence
1. D1: deterministic state machine and health/combat integration boundary.
2. D2: perception and target selection.
3. D3: chase steering/navigation and attack spacing.
4. D4: data-driven archetype behavior policies and tuning.
5. D5: stagger, retreat, group coordination and encounter director.
6. D6: boss phase orchestration and encounter validation.
