# RR-007 D1 — Segment Contract and Deterministic Generator

**Status:** Initial implementation in review  
**Engine:** Godot 4.4.1 · Typed GDScript

## Scope
- Define an authored segment Resource with stable ID, theme ID, length, PackedScene and validation.
- Compose a linear sequence of Node3D segment scenes along local negative Z.
- Use a configurable integer seed and RandomNumberGenerator for reproducible selection.
- Support reset, append, initial generation and generated-ID inspection.
- Reject invalid definitions and non-Node3D scene roots.

## Current boundaries
This is the deterministic composition foundation, not the full streaming world system. It does not yet implement entry/exit sockets, branching routes, traversal compatibility, obstacle/hazard spawn points, difficulty curves, pooling, unload distance, navigation baking or memory budgets. Production themes remain Infected City and Alien Facility.

## Acceptance evidence
- Invalid definitions are rejected.
- Requested segment count is generated.
- Segment placement advances along local -Z using each segment's authored length.
- Repeating the same seed and ordered definition list reproduces the same IDs and positions.
- CI runs tests/procedural_world_generator_test.gd.
