# Procedural Generation
**Owner:** RR-007. **Status:** D1-D2 merged; D3 placement-socket contract implemented, CI pending.

## Design
Compose authored modular segments with deterministic seeded selection. Each WorldSegmentDefinition declares a stable segment ID, theme ID, PackedScene, entry/exit connector profiles and transform sockets. Adjacent segments align by their authored Marker3D transforms.

## Placement sockets
Each segment may author arrays of Marker3D paths for obstacle, traversal and hazard placement. The generator exposes these sockets for later content placement. Socket discovery is metadata only: it does not spawn content or make a segment traversable by itself.

## Planned themes
- Infected City
- Alien Facility

## Delivery sequence
1. D1: segment Resource contract and deterministic linear composition.
2. D2: entry/exit sockets, connector profile validation and transform-based adjacency.
3. D3: obstacle, traversal and hazard placement sockets.
4. D4: encounter spawn anchors and difficulty pacing.
5. D5: runtime streaming, pooling, unload and memory budgets.
6. D6: authored theme kits and procedural QA/seed regression.

Production segments still need authored collision, traversal, navigation and visual assets.
