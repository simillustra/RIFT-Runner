# RR-003 D5 — Invalid delta, configuration and actor ownership safety

## Objective

Prove that the movement controller fails closed when it receives an invalid physics time step, invalid tuning, or an invalid/missing actor owner. Valid movement behavior remains unchanged.

## Implementation

- Reject zero, negative, NaN and infinite physics deltas before reading or mutating actor state.
- Validate the movement mode and every numeric movement parameter for finite, meaningful values.
- Disable initialization when the direct parent is not a `CharacterBody3D` or configuration validation returns diagnostics.
- Expose `is_operational()` for integration checks.
- Re-check direct-parent ownership before each valid physics step. If ownership is lost, disable the controller and emit one actionable warning.
- Keep the controller inert when unattached or invalid; no fallback actor is inferred.

## Automated coverage

`tests/movement_safety_d5_test.gd` checks:

1. Zero, negative, NaN and infinite deltas preserve actor velocity and transform.
2. Invalid lane count, non-positive/non-finite tuning values and all diagnostics.
3. Invalid configuration disables the controller and prevents actor mutation.
4. A controller parented to a non-`CharacterBody3D` is safely disabled.
5. An unattached controller safely ignores a physics step.

## Boundaries

This milestone does not add movement features, change acceleration/physics tuning, or replace production actor integration. Slope/collision arena validation and device testing remain separate acceptance items.

## CI

Run with Godot 4.4.1 after editor import:

```sh
godot --headless --path . --script res://tests/movement_safety_d5_test.gd
```

CI result: pending.
