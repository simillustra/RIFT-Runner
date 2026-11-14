# RR-007 D3 — Obstacle, Traversal and Hazard Placement Sockets

**Status:** Implementation submitted for Godot 4.4.1 CI validation.

## Contract
Authored segment scenes expose named Marker3D placement anchors through WorldSegmentDefinition path arrays: obstacle, traversal and hazard. Resource validation rejects paths that do not resolve to Marker3D. ProceduralWorldGenerator exposes the typed anchors for a generated segment by category.

This milestone defines stable placement metadata and discovery only. It does not spawn gameplay content, randomize obstacle patterns, guarantee traversal fairness, or implement hazard behavior; those require D4 encounter pacing and authored content policies.

## Acceptance evidence
- Each category path resolves to a Marker3D.
- Invalid placement paths fail segment validation.
- Generated segments return the configured category sockets.
- Existing seeded selection and entry/exit alignment remain deterministic.
