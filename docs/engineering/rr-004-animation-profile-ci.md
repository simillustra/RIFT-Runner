# RR-004 D2 — CI Gate

The Godot CI workflow now runs `tests/animation_profile_test.gd` after editor import/global-class registration and after the existing smoke/movement suites.

The D2 pull request is not accepted until the Godot 4.4.1 workflow completes successfully. The test validates structural profile rules and optional animation-library clip-name validation. It does not validate visual playback or production rig compatibility.
