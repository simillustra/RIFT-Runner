# RR-004 D3 — AnimationTree State Machine

**Status:** Implemented on D3 branch; Godot CI validation pending.

## Graph factory

CharacterAnimationGraph creates a Godot AnimationNodeStateMachine using semantic clip identifiers from AnimationProfile. It configures presentation resources only and does not access or mutate CharacterBody3D or CharacterMovementController.

States: Idle; Move (AnimationNodeBlendSpace2D); JumpStart; Rising; Falling; Landing; HitReact.

The Move BlendSpace2D uses actor-local coordinates: X is left/right and Y is forward/back. It contains an idle center and four directional points. Until directional clip variants are added to AnimationProfile, all four directional points intentionally reuse the profile move clip. This is a placeholder mapping, not a claim that directional motion clips exist.

## Centralized parameter paths

- PLAYBACK_PARAMETER_PATH: parameters/playback
- MOVE_BLEND_PARAMETER_PATH: parameters/Move/blend_position

Consumers should use get_playback() and set_move_blend_position() rather than hard-coding AnimationTree parameter paths.

## Transitions

The graph includes grounded locomotion transitions, jump start → rising → falling → landing, and hit-react entry/return transitions. Cross-fade defaults to 0.12 seconds. D4 will own state selection and update timing; D3 does not drive gameplay or movement.

## Validation

The graph validator checks required states, Move BlendSpace2D point count and Idle initial state. The D3 headless test builds an AnimationPlayer/AnimationLibrary/AnimationTree fixture, verifies graph structure, playback parameter resolution and blend parameter updates.

Run after editor import/global-class registration:

```sh
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/animation_tree_graph_test.gd
```

Visual playback and real rig compatibility remain unvalidated until production animation assets are selected and integrated.