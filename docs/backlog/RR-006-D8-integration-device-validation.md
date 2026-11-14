# RR-006 D8 — Integration, Device Validation and Performance Baseline

## Objective

Validate the complete RR-006 path from guided/free-hand recognizers through the context controller and deterministic router into existing movement and combat authorities. Establish repeatable CI diagnostics and a physical-device evidence protocol.

## Automated integration coverage

`tests/mobile_input_integration_d8_test.gd` exercises:
- Guided joystick pointer acquisition, movement command routing and release neutralization.
- Atomic Guided → Free-hand mode transition and recognizer visibility.
- Directional swipe → semantic JUMP → CharacterMovementController request.
- Tap resolution after the multi-tap conflict window → BASIC_ATTACK → HeroCombatController / AttackExecutor.
- Context transition to DIALOG, active movement cancellation, router suppression and gameplay restoration.
- Control registration and unregister lifecycle.

`tests/mobile_input_performance_d8_test.gd` routes 10,000 deterministic MOVE commands in 100 batches. CI reports average and p95 batch duration, verifies every command is accepted, and checks that continuous movement is not buffered. This is a headless regression diagnostic only: it is not a frame-time, input-latency or mobile-device performance measurement.

## CI strategy

- Import project and register global classes before tests.
- Run all D1-D7 contract, recognizer, routing, context and arbitration suites.
- Run D8 end-to-end integration and throughput diagnostic suites.
- Preserve deterministic assertions; do not gate CI on noisy wall-clock thresholds.
- Record Godot version, runner environment, command count, batch size, average batch time and p95 batch time in workflow logs.

## Device validation matrix

Complete on physical hardware before D8 acceptance. Do not substitute editor simulation or headless CI for touch-device evidence.

| Platform / tier | Minimum evidence |
|---|---|
| Android low-tier | Device model, Android version, screen resolution/DPI, refresh rate, build SHA, 10-minute guided and free-hand session, input latency samples, frame-time p50/p95/p99, memory peak, thermal state |
| Android mid-tier | Same measurements; include simultaneous touch and gesture/joystick arbitration |
| iOS supported device | Device model, iOS version, screen resolution/scale, refresh rate, build SHA, 10-minute session, input latency samples, frame-time p50/p95/p99, memory peak, thermal state |

For every device capture:
1. Guided joystick: cardinal and diagonal movement, deadzone, full-radius output, pointer release, second-finger contention.
2. Free-hand: four cardinal swipes, diagonal tie-break, continuous drag, tap/double/triple tap conflict timing, long press, cancellation.
3. Context/lifecycle: pause, dialog, app background/foreground, focus interruption, scene transition and control destruction while a pointer is active.
4. Gameplay: jump, lane action where applicable, basic attack, each hero's assigned ability, cooldown/busy buffering, cancellation and source priority.
5. Usability: left/right-handed layout, control scale, high contrast, gesture sensitivity and accessibility settings.
6. Sustained run: 10 minutes per mode; record input-to-command and command-to-gameplay latency at p50/p95/p99, frame time p50/p95/p99, CPU, memory and thermal behavior.

Use at least 100 samples per latency scenario after warm-up. Record raw observations and build/device metadata in a dated validation report under `docs/qa/mobile-input/`. Report dropped/late events and any lost, duplicated or stuck input. Repeat defects at least three times and attach a screen recording or reproducible steps.

## Provisional performance targets (not yet measured)

- Input recognizer + routing CPU budget: ≤1.0 ms p95 per frame on the agreed mid-tier Android reference device.
- End-to-end touch-to-gameplay response: ≤100 ms p95 for discrete actions, excluding intentional multi-tap resolution windows.
- No stuck movement after release, focus loss, app suspension, context change or scene teardown.
- No command duplication; source sequence validation remains monotonic per source.
- No continuous MOVE command enters the discrete action buffer.

Targets are provisional engineering goals. Record actual values; do not mark pass if the required hardware/build or sample count is missing.

## Acceptance criteria

- [x] Automated recognizer → context → router → movement/combat integration test added.
- [x] Deterministic 10,000-command headless throughput diagnostic added.
- [x] CI executes both D8 suites after project import.
- [x] Device test protocol, metrics and evidence format documented.
- [ ] Android low-tier physical-device validation recorded.
- [ ] Android mid-tier physical-device validation recorded.
- [ ] iOS physical-device validation recorded.
- [ ] HUD safe-area/layout and real multi-touch usability review recorded.
- [ ] Performance targets reviewed against measured evidence.

## Sign-off rule

D8 implementation is complete when automated CI is green. RR-006 remains device-validation-pending until all applicable hardware reports, HUD integration review and performance evidence are attached. CI timings must never be presented as mobile performance results.
