# Software Requirements Specification
## Context
Godot is the game runtime; local services support offline play. Nakama and Python/FastAPI AI orchestration are future optional services.

## Functional requirements
FR-001 boot locally without network. FR-002 expose application phases. FR-003 load validated character Resources with stable IDs. FR-004 reject duplicate/malformed roster entries. FR-005 actor accepts only valid definitions. FR-006 settings/save persist locally with error handling. FR-007 online/AI integrations remain optional.

## Non-functional requirements
Typed GDScript; deterministic/testable boot; no remote calls in frame-critical loops; mobile performance measured on nominated devices; no secrets in Git; smoke tests in CI.

## Interfaces
Godot Resources are local content contracts. Future network APIs use versioned DTOs, not serialized live Resources. Map each requirement to backlog acceptance criteria and reproducible evidence.
