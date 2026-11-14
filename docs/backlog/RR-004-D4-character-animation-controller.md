# RR-004 D4 — CharacterAnimationController

**Status:** Implemented on D4 branch; Godot CI validation pending.

## Responsibilities

CharacterAnimationController is a presentation-only consumer of CharacterMovementController.get_animation_state(). It owns no movement, collision, damage, ability, or physics behavior.

It receives typed references to the movement controller, AnimationTree, AnimationPlayer, and AnimationProfile. On initialization it validates the profile against the AnimationPlayer library, builds the shared D3 graph, activates the tree, and resolves the centralized state-machine playback parameter.

## Runtime state selection

- Grounded and below the profile idle threshold: Idle.
- Grounded and above the profile movement threshold: Move, with hysteresis to prevent state flicker.
- Grounded-to-airborne edge: JumpStart for a configurable short hold.
- Airborne after jump-start: Rising when vertical velocity is positive; Falling otherwise.
- Airborne-to-grounded edge: Landing for a configurable short hold.
- External play_hit_react() request: HitReact for a bounded duration, then resume locomotion selection.

All state changes use AnimationNodeStateMachinePlayback.travel(). Directional blend input is transformed from world planar velocity into actor-local coordinates and written only through CharacterAnimationGraph's centralized parameter helper.

## Playback rate

Moving playback uses AnimationProfile.get_playback_rate(planar_speed), which clamps the speed ratio to profile min/max. Idle playback resets AnimationPlayer.speed_scale to 1.0. This affects animation playback only.

## Integration boundary

D4 does not attach itself to CharacterActor automatically and does not alter the existing character scene. A scene owner must assign the four typed dependencies. Real rig/clip visual validation remains pending production animation assets.

## Validation

The D4 headless test constructs a CharacterBody3D + movement controller + AnimationPlayer + AnimationTree fixture and checks initialization, idle/move hysteresis path, jump/rise/fall/landing, hit-react override, and playback-rate mapping.

Run after editor import/global class registration:

```sh
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/character_animation_controller_test.gd
```
