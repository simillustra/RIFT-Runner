# RR-008 D4 — Data-Driven Enemy Archetype Policies

**Status:** Implementation submitted for Godot 4.4.1 CI validation.

EnemyArchetypeProfile is a Resource containing detection, attack, retention, movement, spacing and engagement-policy tuning. EnemyArchetypeController validates and applies the profile to EnemyAIController and EnemyChaseController. Shared state transitions and combat ownership remain unchanged.

Policies:
- PURSUER: close to preferred attack distance, then brake.
- SKIRMISHER: close to engagement distance, then strafe while maintaining pressure.
- RANGED: close to preferred range and hold position there; ranged attack execution remains a separate combat capability.

No archetype performs remote inference. The profiles are data-only and can be assigned by a later encounter spawner. Physical-device tuning and authored archetype assets remain acceptance evidence.

Acceptance evidence:
- Valid profile updates AI and chase parameters.
- Invalid range relationships are rejected.
- Skirmisher policy produces lateral movement inside its engagement band.
- Existing state machine and combat tests remain green.
