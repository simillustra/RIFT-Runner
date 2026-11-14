# Gameplay Architecture
Layers: domain data (characters/items/abilities), simulation (movement/combat/health/enemies/run rules), presentation (camera/animation/VFX/audio/HUD), application (scene flow/save/settings).

Keep rules deterministic and testable. Separate input intent from movement/combat execution. Resources describe content; runtime Nodes execute behavior. RR-002 defines character metadata and actor ownership only; movement, animation, combat, input and ability execution are separate tasks.
