# RR-002 — Character Framework

**Priority:** P0  
**Status:** Implementation in progress  
**Depends on:** RR-001 — Project Foundation (merged)

## Goal
Establish reusable, data-driven character identity and baseline attribute definitions for the planned hero roster without implementing movement, animation, or combat.

## Scope
- Typed resources for character identity, archetype, stats, and ability metadata.
- A validated character roster with stable ID lookup and duplicate detection.
- A lightweight CharacterBody3D actor root with a placeholder collision shape and safe definition assignment.
- Initial data assets for Vanguard, Phantom, and Cipher.
- Automated tests for resource loading, validation, lookup, and actor assignment.
- Documentation of ownership boundaries for future movement, animation, input, and combat systems.

## Acceptance criteria
- [ ] CharacterStats validates numeric ranges and provides explicit typed attributes.
- [ ] AbilityDefinition provides descriptive metadata only and validates required fields.
- [ ] CharacterDefinition validates identity, stats, and ability metadata.
- [ ] CharacterRoster validates all entries, detects duplicate IDs, and resolves heroes by stable ID.
- [ ] Vanguard, Phantom, and Cipher load from data assets with unique IDs and one signature ability metadata record each.
- [ ] CharacterActor accepts valid definitions and rejects null/invalid definitions.
- [ ] Actor scene has a usable 3D collision placeholder and does not implement movement, animation, or combat.
- [ ] Headless smoke test covers RR-002 loading and assignment.
- [ ] Documentation and backlog status are updated.
- [ ] CI passes on the PR head.

## Non-goals
Movement controllers, camera behavior, animation graphs, combat, ability execution, input bindings, character progression, hero visuals, multiplayer replication, and AI are separate backlog items.

## Data conventions
Character IDs and ability IDs are stable StringName identifiers. Stats and ability values are tuning metadata, not behavior. Future systems consume these resources through narrow interfaces and must not add runtime responsibilities to the data resources.
