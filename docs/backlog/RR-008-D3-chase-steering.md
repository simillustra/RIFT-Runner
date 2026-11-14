# RR-008 D3 — Chase Steering, Navigation and Attack Spacing

**Status:** Implementation submitted for Godot 4.4.1 CI validation.

## Contract
EnemyChaseController is a local runtime locomotion adapter for CharacterBody3D. It follows EnemyAIController state and target. If a configured NavigationAgent3D has a valid navigation map, it follows the next path position; otherwise it uses direct horizontal steering. Navigation targets are refreshed at a bounded interval.

The controller accelerates and brakes horizontal velocity, turns toward movement, preserves vertical velocity, and stops closing distance inside a configurable preferred attack distance. EnemyAIController remains authoritative for CHASE/ATTACK state transitions and RR-005 remains authoritative for attack execution and damage.

## Boundaries
Direct steering does not avoid obstacles. Navigation requires authored NavigationRegion3D meshes and a configured NavigationAgent3D. No navigation bake, enemy archetype policy, remote inference, or multiplayer authority is added.

## Acceptance evidence
- Target outside attack range enters CHASE.
- Direct steering moves toward target at configured speed.
- Enemy stops closing distance inside preferred attack spacing.
- Existing AI, perception and combat suites remain in CI.
