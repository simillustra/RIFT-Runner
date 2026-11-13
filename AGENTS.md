# Coding Agent Instructions

## Mission
RIFT RUNNERS is a mobile-first third-person 3D action-survival runner. Read [the documentation index](docs/README.md), product and architecture documentation, testing strategy, and the relevant backlog item before changing code.

## Mandatory rules
1. Every task references a backlog ID (RR-###) and satisfies its acceptance criteria.
2. RR-001 Project Foundation is accepted and merged. RR-002 is the current character-framework task; do not begin RR-003 or later gameplay tasks until RR-002 is accepted and merged.
3. Preserve offline single-player; network services must never be required to boot or play offline.
4. Use Godot 4.4.1 and typed GDScript. Add C++ GDExtension only with profiling evidence and an ADR.
5. Keep AI orchestration in a separate Python/FastAPI service with OpenAI, Bedrock and custom provider adapters. Never call remote AI from frame, input, movement, combat or enemy decision loops.
6. Use deterministic in-engine FSM/behavior logic for real-time enemy behavior.
7. Keep Nakama/co-op behind future interfaces; neither is a vertical-slice bootstrap dependency.
8. Never commit secrets, signing keys, generated exports, imported assets or machine-specific editor state.
9. Add/update tests for behavior changes. Never claim a test/export/device build passed unless actually run.
10. Update docs and record limitations whenever architecture, setup or acceptance behavior changes.

## GDScript conventions
Use explicit types for public APIs; snake_case for files/methods/variables/signals; PascalCase for classes. Keep Resources data-focused and Nodes behavior-focused. Validate external data, handle errors explicitly, and keep scenes focused.

## Workflow
Inspect repository state, work on a task branch, implement the smallest coherent increment, add tests/docs, run the headless smoke test and report exact commands/results/risks. The detailed rules are in [engineering/coding-agent-rules.md](docs/engineering/coding-agent-rules.md).
