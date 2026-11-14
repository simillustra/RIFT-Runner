# Product Roadmap

| Phase | Scope | Exit gate |
|---|---|---|
| Foundation | RR-001 | Merged; CI smoke passed |
| Character foundation | RR-002 | Accepted and merged |
| Core feel | RR-003 movement, RR-004 animation, RR-006 input | Movement formally accepted; animation transitions tested; traversal validated on target devices |
| Combat | RR-005 | Playable combat loop with gameplay-owned hit/damage outcomes |
| World | RR-007, RR-008, RR-016 | Two environments, enemy roster and boss encounter |
| Slice completion | RR-009–011, RR-019 | Vertical-slice acceptance and performance gates |
| Online | RR-012 Nakama, RR-013 co-op | Online feature gates |
| AI | RR-014 service, RR-015 content tools | Secure optional integration; no remote AI in real-time movement/combat loops |
| Release | RR-017, RR-018, RR-020 | Release checklist signed off |

RR-003 implementation merged in PR #4. Its formal acceptance checklist remains open for deterministic physics coverage and recorded device validation. RR-004 is specified in `docs/backlog/RR-004-animation-framework.md` and depends on RR-003 formal acceptance.
