# RR-004 D5 — Character Integration and Fallback

**Status:** Implementation in progress  
**Dependency:** RR-004 D4 controller  
**Engine:** Godot 4.4.1

## Objective

Integrate the D4 animation controller into CharacterActor without making animation assets a prerequisite for loading or controlling a character.

## Design

- CharacterActor owns an optional CharacterAnimationIntegration adapter.
- The adapter resolves sibling MovementController, AnimationTree and AnimationPlayer nodes through exported NodePaths.
- If both animation nodes are absent, the adapter silently remains disabled. This is the expected fallback until production rigs are supplied.
- If only one animation node is present, or required movement/profile dependencies are missing, the adapter emits an actionable warning and disables animation integration.
- When all dependencies exist, the adapter creates and owns a CharacterAnimationController and assigns typed dependencies.
- The adapter never writes actor velocity, grounded state, collision state or movement intent.

## Validation

The D5 headless test covers actor loading without a rig, fallback movement availability, fixture-rig integration, controller initialization, AnimationTree activation and movement-state immutability.

Run after editor import/global class registration:

```sh
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/character_animation_integration_test.gd
```

## Known limitations

- CharacterActor still uses VisualPlaceholder; no production skeleton or third-party assets are introduced.
- Fixture clips are empty and validate wiring/resource paths, not visual quality.
- Visual retargeting and device validation remain D7 work.
