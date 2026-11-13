# Coding Agent Instructions

## Mission
RIFT RUNNERS is a mobile-first third-person 3D action-survival runner. Read [the documentation index](docs/README.md), product/architecture docs, test strategy and the relevant backlog item before changing code.

## Mandatory rules
1. Every task references RR-### and satisfies its acceptance criteria.
2. RR-001 is accepted/merged. RR-002 has merged, but its CI validation follow-up is open because the merged-head smoke test could not resolve global script class names. Do not begin RR-003 until the fix is verified and accepted.
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
Inspect repository state, work on a task branch, implement the smallest coherent increment, add tests/docs, run editor import/class scan then headless smoke tests, and report exact commands/results/risks. See docs/engineering/coding-agent-rules.md.
