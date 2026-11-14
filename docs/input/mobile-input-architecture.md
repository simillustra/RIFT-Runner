# Mobile Input Architecture

**Status:** RR-006 D1-D7 deterministic implementation baseline. HUD and physical device acceptance remain open.

1. Device recognizers D2-D4 classify input and emit semantic commands.
2. MobileInputCommand carries action, phase, mode, vector, strength, ability ID, source ID and sequence.
3. MobileInputRouter D5/D7 validates, checks hero capability, arbitrates independent movement sources and buffers supported short-lived discrete actions.
4. MobileInputContextController D6 owns mode/context, recognizer lifecycle and local settings.
5. Movement, combat, game-state and interaction systems remain authoritative for effects.

## D7 deterministic rules
- Highest source priority wins movement; equal priority uses ascending source ID.
- Cancel/release promotes the next contribution.
- Buffer only supported discrete commands temporarily rejected as busy/unavailable; bounded capacity and deterministic TTL.
- Buffer flush order: descending priority, ascending source ID, insertion serial.
- Context disable, focus loss, source release and router teardown clear transient input.

D1 semantic contract; D2 joystick; D3 swipe/drag; D4 tap/press; D5 routing; D6 modes/settings; D7 arbitration/buffering/lifecycle; D8 integrated device acceptance.
