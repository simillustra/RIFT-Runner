# Enemy Design
**Owner:** RR-008. **Status:** D1 merged; D2 local perception in review.

Enemy behavior is deterministic, local and data-driven. Enemy brains never depend on remote inference or network availability. Combat delegates to RR-005; health/death remain owned by HealthComponent; hit reactions remain owned by CombatReactionController.

## Initial state model
IDLE → ALERT → CHASE → ATTACK, with interrupt states STAGGERED and terminal DEAD. D1 accepts an explicit target and uses configured distance thresholds. D2 adds local player-group scanning and nearest-valid-target selection. Locomotion and navigation remain later work.

## Vertical-slice archetypes
Five archetypes are planned. Their detailed roles, attack patterns, telegraphs, counters, environment interactions and tuning remain to be authored before archetype implementation. Avoid encoding archetype-specific branches in the shared state machine; use later behavior policies/resources.

## Delivery sequence
1. D1: deterministic state machine and health/combat integration boundary.
2. D2: perception and target selection.
3. D3: chase steering/navigation and attack spacing.
4. D4: data-driven archetype behavior policies and tuning.
5. D5: stagger, retreat, group coordination and encounter director.
6. D6: boss phase orchestration and encounter validation.
