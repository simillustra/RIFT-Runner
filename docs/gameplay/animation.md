# RR-004 Animation Design

**Status:** Technical design baseline; implementation not yet complete  
**Engine:** Godot 4.4.1  
**Primary reference:** [RR-004 Technical Design](../architecture/RR-004-TECHNICAL-DESIGN.md)

## Principles

- Animation is presentation, never gameplay authority.
- CharacterMovementController owns physical movement and exposes read-only state.
- CharacterAnimationController consumes that state and drives AnimationTree.
- AnimationProfile Resources map semantic states to hero-specific clips and tuning.
- Missing optional rig assets must not block offline gameplay.
- Animation markers may notify audio/VFX but cannot cause damage, jump success, landing or ability execution.

## Semantic states

Idle, Start, Move, Stop, JumpStart, Rising, Falling, Landing and HitReact are the initial states. Sprint is an extension point only; RR-003 does not currently expose authoritative sprint state.

## Blend convention

The locomotion BlendSpace2D uses actor-local planar velocity. X negative/positive means left/right; Y positive/negative means forward/backward. Actual velocity, not raw input intent, drives blending so collisions and braking are represented.

## Hero profiles

Vanguard, Phantom and Cipher use the shared controller and separate AnimationProfile resources. Final rig/retargeting decisions are deferred until production animation assets are selected and usage rights confirmed.

## Validation

See the technical design for movement contract, state graph, fallback rules, test matrix and milestones. No production animation clips are claimed to exist until committed and verified.
