# CI/CD
Current GitHub Actions workflow uses a Godot 4.4.1 container to run headless smoke tests on pushes and pull requests.

Required gates: verify engine version, run editor import/class scan, run smoke/feature tests, fail on parser/resource errors, retain useful logs. Add Android export after SDK/templates are provisioned; iOS export needs a macOS runner. Signing secrets belong in CI secrets or a secret manager, never Git.
