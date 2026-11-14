# RR-006 D1 — Mobile Input Architecture and Action Mapping

## Objective

Establish the stable input contract shared by Guided and Free-hand controls before implementing the joystick or gesture recognizers.

## Scope delivered by D1

- Typed semantic action vocabulary and input mode/phase enums.
- Device-neutral `MobileInputCommand` payload with validation.
- Architecture and ownership boundaries documented in `docs/input/mobile-input-architecture.md`.
- Explicit provisional action mapping for joystick, gestures, movement, combat, abilities and game-state actions.
- Automated contract tests wired into the Godot CI workflow.

## Acceptance criteria

- [ ] Guided and Free-hand recognizers can represent their output using the same command type.
- [ ] Semantic actions are independent of touch coordinates, pointer IDs and device-specific event classes.
- [ ] MOVE vectors are finite and normalized; strength is finite and bounded.
- [ ] Ability commands require an explicit ability ID.
- [ ] Invalid enum values, non-finite values, invalid vectors and negative sequence IDs are rejected.
- [ ] Non-MOVE actions cannot accidentally carry movement vectors.
- [ ] The contract documents cancellation, source ownership, context suppression and mode-switch neutralization.
- [ ] Gameplay ownership remains with CharacterMovementController, HeroCombatController and GameState; D1 introduces no direct gameplay mutation.
- [ ] Reserved actions are documented as unsupported until a gameplay endpoint exists.
- [ ] CI imports the Godot project and runs the D1 contract test under Godot 4.4.1.
- [ ] No claim of device usability or gesture accuracy is made at D1.

## Test plan

1. Verify every action enum maps to a stable semantic name.
2. Verify Guided and Free-hand modes and all command phases are representable.
3. Accept normalized MOVE vectors, including zero and diagonal values at unit length.
4. Reject over-length, NaN and infinite movement vectors.
5. Reject non-finite or out-of-range strength.
6. Reject invalid action, phase and mode enum values.
7. Reject non-MOVE vectors and ability actions without ability IDs.
8. Reject negative sequence IDs and empty source IDs.
9. Run the existing full CI suite to detect class registration and regression failures.

## CI strategy

- Keep the project import/class registration step before script tests.
- Add a dedicated headless command: `godot --headless --path . --script res://tests/mobile_input_contract_test.gd`.
- Trigger CI for `feat/rr-006/**` pushes and pull requests targeting main.
- Pin and verify Godot 4.4.1 as in the existing pipeline.
- CI validates deterministic contract behavior only. Touch latency, gesture accuracy, accessibility and frame-time budgets require later physical-device testing.

## Dependencies and exclusions

- Builds on RR-003 movement and RR-005 combat public request interfaces.
- Does not require RR-003 formal device acceptance to define the input contract, but RR-006 integration must respect outstanding movement acceptance gates.
- D2-D8 remain separate milestones; this PR does not implement recognizers or connect live UI controls.
