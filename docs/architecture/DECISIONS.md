# Architecture Decision Records

## ADR-001: Godot 4.x with typed GDScript
**Status:** Accepted  
**Decision:** Use Godot 4.x stable and typed GDScript for the game client.  
**Rationale:** Fast iteration, native scene/editor workflow, and suitability for a mobile 3D vertical slice.  
**Consequences:** Pin the exact engine patch and export templates in CI/release environments. Use C++ GDExtension only when profiling justifies it.

## ADR-002: Offline-first single-player
**Status:** Accepted  
**Decision:** The game must boot and support core single-player without network access.  
**Rationale:** Reliability, mobile connectivity variability, and protection from backend availability.  
**Consequences:** Online systems are optional adapters; local save/config works independently.

## ADR-003: Separate AI orchestration service
**Status:** Accepted  
**Decision:** AI provider integration belongs in a separate Python/FastAPI service with OpenAI, Amazon Bedrock, and custom adapters.  
**Rationale:** Provider portability, secret isolation, and separation from latency-sensitive gameplay.  
**Consequences:** No provider SDK or API key belongs in the Godot client. AI calls are not permitted in real-time movement/combat/enemy loops.

## ADR-004: Deterministic real-time enemy logic
**Status:** Accepted  
**Decision:** Use deterministic in-engine FSM/behavior logic for real-time enemies.  
**Rationale:** Predictable frame-time, reproducible tests, and offline operation.  
**Consequences:** Remote AI may assist tooling/content workflows later but cannot control moment-to-moment enemy decisions.
