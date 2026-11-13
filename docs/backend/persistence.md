# Persistence
## Local
ConfigService stores settings; SaveService stores versioned JSON under user://. Save schema changes require explicit version increments and migration/compatibility tests.

## Future online
Nakama/server persistence may own synchronized profiles, co-op and competitive state. Define conflict resolution and authority before sync. Never trust client data for purchases, rankings or competitive outcomes.
