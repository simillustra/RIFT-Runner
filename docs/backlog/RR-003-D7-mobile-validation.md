# RR-003 D7 — Mobile movement validation recorder and device protocol

## Objective

Make RR-003 movement validation repeatable on physical Android/iOS devices and preserve measurable evidence. This milestone provides the recorder and protocol; it does not claim that physical-device tests have already been run.

## Runtime recorder

Attach `MovementValidationRecorder` to a movement test scene. After the production `CharacterActor` has entered the tree and its `CharacterMovementController` is operational:

```gdscript
@onready var recorder: MovementValidationRecorder = $MovementValidationRecorder
@onready var actor: CharacterBody3D = $CharacterActor
@onready var movement: CharacterMovementController = $CharacterActor/MovementController

func start_device_run() -> void:
    if not recorder.begin_capture(actor, movement):
        push_warning("Movement validation capture could not start.")

func stop_device_run() -> void:
    var report := recorder.finish_capture()
    print(JSON.stringify(report, "\t"))
```

The recorder captures OS, device model, screen dimensions, Godot version, configured renderer, session duration, average/minimum sampled FPS, p95 frame time, and per-frame actor position, velocity, grounded state, lane index and movement mode. Reports are written to `user://rr003_movement_validation_<timestamp>.json`. No network calls or remote AI are involved.

## Physical-device protocol

Run on:
- At least one supported low/mid-tier Android device.
- One target high-tier Android device.
- iOS device(s) where required by the release target.

For each device:
1. Record device model, OS version, Godot build, renderer and display resolution.
2. Use the same production character definition and test arena.
3. Run lane movement: center → both outer lanes → repeated boundary input; verify no overshoot or lane-index drift.
4. Run free movement: cardinal and diagonal directions, camera yaw/pitch changes, release-to-stop, and repeated direction changes.
5. Run jump/landing cycles and confirm grounded transitions; test slopes and wall contact.
6. Exercise the test for at least 10 minutes, including repeated transitions between movement modes if the gameplay harness supports it.
7. Save the JSON report and attach a short screen recording plus notes on input feel, camera-relative direction, collision defects, thermal throttling and frame pacing.

## Review targets

These are validation targets, not measured results:
- Mid/high-tier target: 60 FPS, p95 frame time ≤ 16.67 ms.
- Low-tier fallback: stable 30 FPS, p95 frame time ≤ 33.33 ms.
- Investigate sustained frame-time spikes, lane drift, collision tunnelling, inconsistent jump height, or non-zero residual movement after release.

Do not mark a device row passed based on editor/desktop CI. Record actual device model, OS, renderer, run duration, report artifact and reviewer. A failed or unavailable device run remains open.

## Automated validation

`tests/movement_validation_recorder_d7_test.gd` validates capture lifecycle, invalid-delta rejection, device metadata, FPS/frame-time statistics and movement-state samples. CI runs it after Godot editor import.

## Acceptance boundary

D7 is implemented when recorder contract tests pass in CI and this protocol is available. RR-003 remains formally unaccepted until the D1–D6 CI regressions pass on the final integration commit and physical-device evidence is attached for the required Android/iOS matrix.
