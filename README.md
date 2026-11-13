# RIFT RUNNERS

Mobile-first third-person 3D action-survival runner built with Godot 4.x.

## Project status

The repository foundation is being established under **RR-001 — Project Foundation**. Gameplay feature work is intentionally blocked until the foundation acceptance checks pass.

## Documentation

- [Product overview](docs/product/OVERVIEW.md)
- [Architecture](docs/architecture/ARCHITECTURE.md)
- [Technical decisions](docs/architecture/DECISIONS.md)
- [Development workflow](docs/development/WORKFLOW.md)
- [Testing strategy](docs/quality/TESTING.md)
- [RR-001 implementation plan](docs/backlog/RR-001-project-foundation.md)
- [Backlog index](docs/backlog/README.md)

## Technology baseline

- Godot 4.x and typed GDScript for game runtime
- C++ GDExtension only when profiling demonstrates a justified native-code need
- Python/FastAPI AI orchestration with provider adapters (OpenAI, Amazon Bedrock, and custom providers) as a separate service
- Nakama planned for future online services; offline single-player remains a first-class requirement

Exact engine patch versions, export templates, SDK versions, and CI image tags must be pinned by the implementation environment and recorded in the build report.

## Local development

1. Install a supported Godot 4.x stable release.
2. Open `project.godot` in Godot.
3. Run the project (F6/F5) or execute the headless smoke test:

```sh
godot --headless --path . --script res://tests/smoke_test.gd
```

The smoke test uses only Godot's built-in APIs and does not require an external test addon.

## Repository conventions

All work must reference a backlog item (RR-###), include acceptance criteria, tests where applicable, and documentation updates. See [AGENTS.md](AGENTS.md) for coding-agent rules.
