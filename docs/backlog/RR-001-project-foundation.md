# RR-001 — Project Foundation

**Priority:** P0  
**Status:** Implementation in progress  
**Goal:** Establish a reproducible, documented, testable Godot project foundation before gameplay agents begin feature work.

## Scope
- Godot project configuration and core folder conventions.
- Bootstrap scene and application-level autoload services.
- Centralized scene routing and typed event notifications.
- Configuration defaults and local settings persistence.
- Versioned local save/load foundation.
- Headless automated smoke test.
- Git conventions, coding-agent rules, CI workflow, and repository documentation.
- Record mobile export prerequisites and platform validation limitations.

## Acceptance criteria
- [ ] Project opens with pinned Godot 4.x baseline and valid bootstrap scene.
- [ ] All declared autoloads initialize without runtime errors.
- [ ] Application boot can transition from BOOT to MENU.
- [ ] SceneRouter rejects missing scene paths and centralizes valid transitions.
- [ ] ConfigService exposes defaults and persists supported settings.
- [ ] SaveService performs a versioned local save/load round trip and rejects unsupported data.
- [ ] Headless smoke test passes on the pinned engine version.
- [ ] CI runs the smoke test on pushes and pull requests.
- [ ] README, AGENTS, architecture, workflow, testing, and backlog docs are present and consistent.
- [ ] Android/iOS export prerequisites and unverified platform limitations are documented.
- [ ] No gameplay, online, monetization, or AI runtime feature is included.

## Implementation notes
- Engine baseline selected: Godot 4.4.1 stable, Compatibility renderer for broad mobile support.
- CI is configured to run the smoke test; a workflow file is not evidence that CI has passed.
- Mobile export templates, Android SDK/JDK, Apple toolchain, signing credentials, and physical devices are environment prerequisites and are not committed.
- This is a foundation scaffold, not a complete production release pipeline.

## Evidence required to close
Record engine version, smoke-test command/output/exit code, CI run URL/status, and platform export validation performed. Keep the item open until evidence is available.
