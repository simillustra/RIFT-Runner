# RR-004 D7 — Production Rig Validation Pipeline

## First implementation slice

No production hero models, Skeleton3D rigs or licensed animation clips are currently present in the repository. The existing D7 empty-clip fixture validates graph wiring only. Do not fabricate assets or mark heroes visually validated.

This slice adds a reusable validator for imported hero scenes. It verifies rig hierarchy, AnimationPlayer root resolution, profile/rig ID compatibility, mapped and fallback clip availability/duration, track target-node resolution, and Skeleton3D bone references for 3D position/rotation/scale tracks.

## Calling the validator

```gdscript
var errors := AnimationRigValidator.validate_rig(
    $HeroVisual,
    $HeroVisual/AnimationPlayer,
    $HeroVisual/Armature/Skeleton3D,
    load("res://game/resources/animation_profiles/vanguard_profile.tres"),
    &"humanoid_vanguard"
)
if errors.is_empty():
    print("Hero rig asset contract passed.")
else:
    for error_text: String in errors:
        push_error(error_text)
```

The node paths are illustrative and must be adapted to the imported rig scene. A matching rig ID is a project compatibility contract, not automatic retargeting.

## Hero asset onboarding checklist

For Vanguard, Phantom and Cipher, provide an approved source model, license/provenance, Godot-imported scene, named Skeleton3D and documented bone hierarchy/scale/forward axis, AnimationPlayer with exact semantic clip names, retargeting settings, and idle/forward/backward/strafe/jump/landing/hit-reaction clips.

## Automated validation

`tests/animation_production_rig_validator_d7_test.gd` uses a deterministic synthetic Skeleton3D fixture to test valid bone tracks, mismatched rig IDs, missing bones, missing track nodes and invalid AnimationPlayer root paths. This tests the validator, not the production hero assets or rendered visual quality.

## Remaining D7 gates

- [ ] Approved production rigs and licenses supplied for all launch heroes.
- [ ] Actual imported hero scenes pass AnimationRigValidator.
- [ ] Retargeted clips inspected for bone orientation, root/pelvis motion and scale.
- [ ] Idle/locomotion/jump/landing/hit-react transitions visually reviewed.
- [ ] Directional clips replace repeated placeholder Move BlendSpace points.
- [ ] Android low/mid-tier and high-tier captures recorded.
- [ ] iOS validation completed or explicitly marked not tested with reason.
