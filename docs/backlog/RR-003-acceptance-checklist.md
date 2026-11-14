# RR-003 — Movement Engine Acceptance Checklist

**Status:** Merged; formal acceptance pending evidence for the remaining checks  
**Implementation PR:** [#4](https://github.com/simillustra/RIFT-Runner/pull/4)  
**Merge commit:** `639c8ea801f04ca22c2c325adfe8ce1b35fa0248`  
**CI evidence:** [Run #15](https://github.com/simillustra/RIFT-Runner/actions/runs/43508687806) — successful, including the headless smoke test and movement test suite.

## 1. Delivered scope

- [x] Typed `CharacterMovementController` component is present and attached to the character actor scene.
- [x] Lane mode supports an odd configurable lane count, lane width, bounded lane selection and lateral movement toward lane centers.
- [x] Free mode accepts normalized movement intent and uses a supplied camera basis for planar movement.
- [x] Movement configuration validation covers lane count/width and positive movement rates.
- [x] Controller exposes grounded and lane-change signals.
- [x] Configurable acceleration, braking, gravity and jump request handling are implemented.
- [x] CI imports the project with the Godot editor before executing headless tests.
- [x] CI movement test command executes successfully on the merged implementation.

## 2. Formal acceptance checks

The items below are not implied by PR merge or the current CI result. Attach test output, screenshots, recordings or device reports before marking them complete.

### A. Physics behavior

- [ ] Add deterministic physics-fixture tests using a real `CharacterBody3D` and a known floor/collision setup.
- [ ] Verify gravity increases downward velocity while airborne and does not accumulate downward velocity while grounded.
- [ ] Verify a jump request while grounded produces the configured upward launch velocity within the documented test tolerance.
- [ ] Verify a jump request while airborne is ignored and cannot trigger a second jump.
- [ ] Verify landing restores grounded state and emits `grounded_changed` exactly on state transitions, not every physics frame.
- [ ] Verify lane changes remain within bounds at both outer lanes and emit `lane_changed` only when the lane actually changes.
- [ ] Verify lane movement converges on the expected lane center without overshooting.
- [ ] Verify free movement is camera-relative, planar, normalized diagonally and reaches zero planar target velocity when intent is released.
- [ ] Verify zero/negative delta is safely ignored and invalid configuration is rejected with actionable diagnostics.
- [ ] Verify missing or invalid actor ownership fails safely without runtime errors.

### B. Character and scene integration

- [ ] Load the production character actor scene and confirm exactly one movement controller is attached to the intended `CharacterBody3D`.
- [ ] Confirm character movement speed comes from the character definition when available and falls back safely when absent.
- [ ] Confirm floor detection, collision response and slopes behave correctly in a representative test arena.
- [ ] Confirm controller does not own input polling, camera rig behavior, animation playback, combat or ability execution.

### C. Mobile validation

- [ ] Run a playable movement test on at least one supported low/mid-tier Android device and one target high-tier Android device.
- [ ] Record device model, OS, renderer, frame rate, test duration and any movement defects.
- [ ] Confirm stable movement at target frame rates and across variable frame times.
- [ ] Confirm touch-input integration is not required for RR-003 itself; it is delivered under RR-006.

### D. CI and regression

- [x] Godot 4.4.1 editor import/class registration succeeds in CI.
- [x] Headless foundation smoke test succeeds in CI run #15.
- [x] Headless movement test script succeeds in CI run #15.
- [ ] Add and pass the deterministic physics tests listed above in CI.
- [ ] Run the full CI suite on the final acceptance commit.

## 3. Acceptance decision

RR-003 may be marked **Accepted** when sections A, B and D are complete and evidence is linked in this file. Section C must be completed before the vertical slice is declared device-validated; any outstanding device check must remain visible as a release risk rather than being silently waived.

The successful CI run #15 verifies that the committed headless scripts execute. It does not, by itself, prove all physical behavior assertions or mobile performance.

## 4. Explicit exclusions

Animation and animation events, camera rig implementation, combat, dodge, abilities, mobile touch UI, obstacle traversal, procedural generation, enemy AI, networking and remote AI are outside RR-003. These belong to their own workstreams.
