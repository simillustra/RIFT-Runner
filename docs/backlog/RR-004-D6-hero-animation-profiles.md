# RR-004 D6 — Hero-Specific Animation Profiles

**Status:** Implementation in review  
**Branch:** `feat/rr-004-d6-hero-animation-profiles`  
**Dependency:** D2 AnimationProfile resource; D3 shared graph; D4 runtime controller; D5 optional actor integration

## Objective

Provide independently configurable animation-profile resources for Vanguard, Phantom and Cipher without forking the shared AnimationTree graph or runtime controller.

## Deliverables

- `vanguard_profile.tres`
- `phantom_profile.tres`
- `cipher_profile.tres`
- Automated resource validation test suite
- CI execution of the D6 test suite
- Architecture/backlog status updates

## Profile contract

Each resource:
- Uses the shared semantic state names and required-state contract.
- Has a stable unique `profile_id`.
- Declares a distinct `rig_profile_id` for future rig/retargeting compatibility checks.
- Owns its own locomotion thresholds, reference speed and playback-rate bounds.
- Uses the current canonical clip identifiers (`idle`, `move`, `rising`, `falling`, `landing`) as a temporary shared clip contract.

The initial numeric tuning values are balancing starting points only. They are not claims about final hero movement speeds, animation timing or visual identity. They must be reviewed during D7 with actual animation clips and device capture.

## Explicit scope boundary

D6 creates and validates profile assets; it does not add a hero-selection system, alter CharacterActor's default base profile, create production skeletons, import third-party animation packs or claim that the referenced clips exist in a production rig. The D5 no-rig fallback remains unchanged. D7 owns visual/retargeting validation.

## Acceptance criteria

- [ ] All three resources load as typed AnimationProfile resources.
- [ ] Each profile passes AnimationProfile.validate().
- [ ] Profile IDs are unique and stable.
- [ ] Rig profile IDs are distinct and non-empty.
- [ ] Required semantic state mappings are present.
- [ ] Locomotion tuning is independently configurable per hero.
- [ ] CI executes the D6 test suite successfully.
- [ ] D7 visual validation remains explicitly outstanding.
