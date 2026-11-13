# Architecture

## Runtime boundaries
- **Godot client:** rendering, input, movement, combat, deterministic enemy logic, scene lifecycle, local settings and saves.
- **Native extension:** optional C++ GDExtension modules only after profiling identifies a CPU-bound operation that cannot reasonably be optimized in GDScript.
- **Backend (future):** Nakama for identity, matchmaking, authoritative online features, and co-op services. The client remains usable offline.
- **AI orchestration (future):** separate Python/FastAPI service with provider adapters for OpenAI, Amazon Bedrock, and custom providers. Provider selection belongs behind a stable interface. Remote inference is never part of the real-time game loop.

## Dependency direction
Presentation/scenes depend on gameplay/application interfaces. Gameplay systems depend on narrow core interfaces. Core services must not depend on concrete gameplay scenes. Online and AI integrations are optional adapters at the boundary.

## Foundation services
- **EventBus:** typed, cross-system notifications only.
- **GameState:** coarse application phase and initialization state.
- **SceneRouter:** validates and centralizes scene changes.
- **ConfigService:** local user settings with defaults.
- **SaveService:** versioned local JSON save payload.

## Folder conventions
- game/scenes: Godot scenes.
- game/scripts/core: application-level services.
- game/scripts: gameplay and presentation scripts grouped by feature.
- game/resources: reusable resources and data definitions.
- game/assets: imported source assets grouped by type.
- native: optional C++ GDExtension source/build.
- backend: future backend services, separate from Godot runtime.
- tests: automated smoke and feature tests.
- docs: product, architecture, backlog, workflow, and quality documentation.

## Runtime principles
Keep boot deterministic and local. Validate external inputs and persisted data. Keep global state minimal. Do not block frame processing on disk, network, or AI requests. Profile before introducing native code or complex optimization.
