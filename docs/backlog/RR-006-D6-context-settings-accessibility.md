# RR-006 D6 — Mode Switching, Context Suppression, Settings and Accessibility

## Objective

Provide one local, deterministic owner for Guided/Free-hand mode selection, gameplay input contexts, player input preferences and accessibility options. Transitions must cancel old recognizers and neutralize movement before the next input mode becomes active.

## Architecture

- `MobileInputContextController` owns the selected `MobileInputAction.Mode`, gameplay context and registered recognizer controls.
- `MobileInputRouter` remains the gameplay dispatch authority. The context controller gates it; it does not bypass or duplicate action validation.
- Registered controls declare their mode. Only controls matching the selected mode are visible, process input and accept mouse/touch interaction.
- Contexts: GAMEPLAY, PAUSED, MENU, DIALOG, LOADING, DEAD, TRANSITION and CUTSCENE. Only GAMEPLAY accepts gameplay commands.
- A mode/context transition cancels every active recognizer while the old router context is still valid, disables routing and neutralizes movement, changes state and control visibility, then re-enables routing only when entering GAMEPLAY.
- Commands are accepted only when the registered control mode, command mode and current mode all agree.
- No remote AI, networking, asynchronous calls or real-time service dependencies are introduced.

## Settings and accessibility

`MobileInputSettings` validates and persists:
- Left/right joystick side preference (the HUD layout owner consumes the layout signal).
- Joystick scale and radial deadzone.
- Swipe/drag sensitivity.
- Long-press and multi-tap timing.
- High-contrast joystick rendering.

Settings are stored locally through Godot `ConfigFile` at `user://mobile_input_settings.cfg`. Invalid settings are rejected rather than silently clamped. Profile resources are duplicated before applying player overrides so shared defaults are not mutated.

The left-handed preference is exposed through `left_handed_layout_requested`; actual safe-area positioning belongs to the HUD/layout milestone. Haptics, remappable action layouts and screen-reader narration are not claimed as implemented.

## Acceptance criteria

- [ ] Guided and Free-hand controls can be registered and switched atomically.
- [ ] Mode change cancels active pointers and neutralizes movement before new controls are enabled.
- [ ] Only controls for the selected mode are visible and process input.
- [ ] PAUSED, MENU, DIALOG, LOADING, DEAD, TRANSITION and CUTSCENE suppress gameplay input.
- [ ] Returning to GAMEPLAY restores only the currently selected control mode.
- [ ] Stale-mode commands are rejected even if emitted by a previously active recognizer.
- [ ] Context transitions cancel pending tap/press sequences and active joystick/drag gestures.
- [ ] Settings are validated, applied, saved and loaded from user-local ConfigFile storage.
- [ ] Joystick scale, deadzone, left/right preference, gesture sensitivity, press timing and high contrast are represented.
- [ ] Shared default gesture resources are not mutated by user overrides.
- [ ] Invalid enum values and out-of-range settings are rejected.
- [ ] Headless tests cover mode/context transitions, cancellation, routing suppression, settings round-trip and accessibility application.
- [ ] Godot 4.4.1 CI imports the project and runs D1-D6 input suites plus existing regressions.

## Test plan

1. Register guided joystick and free-hand swipe/tap controls.
2. Confirm only Guided controls are active initially.
3. Begin joystick movement; switch to Free-hand; assert cancellation, neutral movement and correct visibility.
4. Enter each non-gameplay context and verify routing is disabled and recognizers are cancelled.
5. Restore GAMEPLAY and verify only the selected mode is enabled.
6. Emit a command from an inactive mode and verify it cannot reach gameplay.
7. Apply settings, verify joystick/profile changes, save and reload, and reject invalid values.
8. Run the complete CI suite.

## Device validation still required

- Verify left/right joystick layout against notches, rounded corners and Android navigation regions.
- Test touch target reachability, one-handed reach, contrast and gesture thresholds on low/mid/high DPI devices.
- Validate app background/resume, incoming calls, OS permission overlays and pause/death/menu transitions.
- Record device, OS, resolution, control mode, settings, build and observed defects. CI is not device acceptance.
