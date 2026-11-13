# RR-001 — Project Foundation

**Priority:** P0  
**Status:** Accepted and merged  
**Merged PR:** [#1](https://github.com/simillustra/RIFT-Runner/pull/1)  
**Goal:** Establish a reproducible, documented, testable Godot project foundation before gameplay agents begin feature work.

## Delivered
- Godot project configuration and bootstrap scene.
- Application-level EventBus, GameState, SceneRouter, ConfigService, and SaveService autoloads.
- Local settings persistence and versioned save/load foundation.
- Headless smoke test and GitHub Actions workflow.
- Git conventions, coding-agent instructions, product, architecture, workflow, testing, and backlog documentation.

## Validation evidence
- GitHub Actions final-head runs #4 and #5 passed, including engine-version verification and the headless smoke-test step.
- Android/iOS exports were not performed; platform SDKs, export templates, signing credentials, and devices remain environment prerequisites.

## Follow-up
Platform export validation remains a release-readiness task and must be completed when the mobile build environment is provisioned.
