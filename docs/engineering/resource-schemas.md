# Resource Schemas
**CharacterStats:** max_health, movement_speed, attack_power, defense; validates numeric values.  
**AbilityDefinition:** stable ability_id, display_name, description, cooldown_seconds, duration_seconds, tags; metadata only in RR-002.  
**CharacterDefinition:** character_id, display_name, archetype, description, stats, abilities; validates nested resources and duplicate ability IDs.  
**CharacterRoster:** characters array; rejects null entries and duplicate character IDs; lookup by stable ID.

Schema changes require compatibility review. Version persisted formats and never repurpose stable IDs.
