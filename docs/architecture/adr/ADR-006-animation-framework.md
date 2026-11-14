# ADR-006: Character Animation Framework

- **Status:** Accepted design baseline; implementation subject to RR-004 review
- **Date:** 2026-11-14
- **Workstream:** RR-004

## Context

RIFT RUNNERS requires reusable third-person character animation for Vanguard, Phantom and Cipher. RR-003 owns physical movement; RR-005 will own combat outcomes. The current CharacterActor has a visual placeholder and movement controller but no production rig or animation graph. Gameplay correctness must not depend on animation clips.

## Decision

1. Use Godot 4.4.1 AnimationTree for blending/state-machine playback, backed by AnimationPlayer.
2. Use a shared typed CharacterAnimationController Node as a presentation-only consumer.
3. Use typed AnimationProfile Resources for hero-specific semantic clip mappings and tuning.
4. Consume a read-only movement-state snapshot; do not read private controller state or mutate CharacterBody3D.
5. Centralize and validate AnimationTree parameter paths at initialization.
6. Missing optional visual assets disable animation safely without blocking offline gameplay.
7. Animation markers emit presentation-only events; gameplay outcomes remain owned by movement/combat systems.
8. No runtime AI, network service or per-frame asset loading.

## Consequences

- Shared behavior remains consistent while hero-specific mappings stay data-driven.
- A minimal read-only movement API is required; current RR-003 does not expose the complete animation state contract.
- Rig retargeting and final clip selection remain open until licensed production assets are chosen.
- Headless tests validate resources/state behavior; visual quality requires a visual scene and device review.
- Sprint presentation remains disabled until an authoritative sprint state is introduced.

## Alternatives

- AnimationPlayer-only playback: simpler but less suitable for reusable locomotion blending.
- Animation logic embedded in CharacterActor: rejected because it couples movement and presentation.
- Per-hero controller scripts: rejected because shared behavior would be duplicated.
- Runtime AI-generated animation: rejected for determinism, latency, licensing and offline requirements.
