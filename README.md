# RIFT RUNNERS

Mobile-first third-person 3D action-survival runner built with Godot 4.4.1.

## Project status
RR-001 — Project Foundation is merged. RR-002 — Character Framework is in progress in [PR #2](https://github.com/simillustra/RIFT-Runner/pull/2). Later gameplay tasks remain gated by their backlog acceptance criteria.

## Documentation
The complete required documentation structure is indexed in [docs/README.md](docs/README.md).

Key entry points:
- [Product Requirements (PRD)](docs/product/PRD.md)
- [Game Design (GDD)](docs/product/GDD.md)
- [System Requirements (SRS)](docs/product/SRS.md)
- [System Architecture](docs/architecture/ARCHITECTURE.md)
- [Engineering standards](docs/engineering/coding-standards.md)
- [Character design](docs/gameplay/characters.md)
- [Test strategy](docs/qa/TEST-STRATEGY.md)
- [Engineering backlog](docs/project-management/engineering-backlog.md)

## Technology baseline
Godot 4.4.1 and typed GDScript for the client. C++ GDExtension only with profiling evidence. Future AI orchestration is a separate Python/FastAPI service with OpenAI, Amazon Bedrock and custom provider adapters. Nakama is planned for future online services. Offline single-player remains first-class.

## Local development
1. Install Godot 4.4.1 stable.
2. Open `project.godot`.
3. Run the project in the editor or execute:

    godot --headless --path . --script res://tests/smoke_test.gd

See [AGENTS.md](AGENTS.md) for coding-agent rules.
