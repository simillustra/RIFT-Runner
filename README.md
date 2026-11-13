# RIFT RUNNERS

Mobile-first third-person 3D action-survival runner built with Godot 4.4.1.

## Project status
RR-001 is merged. RR-002 is merged via [PR #2](https://github.com/simillustra/RIFT-Runner/pull/2), with a CI validation follow-up required: the merged-head smoke test failed to resolve global script classes because the editor import/class scan was not run first. RR-003 remains blocked pending that fix.

## Documentation
The complete required documentation structure is indexed in [docs/README.md](docs/README.md).

Key entry points: [PRD](docs/product/PRD.md), [GDD](docs/product/GDD.md), [SRS](docs/product/SRS.md), [Architecture](docs/architecture/ARCHITECTURE.md), [Engineering standards](docs/engineering/coding-standards.md), [Character design](docs/gameplay/characters.md), [Test strategy](docs/qa/TEST-STRATEGY.md), [Backlog](docs/project-management/engineering-backlog.md).

## Technology
Godot 4.4.1 and typed GDScript. C++ GDExtension only with profiling evidence. Future AI orchestration is a separate Python/FastAPI service with OpenAI, Amazon Bedrock and custom provider adapters. Nakama is planned for future online services. Offline single-player remains first-class.

## Local development
Install Godot 4.4.1 stable, open project.godot, then run:

    godot --headless --editor --path . --quit
    godot --headless --path . --script res://tests/smoke_test.gd

See [AGENTS.md](AGENTS.md) for coding-agent rules.
