# RR-006 D2 — Guided Virtual Joystick

## Objective

Implement the first guided-mode input recognizer: a reusable fixed-position virtual joystick that emits the RR-006 D1 semantic MOVE command without directly changing character movement.

## Scope

- Reusable `VirtualJoystick` Control script and scene.
- Single-pointer ownership with touch and optional desktop mouse input.
- Radial deadzone, radius clamping and normalized directional output.
- Semantic MOVE command lifecycle: STARTED, PERFORMED and CANCELED.
- Focus-loss/tree-exit cancellation and neutral output.
- Deterministic automated tests and CI integration.

## Acceptance criteria

- [ ] Joystick can be instanced as a reusable UI Control.
- [ ] Touch begins only inside the joystick control rectangle.
- [ ] Only one pointer owns the joystick; other pointers cannot steal or update it.
- [ ] Dragging outside the control continues to update the owning pointer.
- [ ] Screen-right maps to +X and screen-up maps to +Y.
- [ ] Radial deadzone suppresses small movement and output is normalized to length <= 1.
- [ ] Knob displacement is clamped to the configured radius.
- [ ] Release, explicit cancel, focus loss and tree exit clear the output and emit a zero-vector CANCELED command.
- [ ] Commands use the D1 action/mode/phase contract, stable source ID and monotonic sequence ID.
- [ ] Joystick never calls CharacterMovementController or changes physics directly.
- [ ] Headless CI tests cover pointer ownership, deadzone, normalization, clamping, direction, cancellation and invalid configuration.
- [ ] Physical-device safe-area placement, touch latency and usability remain open until device validation.

## Test plan

1. Acquire/release pointer and reject a second pointer.
2. Reject updates from a non-owner pointer.
3. Verify center and values within deadzone produce zero vector.
4. Verify full-radius and beyond-radius drags clamp to unit output.
5. Verify directional coordinate convention.
6. Verify STARTED/PERFORMED/CANCELED lifecycle, neutral cancellation and monotonic sequence.
7. Verify invalid source configuration cannot acquire a pointer.
8. Run all existing regression suites through CI.

## CI strategy

- Run project import/class registration before tests.
- Add `tests/virtual_joystick_test.gd` to the Godot 4.4.1 headless CI sequence.
- Keep CI deterministic; no touch-device performance or UX claims from simulated pointer tests.

## Dependencies and exclusions

- Depends on RR-006 D1 semantic command contract.
- D2 implements guided movement input only. Action buttons, gesture recognizers, routing/arbitration, layout/safe-area placement and device acceptance remain later work.
