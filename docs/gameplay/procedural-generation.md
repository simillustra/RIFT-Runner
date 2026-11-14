# Procedural Generation
**Owner:** RR-007. **Status:** D1-D3 implementation in review; D4 encounter planning submitted for CI validation.

## Design
Compose authored modular world segments with deterministic seeded selection. Each WorldSegmentDefinition declares stable IDs, a PackedScene, connector profiles and Marker3D transform sockets. Adjacent segments align by authored entry/exit transforms.

## Placement and encounter anchors
Obstacle, traversal, hazard and encounter spawn paths are authored as Marker3D paths on each segment definition. The generator retains the exact definition resource on the generated instance and resolves anchors from it. EncounterSpawnDirector uses spawn anchors to produce a deterministic plan; it does not instantiate enemies.

## Difficulty pacing
EncounterPacingProfile computes a bounded budget from segment progression and difficulty level. Spawn selection is seeded from world seed, segment index and difficulty level. The plan respects authored anchor count, spawn cost, maximum count and concurrency cap.

## Themes and delivery sequence
- Infected City
- Alien Facility

1. D1: segment Resource and deterministic linear composition.
2. D2: entry/exit connector profiles and transform alignment.
3. D3: obstacle, traversal and hazard placement sockets.
4. D4: encounter spawn anchors and difficulty pacing.
5. D5: runtime streaming, pooling, unload and memory budgets.
6. D6: authored theme kits and procedural QA/seed regression.

Production segments still require authored collision, traversal, navigation, spawn and visual assets.
