# Mobile Input Architecture

**Status:** RR-006 D1-D4 implementation baseline. Guided joystick, free-hand swipe/drag and tap/press recognizers emit semantic commands; gameplay routing remains deferred.

## Goals
- Support Guided (virtual joystick and explicit action controls) and Free-hand (gesture-driven) control modes.
- Translate device events into a stable, device-neutral semantic action vocabulary.
- Keep movement, combat, abilities, game state and health authoritative in existing gameplay systems.
- Keep gesture grammar configurable and testable; do not freeze unvalidated meanings.
- Keep input processing local and deterministic. No remote AI, network dependency or asynchronous service in the input-to-gameplay path.

## Layers and ownership
1. Device recognizers (D2-D4) own pointer tracking, thresholds, gesture classification and cancellation.
2. MobileInputCommand (D1) carries action, phase, mode, normalized movement vector, strength, optional ability ID, source ID and monotonic sequence ID. It contains intent only.
3. The later input router validates commands, applies context/priority policy and dispatches to gameplay interfaces.
4. CharacterMovementController owns movement requests; HeroCombatController owns attack and ability acceptance/cooldowns; game-state systems own pause/menu state.
5. HUD, animation and VFX observe gameplay state; they do not reinterpret raw touch input.

## Command contract
- Actions, phases and modes use MobileInputAction enums.
- MOVE vectors are finite and length <= 1.0; strength is finite and in [0, 1].
- Ability actions require a non-empty ability_id.
- source_id identifies a recognizer/control; sequence_id is non-negative and monotonically increasing per source.
- Non-MOVE actions carry a zero vector. Validate before dispatch.
- A canceled MOVE neutralizes only its source contribution; future router arbitration must prevent one source from canceling another.

## Guided virtual joystick (D2)
- VirtualJoystick is a reusable Control with single-pointer ownership, radial deadzone and clamped normalized MOVE output.
- Screen-right maps to +X and screen-up maps to +Y.
- It emits intent only and never calls movement or changes physics.

## Free-hand swipe and drag recognizer (D3)
- FreeHandGestureRecognizer is a reusable Control with one active pointer. The first pointer beginning inside its rectangle owns the gesture until release/cancel.
- FreeHandGestureProfile selects exactly one recognition mode per instance: cardinal swipe or continuous drag.
- Directional swipe mode compares displacement with a configurable threshold and resolves diagonals by dominant axis (horizontal on ties). Direction-to-action bindings live in the profile.
- Continuous-drag mode activates after its threshold, applies a pixel deadzone, converts screen coordinates to normalized MOVE and emits neutral CANCELED on release or interruption.
- Default bindings (left/right lane change, up jump, down dodge) are provisional and must be validated in playtests.

## Tap and press recognition (D4)
- TapPressGestureRecognizer supports tap, double-tap, triple-tap, long-press and optional pressure-aware hard-press.
- Tap classification is delayed by the configurable multi-tap window. A third tap resolves the sequence as triple-tap rather than emitting a double-tap first.
- Long press fires once at its duration threshold. Movement beyond the tap tolerance cancels the gesture.
- Hard press is disabled by default; pressure support varies by device and must be validated before enabling.
- Gesture-to-action bindings are profile data and provisional. Discrete actions emit FREE_HAND STARTED/PERFORMED pairs.
- Focus loss, tree exit and explicit cancellation clear active and pending gesture state.
- The recognizer emits commands only; it never invokes gameplay controllers or mutates physics.

## Context and lifecycle
- Pause, menus, dialogs, loading, death and transitions must suppress gameplay commands; router/context work owns this policy.
- UI-consumed touches must not leak into gameplay recognizers.
- Recognizers track pointer IDs. On focus loss, app suspension, scene/mode change or control destruction, cancel active recognizers.
- Commands run on the main gameplay thread. No remote calls, awaits, network responses or AI inference in the input-to-gameplay path.

## Planned sequence
- D1: semantic command contract and CI tests.
- D2: guided virtual joystick.
- D3: free-hand directional swipe/drag recognizer.
- D4: tap/press recognition.
- D5: gameplay action routing and hero capability validation.
- D6: mode switching, context suppression, settings and accessibility.
- D7: multi-source arbitration, buffering and lifecycle hardening.
- D8: integration tests, device validation and performance baseline.
