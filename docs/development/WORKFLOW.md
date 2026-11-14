# Development Workflow

## Branching and commits
Create a task branch from the integration branch (for example, rr-003/movement-controller). Use focused commits with the backlog ID in the subject. Never force-push shared branches or commit generated/imported build output.

## Task lifecycle
1. Read AGENTS.md and the relevant product, architecture, and backlog documentation.
2. Confirm scope and acceptance criteria before coding.
3. Inspect existing code and identify dependencies.
4. Implement the smallest coherent increment.
5. Add/update automated tests and documentation.
6. Run the headless smoke test and relevant feature checks.
7. Report exact commands, outcomes, limitations, and changed files.

## Definition of Done
Acceptance criteria are met and demonstrable. Automated tests exist and pass, or an explicit blocker is recorded. Startup behavior is verified. Documentation reflects shipped behavior. No unrelated regressions or unreviewed scope expansion. Build/export claims are supported by tool output.

## Asset and platform policy
Use legally cleared assets and record source/license metadata. Keep Android signing material, Apple certificates/profiles, API keys, and service credentials outside Git. Device export validation requires SDKs, export templates, signing setup, and target devices.
