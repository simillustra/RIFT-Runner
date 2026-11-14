# RR-005 D7 — Combat Tuning, Performance and Encounter Validation

**Status:** Implementation in review  
**Branch:** `feat/rr-005-d7-combat-validation`  
**Engine:** Godot 4.4.1 · Typed GDScript

## Goal

Establish repeatable balance regression checks for the three launch heroes, define mobile combat performance budgets, and record the device/encounter evidence required before combat sign-off.

## Delivered

- A deterministic hero-versus-baseline encounter test runs the real Vanguard, Phantom and Cipher attack resources through D2 `AttackExecutor` into D1 `HealthComponent`.
- The test verifies startup cannot deal damage, damage is applied only in the active window, attack cycles complete, expected hit counts remain stable, and target death remains owned by D1.
- The test reports simulated time-to-kill (TTK) and attack-cycle duration for each hero.
- CI runs the D7 encounter regression alongside all D1-D6 suites.
- This document defines provisional mobile performance budgets and a manual device/encounter validation protocol.

## Baseline balance regression

Target: a 100 HP, zero-defense, zero-invulnerability training target. Time is deterministic simulation time, advanced in 10 ms steps; it is not wall-clock benchmark time.

| Hero | Basic attack damage | Full attack cycle | Hits to defeat 100 HP | Baseline simulated TTK |
|---|---:|---:|---:|---:|
| Vanguard | 24 | 1.06 s | 5 | 5.30 s |
| Phantom | 20 | 0.64 s | 5 | 3.20 s |
| Cipher | 18 | 0.85 s | 6 | 5.10 s |

These values are regression baselines derived from the current authored attack resources, not a claim that the heroes are finally balanced. Any intentional balance change must update the expected values and include a design rationale.

## Provisional mobile performance budgets

The following are targets for profiling, not measured results:

| Metric | Mid-tier Android target | Low-tier fallback target |
|---|---:|---:|
| Frame rate | 60 FPS | 30 FPS minimum |
| Frame time | 16.67 ms | 33.33 ms |
| Combat-system CPU time | ≤2 ms p95 | ≤4 ms p95 |
| Concurrent active combatants | 20 | 10 |
| Physics tick | 60 Hz | 30–60 Hz, device verified |

Profiling protocol:
1. Use an exported release build, not the editor or headless CI build.
2. Profile a repeatable encounter with 1, 5, 10 and 20 active combatants.
3. Capture at least 60 seconds after warm-up for each run.
4. Record device model, OS, build commit, average FPS, 1% low FPS, frame-time p95, combat CPU p95, physics CPU and peak memory.
5. Repeat each run three times; investigate sustained frame-time budget violations and spikes during simultaneous hit reactions/deaths.
6. Do not claim device performance acceptance until measurements and device captures are attached to the release evidence.

## Encounter validation checklist

- [ ] Vanguard, Phantom and Cipher each defeat the baseline target within the regression envelope.
- [ ] Attack startup, active, recovery and cooldown windows remain authoritative in D2.
- [ ] Repeated overlap does not produce multiple hits per target per attack.
- [ ] Same-team and self-hit filtering remain enforced by D3.
- [ ] Boss armored/exposed/enraged multipliers preserve D1 damage ownership.
- [ ] Stagger/knockback does not bypass movement ownership or allow dead actors to move.
- [ ] A representative multi-enemy encounter completes without script errors, stuck hitboxes or actors remaining targetable after death.
- [ ] Android release build profiling evidence is attached.
- [ ] iOS export/build validation evidence is attached.
- [ ] Combat designer signs off hero matchup, readability, hit feedback and boss pacing.

## Architecture boundaries

- D1 owns health, defense, damage reception and death.
- D2 owns attack phases and one-hit-per-target registration.
- D3 owns collision overlap and target filtering.
- D4/D5 own hero/enemy/boss combat entry points and boss damage phase multipliers.
- D6 owns local hit reaction, stagger, knockback and death response.
- D7 validates and tunes the existing contracts; it does not introduce a second damage path, real-time remote AI, or device-specific gameplay forks.

## Known limitations / exit criteria

The automated D7 test is deterministic and validates authored combat timing; it does not measure wall-clock performance, collision throughput on a phone, visual readability, animation quality, or boss encounter fun. Production character rigs, full encounter scenes and physical Android/iOS devices are still required for those sign-offs. D7 remains in review until CI passes and the manual evidence checklist is completed.
