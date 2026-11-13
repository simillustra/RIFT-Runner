# Repository Structure
- game/scenes: Godot scenes.
- game/scripts/core: application services.
- game/scripts/characters: character domain/runtime scripts.
- game/resources: reusable Resources and content data.
- game/assets: licensed source assets.
- native: optional C++ GDExtension.
- backend: future services.
- tests: headless smoke and feature tests.
- docs: product, architecture, engineering, delivery and project docs.
- .github/workflows: CI.
Keep generated .godot/import/export output, build products, secrets and signing files out of Git. Add folders when real code requires them.
