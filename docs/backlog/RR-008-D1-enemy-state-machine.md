# RR-008 D1 — Deterministic Enemy State Machine

**Status:** Initial implementation in review  
**Engine:** Godot 4.4.1 · Typed GDScript

## Scope
- Establish typed enemy states: IDLE, ALERT, CHASE, ATTACK, STAGGERED and DEAD.
- Accept an explicit Node3D target; keep target selection/perception as a later milestone.
- Transition deterministically using configured detection, attack and target-loss distances.
- Delegate attack requests to existing EnemyCombatController; D2 remains authoritative for attack phases and damage.
- Allow stagger/death lifecycle to suppress further decisions and prevent dead actors reacquiring targets.

## Architecture boundaries
The controller does not move the enemy, apply damage, select targets from the scene tree, or call remote AI. Later milestones add perception/target selection, navigation/steering, archetype policies and boss phase orchestration. Runtime decisions stay local and deterministic.

## Acceptance evidence
- Target acquisition, chase, attack, stagger recovery and death transitions are covered by tests/enemy_ai_controller_test.gd.
- A dead HealthComponent transitions the brain to DEAD.
- CI runs the enemy AI test suite.
