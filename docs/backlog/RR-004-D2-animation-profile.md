# RR-004 D2 — AnimationProfile Resource

**Status:** Implemented on D2 branch; Godot CI validation pending.

## Resource

`AnimationProfile` is a typed Godot Resource in `game/scripts/characters/animation_profile.gd`. It contains a stable profile ID, optional rig compatibility key, semantic state-to-clip map, required state list, fallback clip and locomotion tuning.

Supported semantic identifiers: `idle`, `start`, `move`, `stop`, `jump_start`, `rising`, `falling`, `landing`, `hit_react`, and `sprint`.

The resource is data-only. It does not play animations or mutate gameplay state.

## Validation contract

`validate(available_clips: PackedStringArray = PackedStringArray()) -> PackedStringArray` checks:
- non-empty profile ID and fallback clip;
- known required/mapped semantic state names;
- all required states have non-empty clip mappings;
- mapped clip identifiers are non-empty;
- optional clip-library verification when names are supplied;
- valid idle hysteresis thresholds;
- positive reference speed and playback-rate bounds.

An empty `available_clips` argument performs structural validation only. Supplying clip names also checks every mapped/fallback clip against the available animation library.

## Runtime helpers

- `get_clip(state_name)` returns the configured mapping or the fallback clip for optional/unmapped states.
- `get_playback_rate(planar_speed)` converts speed relative to reference speed and clamps to configured minimum/maximum.

## Fixture and tests

`tests/fixtures/animation_profiles/valid_animation_profile.tres` is a test fixture with semantic clip identifiers. It does not imply production animation assets exist.

Run after editor import/class registration:

```sh
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/animation_profile_test.gd
```

The D2 milestone is accepted only when the Godot 4.4.1 CI job passes and the profile resource loads without parser/import warnings.
