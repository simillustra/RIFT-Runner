# Build Instructions
1. Install Godot 4.4.1 stable and matching export templates.
2. Clone repository and open project.godot.
3. Run interactively in editor.
4. Run editor import/class scan: godot --headless --editor --path . --quit
5. Run smoke: godot --headless --path . --script res://tests/smoke_test.gd
6. Configure platform SDKs/export presets only in a secure build environment.

Android requires compatible Android SDK/JDK and Godot export templates. iOS requires macOS/Xcode and signing. Pin exact SDK versions when release automation is provisioned.
