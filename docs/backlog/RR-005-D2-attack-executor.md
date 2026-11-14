# RR-005 D2 — Attack Definitions and Deterministic Executor

**Status:** Implementation in review  
**Branch:** `feat/rr-005-d2-attack-executor`  
**Engine:** Godot 4.4.1 · Typed GDScript

## Goal

Add reusable attack data and a deterministic runtime phase controller. D2 accepts explicit hit confirmations from a caller; it does not perform collision queries. RR-005 D3 will provide hit detection and target filtering.

## Delivered in D2

- `AttackDefinition` typed Resource with stable ID, display metadata, damage amount/type and startup, active, recovery and cooldown durations.
- `AttackDefinition.validate()` rejects missing IDs/names/types, non-positive damage/active duration and invalid timing values.
- `AttackExecutor` with IDLE, STARTUP, ACTIVE, RECOVERY and COOLDOWN phases.
- Deterministic timer stepping that carries excess delta across phase boundaries.
- Explicit `try_hit(HealthComponent)` API, accepted only during ACTIVE.
- One target registration per attack instance; repeated overlaps cannot apply duplicate damage.
- Damage always routes through D1 `HealthComponent.apply_damage()`.
- Cancellation, phase signals, active-window signals, hit confirmation and completion signals.
- Headless tests for validation, phase boundaries, rejected calls, cooldown, target de-duplication, cancellation, zero-length optional phases and large timer steps.

## Public API

- `begin_attack(definition, source = null) -> Error`: starts only while IDLE and only for a valid definition.
- `try_hit(target) -> float`: registers one confirmed target during ACTIVE and returns actual damage applied.
- `has_registered_hit(target) -> bool`: queries whether a target has already been registered for the current attack.
- `update_timers(delta)`: deterministic timer step; also called by `_process`.
- `cancel_attack()`: cancels the current attack and returns to IDLE.

## Timing semantics

1. STARTUP: no hits accepted.
2. ACTIVE: caller may submit confirmed overlaps; each target is registered once.
3. RECOVERY: no hits accepted.
4. COOLDOWN: no new attack can begin.
5. IDLE: executor is ready for another attack.

Cooldown begins after recovery. A zero startup, recovery or cooldown is supported; active duration must be positive. Large deltas are consumed across sequential phases rather than discarded.

## Boundaries

- D2 does not create physics hitboxes, hurtboxes, raycasts, overlap queries or faction/team filtering.
- D2 does not read animation tracks or wait for animation completion.
- D2 does not implement combos, buffered input, stamina, poise, stagger, knockback or abilities.
- The executor does not own target health; it delegates damage to D1.
- A target is registered once even if HealthComponent rejects damage (for example, invulnerability), preventing repeated overlap callbacks from reattempting the same attack.

## Acceptance checks

- [x] Attack definition validation.
- [x] Startup, active, recovery and cooldown phase contract.
- [x] Explicit active-window hit registration.
- [x] One registration per target per attack instance.
- [x] D1 health component receives damage.
- [x] Cancellation and phase signal contract.
- [x] Large-delta and zero optional phase timing tests.
- [ ] Godot 4.4.1 CI passes on this branch.
- [ ] Review and merge.

## Next D3

Add collision-based hit detection and target filtering. D3 must submit confirmed eligible HealthComponent targets to `AttackExecutor.try_hit()`; it must not apply damage directly or bypass the D2 active window.
