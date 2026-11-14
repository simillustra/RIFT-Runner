# RR-004 D7 — Visual and Device Validation

**Status:** Validation baseline implemented; production visual/device evidence outstanding  
**Branch:** `feat/rr-004-d7-validation-baseline`  
**Dependencies:** D1-D6 merged; production hero rigs and animation assets required for final sign-off

## Objective

Validate the shared animation framework against real hero rigs, imported animation clips and target mobile devices. D7 is the final RR-004 acceptance gate; resource loading and headless tests alone are not visual acceptance.

## Implemented in this baseline

- Automated asset-contract test creates a deterministic AnimationPlayer fixture with the canonical semantic clips.
- Loads Vanguard, Phantom and Cipher profiles and validates each against the fixture's actual animation-library names.
- Builds the shared AnimationTree graph for each profile and verifies graph structure and every referenced AnimationNodeAnimation clip.
- Runs the contract test in Godot 4.4.1 CI.
- Adds a manual visual/device evidence matrix and explicit sign-off gates.

The fixture clips are empty test animations. They prove resource and graph wiring only. They do not prove skeleton compatibility, retargeting quality, foot contact, root motion, animation blending quality, frame pacing or device performance.

## Required production validation

1. Import one approved production rig for each hero, with documented skeleton/bone hierarchy and scale.
2. Import licensed animation clips and verify exact clip names against each hero profile.
3. Verify retargeting and animation track paths resolve to the intended skeleton.
4. Run the visual test scene through Idle → Move, Move → Idle, JumpStart → Rising → Falling → Landing, and HitReact recovery.
5. Inspect directional locomotion from forward, backward and lateral movement; replace the current repeated placeholder clip points with suitable directional clips where available.
6. Confirm animation does not visibly slide, pop, twist, detach from the floor or deform incorrectly.
7. Capture representative low/mid-tier and high-tier Android device runs; record device model, OS, build commit, renderer, FPS/frame-time observations, memory observations and defects.
8. Repeat on iOS when an iOS device/export environment is available; otherwise record as not tested, not passed.

## Acceptance checklist

- [ ] Vanguard production rig imported and profile compatibility verified.
- [ ] Phantom production rig imported and profile compatibility verified.
- [ ] Cipher production rig imported and profile compatibility verified.
- [ ] Required clips exist in each production AnimationPlayer library.
- [ ] Animation track paths resolve to the intended Skeleton3D.
- [ ] No severe foot sliding, pose snapping, broken retargeting or transition pops.
- [ ] All required locomotion and airborne transitions visually reviewed.
- [ ] Android low/mid-tier device evidence recorded.
- [ ] Android high-tier device evidence recorded.
- [ ] iOS validation completed or explicitly marked not tested with reason.
- [ ] CI asset-contract test passes on Godot 4.4.1.
- [ ] Known limitations and asset licensing/import settings documented.

## Evidence record

Use `docs/qa/RR-004-D7-VALIDATION-MATRIX.md`. Attach screenshots or short recordings to the PR/release evidence; do not mark a device or hero as validated without an actual run.

## Exit rule

D7 remains open until all available production heroes and required target devices have evidence. If production assets or devices are unavailable, merge only the validation infrastructure as a partial milestone and retain RR-004 as not accepted.
