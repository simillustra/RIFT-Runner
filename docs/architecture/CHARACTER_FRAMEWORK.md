# Character Framework

## Responsibility boundaries
- **CharacterStats:** typed baseline numerical attributes only.
- **AbilityDefinition:** ability identity and design metadata only; no executable effects or cooldown timers.
- **CharacterDefinition:** character identity, archetype, stats, and ability references.
- **CharacterRoster:** collection validation and lookup by stable character ID.
- **CharacterActor:** scene-level character body and definition assignment. It does not own movement, animation, combat, input, or progression.

## Extension points
- RR-003 movement consumes movement-related stat values through a controller interface.
- RR-004 animation maps actor state and authored animation data.
- RR-005 combat consumes attack/defense values and defines combat/ability execution.
- RR-006 input translates device actions into intent; it does not directly mutate character definitions.
- Future multiplayer adapters replicate stable IDs and authoritative state, not Resource object instances.

## Data integrity
Validate resources before adding them to a roster or assigning them to an actor. IDs are stable content identifiers and must not be repurposed. Keep balance values in data assets so they can be tuned without changing actor behavior.
