# Multiplayer Architecture
**Status:** Future P1 capability (RR-012 Nakama, RR-013 co-op). Live multiplayer is not required for the vertical slice.

Offline single-player remains independent. Future online systems must define server authority, stable-ID replication, prediction/reconciliation, reconnect and session ownership. Replicate DTOs/state, not Godot Resource instances. Two- and four-player co-op are targets; mode/authority details remain TBD. No networking is implemented in RR-002.
