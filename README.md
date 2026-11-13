# RIFT RUNNERS

Mobile-first third-person 3D action-survival runner built with Godot 4.x.

## Project status

RR-001 — Project Foundation is merged. RR-002 — Character Framework is in progress. Later gameplay tasks remain gated by their backlog acceptance criteria.

## Documentation

- [Product overview](docs/product/OVERVIEW.md)
- [Architecture](docs/architecture/ARCHITECTURE.md)
- [Character framework](docs/architecture/CHARACTER_FRAMEWORK.md)
- [Technical decisions](docs/architecture/DECISIONS.md)
- [Development workflow](docs/development/WORKFLOW.md)
- [Testing strategy](docs/quality/TESTING.md)
- [Backlog index](docs/backlog/README.md)

## Technology baseline

- Godot 4.4.1 and typed GDScript for game runtime
- C++ GDExtension only when profiling demonstrates a justified native-code need
- Python/FastAPI AI orchestration with provider adapters (OpenAI, Amazon Bedrock, and custom providers) as a separate service
- Nakama planned for future online services; offline single-player remains a first-class requirement

## Local development

1. Install Godot 4.4.1 stable.
2. Open `project.godot` in Godot.
3. Run the project (F6/F5) or execute the headless smoke test:

    godot --headless --path . --script res://tests/smoke_test.gd

The smoke test uses only Godot's built-in APIs and does not require an external test addon. See [AGENTS.md](AGENTS.md) for coding-agent rules.
