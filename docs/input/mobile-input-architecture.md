# Mobile Input Architecture

**Status:** RR-006 D1-D8 implementation baseline. Automated integration and headless throughput diagnostics are included; physical Android/iOS, HUD safe-area and usability sign-off remains outstanding.

## Goals

- Support the two product control modes: **Guided** (virtual joystick and explicit action controls) and **Free-hand** (gesture-driven).
- Translate device-specific events into a stable, device-neutral semantic action vocabulary.
- Keep movement, combat, abilities, game state and character health authoritative in their existing gameplay systems.
- Make gesture grammar configurable and testable; do not freeze unvalidated gesture meanings in the input contract.
- Keep input processing local and deterministic. No remote AI, network dependency or asynchronous service is permitted in the input-to-gameplay path.

## Layers and ownership

1. **Device recognizers (RR-006 D2-D4):** joystick, touch, swipe and press recognizers. They own pointer tracking, thresholds, gesture classification and cancellation.
2. **Semantic command (D1):** `MobileInputCommand` carries action, phase, mode, normalized movement vector, strength, optional ability ID, source ID and monotonic sequence ID. It contains intent only.
3. **Input router (D5/D7):** validates commands, applies context/priority policy, buffers only eligible discrete actions and dispatches supported actions to gameplay interfaces. It must not contain movement physics, attack timing or ability effects.
4. **Gameplay authorities:** `CharacterMovementController` owns movement requests; `HeroCombatController` owns basic attack and ability acceptance/cooldowns; game-state systems own pause/menu state.
5. **Presentation:** HUD, animation and VFX observe gameplay state; they do not reinterpret raw touch input.

## Context, priority and lifecycle

- D6 owns atomic control-mode and gameplay-context transitions, local settings and accessibility preferences.
- D7 arbitrates simultaneous movement sources by priority, uses stable lexical tie-breaks and clears transient state on cancellation, focus loss and teardown.
- See [D8 validation protocol](../backlog/RR-006-D8-integration-device-validation.md) for end-to-end integration, performance diagnostics and physical-device evidence requirements.

## Determinism and authority

- Commands are processed on the main gameplay thread.
- No remote AI, network call, await or asynchronous service may be introduced into the input-to-gameplay path.
- Only the router dispatches accepted semantic commands; movement/combat systems remain authoritative.
- Headless timings are diagnostics, not physical-device latency or frame-time evidence.
