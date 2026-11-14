# RR-006 D4 — Tap, Multi-tap and Press Recognition

## Objective
Implement a configurable free-hand recognizer for tap, double-tap, triple-tap, long-press and optional pressure-aware hard-press gestures. Recognizers emit validated D1 semantic commands only.

## Scope and behavior
- Reusable `TapPressGestureRecognizer` Control and scene.
- `TapPressGestureProfile` configures gesture thresholds and semantic action bindings.
- Single pointer ownership, movement tolerance and touch/mouse support.
- Single taps are delayed until the multi-tap window closes. Two taps resolve to double-tap; a third tap overrides the pending double-tap and resolves to triple-tap.
- Long press fires once when the configured hold duration is reached and suppresses tap classification.
- Hard press is opt-in and pressure-aware. It is disabled by default because pressure support is not consistent across mobile hardware; it can be tested through the explicit pressure update API.
- Movement beyond the tap tolerance cancels the press instead of accidentally triggering an action.
- Focus loss, explicit cancellation and tree exit clear active and pending gesture state.
- Emits FREE_HAND STARTED/PERFORMED command pairs with stable source ID and monotonic sequence IDs.
- No movement, combat, ability or physics calls.

## Provisional default action mapping
| Gesture | Default semantic action |
|---|---|
| Tap | BASIC_ATTACK |
| Double tap | DODGE |
| Triple tap | INTERACT |
| Long press | CANCEL |
| Hard press | PAUSE |

All mappings and thresholds are configurable. These defaults are implementation placeholders, not final gameplay decisions. Ability actions require a hero-specific ability ID and should be configured only after the action-router milestone.

## Acceptance criteria
- [ ] Only one pointer owns the recognizer; non-owner events are ignored.
- [ ] Tap emits after the conflict window, not immediately.
- [ ] Double tap overrides single tap; triple tap overrides double tap.
- [ ] Long press fires once and suppresses tap.
- [ ] Optional pressure-aware hard press fires once and suppresses tap.
- [ ] Movement beyond tolerance cancels the press.
- [ ] Cancellation clears active pointer and pending multi-tap state.
- [ ] Commands validate against D1 and preserve source/sequence metadata.
- [ ] No gameplay controller or physics mutation is performed.
- [ ] Headless tests cover pointer ownership, tap conflict resolution, long press, hard press, movement cancellation and invalid profiles.
- [ ] Physical Android/iOS timing, pressure capability and accessibility validation remain outstanding.

## Test plan
1. Pointer acquisition, second-pointer rejection and non-owner update rejection.
2. Single tap timeout and command phase/sequence checks.
3. Double/triple tap conflict resolution.
4. Long press timing and movement cancellation.
5. Optional pressure-aware hard press and interruption cleanup.
6. Invalid source/profile rejection.
7. Full CI regression suite after Godot 4.4.1 project import.

## CI and dependencies
- Depends on D1 command contract and D3 pointer ownership/lifecycle conventions.
- Add `tests/tap_press_gesture_recognizer_test.gd` to the Godot 4.4.1 headless CI sequence.
- D4 excludes gameplay dispatch (D5), mode/context management (D6), multi-source arbitration (D7) and device acceptance (D8).
