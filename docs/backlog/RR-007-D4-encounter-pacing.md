# RR-007 D4 — Encounter Spawn Anchors and Difficulty Pacing

**Status:** Implementation submitted for Godot 4.4.1 CI validation.

World segments can declare authored encounter spawn Marker3D paths. The generator retains the exact WorldSegmentDefinition resource on each generated segment and exposes the resolved anchors. EncounterSpawnDirector produces a deterministic spawn plan from segment index, difficulty level, world seed and EncounterPacingProfile.

The plan contains a budget, selected world transforms and a maximum-concurrent cap. It deliberately does not instantiate enemies, own enemy lifetimes, or bypass RR-008 archetype configuration. Production spawn execution, fairness review, and playtest tuning remain follow-up work.

Acceptance evidence:
- Spawn paths validate against the packed segment scene.
- Generated segment exposes its configured spawn anchors.
- Budget is bounded and scales deterministically with progression/difficulty.
- Same seed and inputs return the same spawn transforms.
- Spawn count respects available anchors, budget cost and profile limits.
