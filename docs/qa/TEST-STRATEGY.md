# Test Strategy
Automated: headless smoke (boot/autoloads/state/settings/save/character resources/actor); unit tests for validation and deterministic rules; integration tests for scenes/input/combat/persistence; CI on pushes and PRs.

Manual/device: Android touch, lifecycle/resume, performance, thermal, memory, audio and display scaling. iOS export needs Apple toolchain/signing. Record engine, device/OS, build, command, result and logs. A configured workflow is not a passing run.
