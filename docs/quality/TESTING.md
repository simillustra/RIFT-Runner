# Testing Strategy

## Foundation
Run the built-in headless smoke test from the repository root:

    godot --headless --path . --script res://tests/smoke_test.gd

Expected summary: RR-001 smoke test: PASS and exit code 0.

## Test layers
- **Smoke:** project loads, autoloads exist, boot state initializes, local save round-trip works.
- **Unit:** pure gameplay rules and data transformations, added alongside each feature.
- **Integration:** scene composition, input-to-controller behavior, combat interactions, save migrations.
- **Performance:** target-device frame-time, memory, thermal and load-time profiling.
- **Platform:** Android install/launch/input/resume; iOS project/export validation and device checks where signing and hardware are available.

## Quality gates
A task cannot be marked complete solely because it parses. Include behavioral tests and record actual engine version, command, exit status, and output. A CI workflow definition is not evidence of a successful CI run.
