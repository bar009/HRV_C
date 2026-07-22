# Go-Live — final decisions & steps to public App Store

Tracks the last mile from "on TestFlight" to "public on the App Store".
Companion to [`../LAUNCH_CHECKLIST.md`](../LAUNCH_CHECKLIST.md) (the 16 items) and
[`README.md`](README.md) (the content pack).

## Final decisions (locked)

| Decision | Value |
|---|---|
| Legal / developer name (privacy policy, medical statement) | **Trigger Bitter** *(verify spelling/entity before publishing)* |
| Public contact email | **bar16072000@gmail.com** |
| Jurisdiction (privacy policy governing law) | **Israel** |
| Privacy-policy effective date | **23 July 2026** |
| Coherence (Track J) in **public v1** | **OFF** — v1 is the passive app (3 tabs). Coherence ships in **v1.1** after real-watch validation. It's behind `FeatureFlags.coherenceEnabled` (false in Release). |
| Beat-series metrics (RMSSD/pNN50/SDSD) in **public v1** | **OFF** — behind `FeatureFlags.advancedMetricsEnabled`. Ships with the v1.1 batch after a real-device field test confirms passive `HKHeartbeatSeriesSample` availability (Q-A). When enabled: add `heartbeat` to the Info.plist HealthKit usage string + the appstore read-set line. |
| First ship target | **HRV-Phone** (iPhone-only). Watch app follows in a later build. |
| Export compliance | Exempt — no custom crypto (`ITSAppUsesNonExemptEncryption=false`). |

## Why your phone shows 3 tabs (not 4)

That is **correct and current**. The coherence "תרגול" tab is behind
`FeatureFlags.coherenceEnabled`, which is only enabled via a DEBUG launch
argument — compiled **out** of Release/TestFlight builds. So every real build
(App Store or TestFlight) shows 3 tabs by design. The 4-tab version only appears
in DEBUG simulator runs used for development. There is no newer app code than
TestFlight build 1; enabling the 4th tab requires a deliberate flag change.

## Remaining steps to public

| # | Step | Owner | Status |
|---|------|-------|--------|
| 1 | Confirm "Trigger Bitter" is the correct legal entity name | user | ⬜ |
| 2 | Host the Privacy Policy at a public URL → fill `{{PRIVACY_URL}}` (also `{{SUPPORT_URL}}`, `{{MARKETING_URL}}`) | user + me (I can prep HTML) | ⬜ |
| 3 | Find the App record's public **Name** in App Store Connect (App Information → Name) | user | ⬜ |
| 4 | Disable **Clinical Health Records** on the App ID (enabled but unused — clean before review) | user (developer.apple.com) | ⬜ |
| 5 | **Device validation pass** on iPhone + Apple Watch (the gate — thresholds untuned, never run on real HRV). Tune `k`/persistence/cooldown (Q-B); verify File Protection (#6), real notification tap, all screens. Via TestFlight build 1. | user + me | ⬜ |
| 6 | App Store Connect data entry: listing text, screenshots (`screenshots/`), privacy questionnaire (Data Not Collected), age rating (4+), trader/DSA status — all from the content pack | user | ⬜ |
| 7 | **Submit for Review** | user | ⬜ |

**Order matters:** step 5 (device validation) must pass before step 7 (submit).
