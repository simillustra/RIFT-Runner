# RR-006 D3 — Free-hand Swipe and Drag Recognition

## Objective
Add a configurable free-hand recognizer that translates cardinal swipes or continuous drags into validated RR-006 D1 semantic commands. It emits intent only and does not call movement, combat or ability controllers.

## Scope
- FreeHandGestureProfile Resource with directional-swipe or continuous-drag mode.
- FreeHandGestureRecognizer Control with single-pointer ownership and touch/mouse support.
- Configurable thresholds, deadzone, full-scale distance and cardinal swipe-to-action bindings.
- Normalized MOVE vector for continuous drag; screen-right +X and screen-up +Y.
- STARTED/PERFORMED/CANCELED lifecycle, focus/tree cancellation and monotonic source sequence.
- Headless tests, architecture documentation and CI coverage.

## Acceptance criteria
- [ ] Pointer begins only inside the visible control rectangle.
- [ ] Second pointer cannot steal or update an active gesture.
- [ ] Cardinal swipes use a configurable distance threshold.
- [ ] Diagonals resolve by dominant axis; ties resolve horizontally.
- [ ] Direction bindings are configurable and validated.
- [ ] Sub-threshold movement emits no semantic action.
- [ ] Continuous drag activates after threshold and emits normalized MOVE commands.
- [ ] Drag output applies a pixel deadzone, clamps magnitude to 1 and follows the screen coordinate convention.
- [ ] Drag release, explicit cancellation, focus loss and tree exit emit zero-vector CANCELED.
- [ ] Commands use FREE_HAND mode, valid action/phase values, source ID and increasing sequence IDs.
- [ ] Recognizer never calls CharacterMovementController or mutates physics.
- [ ] CI covers pointer ownership, cardinal swipes, threshold, dominant axis, drag output/lifecycle and invalid profile.
- [ ] Physical-device latency, comfort, gesture grammar and accessibility remain subject to device playtesting.

## Provisional default mapping
| Gesture | Semantic action |
|---|---|
| Swipe left | LANE_LEFT |
| Swipe right | LANE_RIGHT |
| Swipe up | JUMP |
| Swipe down | DODGE |
| Continuous drag | MOVE vector |

These bindings are configuration defaults, not final design approval. Replace or edit the profile per game mode, hero, device or accessibility setting. Swipe and drag modes are mutually exclusive per recognizer instance.

## Test plan
1. Acquire/release pointer; reject second pointer and non-owner updates.
2. Verify four cardinal mappings and command phases.
3. Verify sub-threshold movement and dominant-axis resolution.
4. Verify drag activation, normalization, deadzone and direction convention.
5. Verify release and explicit cancellation neutralize drag.
6. Verify invalid source/profile prevents acquisition.
7. Run the complete existing Godot regression suite in CI.

## CI strategy
- Import project and register global classes before tests.
- Run tests/free_hand_gesture_recognizer_test.gd after D1/D2 input suites.
- Tests are deterministic and independent of real touch hardware.
- Physical Android/iOS validation remains a separate acceptance gate.

## Dependencies and exclusions
- Depends on RR-006 D1 command contract and D2 pointer lifecycle conventions.
- D3 excludes tap/long-press recognition (D4), gameplay routing (D5), mode/context management (D6), multi-source arbitration (D7) and final device-tuned defaults (D8).
