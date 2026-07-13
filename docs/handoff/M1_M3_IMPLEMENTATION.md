# M1–M3 Implementation Task

## Goal

Bring repository behavior, documentation and future SwiftUI implementation into alignment with the Figma master plan and the method-based product purpose.

## M1 — Product & State Model

### Required

- Add the presentation state contract from `docs/PRODUCT_STATE_MODEL.md`.
- Keep detector states and presentation states separate.
- Decide where the pure mapping will live in the future Swift architecture.
- Add tests for any pure mapping logic created in Python or Swift.
- Update `docs/DECISIONS.md` with the canonical state mapping.

### Do not

- Change detector thresholds or state-machine behavior.
- Expose Watching or Cooldown in user-facing copy.
- Claim that HRV identifies emotion or a subconscious pattern.

### Exit criteria

- One canonical state table exists.
- Every detector state has a defined presentation outcome.
- Canonical Hebrew copy is documented.
- Existing Python tests pass.

## M2 — Onboarding & Permissions

### Design scope

- Welcome / value
- Method explanation
- HealthKit rationale and access
- Notification permission rationale
- Privacy and local-only explanation

### UX rules

- Ask permissions only after explaining value.
- Separate Health and notification requests.
- Avoid medical claims.
- Show a clear path when permission is skipped.

### Exit criteria

- All first-run screens exist in Light and Dark.
- Permission-denied, skipped and no-data states are documented.
- Copy is localized and accessible.

## M3 — Post-Alert Guided Moment

### Screen order

1. Alert Detail / entry
2. Guided Moment intro
3. Body
4. Mind
5. Context
6. Support choice
7. Completion / If–Then plan
8. Follow-up relevance feedback

### UX rules

- One question per screen.
- 20–60 seconds total.
- Skip and Not Now are always available.
- The app never supplies the user's interpretation.
- Persist user-provided context separately from detector truth.

### Exit criteria

- Core prototype: Alert → Body → Mind → Context → Support → Completion.
- False-positive and Not Now paths exist.
- VoiceOver and Dynamic Type are validated.
