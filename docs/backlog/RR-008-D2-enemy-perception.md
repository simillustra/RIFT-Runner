# RR-008 D2 — Local Enemy Perception and Target Selection

**Status:** Implementation in review · Godot 4.4.1

## Contract
EnemyPerceptionController periodically scans the configured player group, filters invalid/dead candidates and chooses the nearest valid target inside the perception radius. The chosen target is passed to EnemyAIController; no enemy movement or damage is performed here.

Optional line-of-sight checks use a local physics ray query and configurable collision mask. They are disabled by default until player/environment collision layers are authored consistently.

## Acceptance evidence
- Nearest valid player-group candidate is selected.
- Non-player, out-of-range and dead candidates are ignored.
- Target changes and loss are forwarded to EnemyAIController.
- Enemy and boss combatant scenes include the perception component.
- CI runs tests/enemy_perception_test.gd.

## Boundaries
This milestone does not implement pathfinding, chase steering, archetype-specific behavior, group coordination or remote AI. Runtime perception stays local and is rate-limited by the scan interval.
