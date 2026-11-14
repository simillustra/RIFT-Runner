# RR-003 D6 — Production actor integration and collision validation

## Objective

Validate the production `CharacterActor` scene with the real movement controller and Godot's collision solver. This milestone is an integration gate, not a new movement mode or input implementation.

## Integration contract

- The production actor is a `CharacterBody3D` and owns exactly one direct-child `CharacterMovementController`.
- The controller remains responsible only for deterministic locomotion, grounded state and movement impulses. It does not poll input, own camera behavior, drive animation, or execute combat/abilities.
- Character speed is read from `CharacterDefinition.stats.movement_speed` when available; the controller's existing safe default remains available for actors without a definition.
- CharacterActor continues to configure its HealthComponent from the assigned character definition.
- Optional animation integration remains presentation-only and may safely run without a production rig.

## Automated integration arena

`tests/movement_actor_integration_d6_test.gd` instantiates the actual `game/scenes/characters/character_actor.tscn` and the Vanguard resource. It builds real StaticBody3D collision geometry: a floor, a 12-degree ramp and a vertical wall.

Assertions cover:

1. Production scene/resource loading and exactly one movement controller with correct direct ownership.
2. Required production components and CharacterDefinition-driven movement/health values.
3. Real grounded contact before movement.
4. Ramp ascent through CharacterBody3D collision response.
5. Wall blocking without tunnelling through the obstacle.
6. Grounded state remains valid on the ramp.

## CI

Godot 4.4.1 editor import/class registration runs before the test:

```sh
godot --headless --path . --script res://tests/movement_actor_integration_d6_test.gd
```

CI result: pending.

## Remaining validation

Headless collision fixtures do not replace visual and device validation. RR-003 still requires Android device movement tests, representative production-level arena playtesting, full regression on the final acceptance commit, and any required iOS validation for the release target.
