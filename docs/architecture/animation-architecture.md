# Animation Architecture
Animation presents locomotion, combat, reactions, traversal transitions and abilities. It consumes actor state; it does not own authoritative movement or damage.

Planned options include AnimationTree/AnimationPlayer, shared state parameters and hero-specific overrides. Animation events may drive presentation timing, but hit validation remains in combat logic. Rig/retargeting strategy must be decided before production assets. No animation graph/assets are part of RR-002.
