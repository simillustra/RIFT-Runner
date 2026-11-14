# Procedural Generation
**Owner:** RR-007. **Status:** D1 merged; D2 socket compatibility in review.

## Design
Compose authored modular segments with deterministic seeded selection. Each WorldSegmentDefinition declares a stable segment ID, theme ID, local forward length and PackedScene. ProceduralWorldGenerator places segment roots along local negative Z and can reproduce a sequence from the same seed and ordered definition list.

## Planned themes
- Infected City
- Alien Facility

## Delivery sequence
1. D1: segment Resource contract and deterministic linear composition.
2. D2: authored Marker3D entry/exit sockets, connector profile validation and transform-based adjacency (implemented).
3. D3: obstacle, traversal and hazard placement sockets.
4. D4: encounter spawn anchors and difficulty pacing.
5. D5: runtime streaming, pooling, unload and memory budgets.
6. D6: authored theme kits and procedural QA/seed regression.

D1 is not yet a complete streaming or branching generator. Production segments still need authored collision, traversal, navigation and visual assets.
