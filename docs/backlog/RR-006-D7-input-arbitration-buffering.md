# RR-006 D7 — Deterministic Arbitration, Buffering and Lifecycle

- Independent MOVE contribution per source; highest configured priority wins. Priority range -1000..1000; default 0.
- Equal priority uses ascending source ID, not event arrival order. Winner cancel/release promotes the next source immediately.
- Only the winning contribution is sent to CharacterMovementController.
- Supported discrete actions (jump, lane changes, basic attack, assigned abilities) buffer only on temporary ERR_BUSY/ERR_UNAVAILABLE. MOVE, CANCEL, PAUSE, INTERACT and unsupported actions never buffer.
- Default TTL 180ms and capacity 8. New same-source/action command replaces prior pending intent; oldest is evicted at capacity.
- Flush order: descending source priority, ascending source ID, insertion serial. Expiry uses deterministic accumulated input time.
- Source release clears its movement, queued actions and sequence watermark. Context disable, focus loss and teardown clear all transient state.
- CI tests concurrent sources, priority/tie-break, fallback, buffering, expiry, context cleanup and source reuse.
- Android/iOS simultaneous-touch and interruption/resume validation remains outstanding.
