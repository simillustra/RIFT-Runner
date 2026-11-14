# RR-004 D7 — Validation Evidence Matrix

**Current status:** No production hero rig or device capture has been recorded in this repository.  
**Automated baseline:** See `tests/animation_rig_validation_test.gd`; its empty fixture clips are not visual proof.

## Hero asset validation

| Hero | Production rig | Skeleton/retargeting | Required clips | Visual transitions | Result / evidence |
|---|---|---|---|---|---|
| Vanguard | Not supplied | Not tested | Fixture only | Not tested | Open |
| Phantom | Not supplied | Not tested | Fixture only | Not tested | Open |
| Cipher | Not supplied | Not tested | Fixture only | Not tested | Open |

## Device validation

| Target | Device / OS | Build commit | Renderer | FPS / frame-time | Memory | Result / evidence |
|---|---|---|---|---|---|---|
| Android low/mid tier | Not recorded | — | — | — | — | Not tested |
| Android high tier | Not recorded | — | — | — | — | Not tested |
| iOS | Not recorded | — | — | — | — | Not tested |

## Required capture notes

For every run, record:
- Device model, SoC/GPU, RAM and OS version.
- Build commit SHA, Godot version, renderer and display refresh rate.
- Average FPS and observed frame-time spikes during idle, directional movement and jump/landing transitions.
- Memory observations and any thermal throttling.
- Missing resources, animation warnings, skeleton/retargeting defects and visual artifacts.
- Link to screenshots/video and tester/date.

## Automated checks versus manual evidence

The D7 CI test validates that the three profiles resolve against a known AnimationPlayer clip library and that their generated state-machine graphs reference available clips. It does not load production assets or simulate a rendered character. Manual hero and device rows must remain open until evidence is attached.
