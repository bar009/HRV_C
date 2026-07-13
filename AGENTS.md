# AGENTS.md — HRV-C

## Mission

HRV-C is a local-first iOS + watchOS wellness product. It reads passively collected HRV data, learns a personal baseline, and helps shorten the time between a meaningful physiological change and conscious self-recognition.

The product supports the method "קוד התת-מודע" by creating a calm recognition point. It must never claim that HRV proves a feeling, diagnosis, trigger, subconscious pattern, anxiety state, or medical condition.

## Repository source of truth

Before changing behavior, read:

1. `README.md`
2. `docs/DECISIONS.md`
3. `docs/HRV_App_Spec.md`
4. `docs/HRV_Architecture_Deep_Dive.md`
5. `docs/SWIFT_PORTING_MAP.md`
6. `docs/PRODUCT_STATE_MODEL.md`
7. `docs/FIGMA_HANDOFF.md`

The Python implementation in `hrv_core/` and the tests in `tests/` are the executable numerical oracle for the future Swift port.

## Product state contract

User-visible presentation states:

- `setupRequired`
- `learning`
- `stable`
- `attention`
- `unavailable`

Internal detector states that must never be exposed directly:

- `Watching` — render as Stable while persistence is being verified.
- `Cooldown` — normally render as Stable while repeated alerts are suppressed.

Only a confirmed detector Alert may become the user-visible `attention` state.

## Canonical UX rules

- Describe data truth, not inferred emotion.
- Say “זוהה שינוי מתמשך” rather than “נכנסת ללופ”.
- An empty HealthKit read is not proof that permission was denied.
- Color never communicates state alone.
- One primary action per screen.
- Guided recognition must be optional, skippable, and calm.
- Preserve user agency: the app offers a check-in, not an interpretation.
- Local-first by default. Do not add a backend, cloud account, analytics SDK, or remote storage without explicit approval.
- Coherence / active measurement is outside v1.

## Engineering rules

- Do not change detection math, thresholds, persistence, cooldown, or artifact correction without tests and an explicit update to `docs/DECISIONS.md`.
- Keep `hrv_core/` standard-library-only unless a decision document explicitly changes that constraint.
- Run `pytest` after modifying Python code.
- Add or update tests for every behavior change.
- Keep commits small and explain product-impacting changes.
- Do not commit secrets, Health data, personal logs, generated user exports, or proprietary source PDFs.

## SwiftUI target

- iOS 17+
- watchOS 10+
- SwiftUI + Charts
- SwiftData
- HealthKit
- RTL-first Hebrew
- Dynamic Type through XXXL
- VoiceOver order: title → state → explanation → timestamp → action
- SF Pro on iPhone; SF Compact on Watch

If Xcode/macOS is unavailable, create documented scaffolds only and clearly mark them as uncompiled. Never claim device validation without a physical iPhone and Apple Watch.

## Figma source

File: `HRV-C — UX Wireframes v0.1`

- Main file: https://www.figma.com/design/hlCzE7OlX9yaZa7s5UJyhL
- Master plan: https://www.figma.com/design/hlCzE7OlX9yaZa7s5UJyhL?node-id=96-2
- State model: https://www.figma.com/design/hlCzE7OlX9yaZa7s5UJyhL?node-id=103-2
- Handoff: https://www.figma.com/design/hlCzE7OlX9yaZa7s5UJyhL?node-id=58-2

Treat Figma components and tokens as the visual source of truth. Treat the state contract and canonical copy in `docs/PRODUCT_STATE_MODEL.md` as the behavioral source of truth.

## Current work order

1. M1 — Product & State Model
2. M2 — Onboarding & Permissions
3. M3 — Post-Alert Guided Moment
4. M4 — Behaviour Support
5. M5 — History & Learning
6. M6 — Watch & Entry Points
7. M7 — Edge Cases & Accessibility
8. M8 — Prototype, QA & Handoff

Start with `tasks/M1_M3_IMPLEMENTATION.md`.
