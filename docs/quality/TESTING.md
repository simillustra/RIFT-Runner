# Testing Strategy

## Headless setup and smoke test
Run the editor import/class scan first so Godot registers project-wide script classes:

    godot --headless --editor --path . --quit

Then run:

    godot --headless --path . --script res://tests/smoke_test.gd

Expected summary: RIFT RUNNERS smoke test: PASS and exit code 0.

## Test layers
- **Smoke:** project loads, autoloads exist, boot state initializes, local settings/save round-trip works, RR-002 character Resources validate and actor assignment works.
- **Unit:** pure gameplay rules and data transformations, added alongside each feature.
- **Integration:** scene composition, input-to-controller behavior, combat interactions, save migrations.
- **Performance:** target-device frame-time, memory, thermal and load-time profiling.
- **Platform:** Android install/launch/input/resume; iOS project/export validation and device checks where signing and hardware are available.

## Quality gates
A task cannot be marked complete solely because it parses. Include behavioral tests and record actual engine version, command, exit status and output. A workflow definition is not evidence of a successful CI run.
