# RR-007 D2 — Segment Socket Compatibility

**Status:** Implementation in review · Godot 4.4.1

## Contract
Each authored segment declares Marker3D entry/exit paths and connector profile IDs with width/height dimensions. Adjacent segments may connect only when the previous exit and next entry share a connector ID and matching dimensions within tolerance.

The generator aligns each new segment's entry socket transform to the preceding segment's exit socket transform. This supports authored offsets and rotations; placement no longer assumes every segment begins at its root origin or has a uniform length.

## Acceptance evidence
- Missing or invalid socket markers fail resource validation.
- Incompatible connector IDs or dimensions are rejected.
- Adjacent entry/exit transforms match.
- Seeded selection remains reproducible.
- Generation reports failure when no compatible continuation exists.

## Boundaries
Branching, traversal/hazard sockets, runtime streaming, pooling and memory budgets are later milestones. Authored segment scenes must provide their own collision and visual content.
