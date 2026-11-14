# Enemy Design
**Owner:** RR-008. **Status:** D1-D3 implementation in review; D4 archetype policy resources submitted for CI validation.

Enemy behavior is deterministic, local and data-driven. Enemy brains never depend on remote inference or network availability. EnemyAIController owns state transitions; EnemyChaseController owns local locomotion; RR-005 owns health, attack execution, damage and reactions.

## State model
IDLE → ALERT → CHASE → ATTACK, with interrupt states STAGGERED and terminal DEAD. Perception selects the nearest valid player target.

## Chase and navigation
A configured NavigationAgent3D is used when it has a valid navigation map. Otherwise direct steering is used as a fallback; it does not avoid obstacles. Attack spacing prevents continuous closing movement.

## Archetype policies
EnemyArchetypeProfile Resources configure detection/attack ranges, movement speed, acceleration, preferred distance and engagement policy. EnemyArchetypeController applies a validated profile without adding archetype-specific branches to the shared state machine.

- PURSUER closes to attack distance and brakes.
- SKIRMISHER closes, then strafes laterally within its engagement band.
- RANGED closes to its preferred range and holds. Actual ranged attack definitions/projectiles are not part of this milestone.

## Delivery sequence
1. D1: deterministic state machine and health/combat boundary.
2. D2: perception and target selection.
3. D3: chase steering/navigation and attack spacing.
4. D4: data-driven archetype policies and tuning.
5. D5: stagger, retreat, group coordination and encounter director.
6. D6: boss phase orchestration and encounter validation.
