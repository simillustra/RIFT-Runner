# Coding Agent Instructions

## Mission
RIFT RUNNERS is a mobile-first third-person 3D action-survival runner. Read the product overview, architecture, workflow, testing strategy, and relevant backlog item before changing code.

## Mandatory rules
1. Every task references a backlog ID (RR-###) and satisfies its acceptance criteria.
2. Do not implement gameplay features until RR-001 is accepted.
3. Preserve offline single-player operation; network services must never be required to boot or play offline.
4. Use Godot 4.x stable and typed GDScript. Add C++ GDExtension only with profiling evidence and an ADR.
5. Keep AI orchestration in a separate Python/FastAPI service with OpenAI, Bedrock, and custom provider adapters. Never call remote AI from frame, input, movement, combat, or enemy decision loops.
6. Use deterministic in-engine FSM/behavior logic for real-time enemy behavior.
7. Keep Nakama and co-op behind future interfaces; neither is a dependency of the vertical-slice bootstrap.
8. Never commit secrets, signing keys, generated exports, imported assets, or machine-specific editor state.
9. Add/update tests for behavior changes. Never claim a test, export, or device build passed unless it was actually run.
10. Update docs and record limitations whenever architecture, setup, or acceptance behavior changes.

## GDScript conventions
- Prefer class_name only for stable reusable public types.
- Add explicit types to members, parameters, and return values.
- Use snake_case for files, variables, functions, and signals; PascalCase for classes.
- Use signals/event bus for decoupled notifications; avoid global mutable state where local ownership is clearer.
- Validate external data and persisted files. Handle errors explicitly.
- Keep scene scripts focused; move reusable logic into core services.

## Change workflow
Inspect history and files first. Work on a task branch. Implement the smallest complete increment. Run the headless smoke test and relevant checks. Report changed files, commands, exact outcomes, and remaining risks.
