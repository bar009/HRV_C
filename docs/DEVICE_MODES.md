# Sensor modes — what each one measures, and what it makes possible

HRV-C runs in one of two **explicitly chosen** modes. The app never switches on
its own, so the user always knows which indicators to expect.

The rule that governs everything below: **devices do not all produce the same
indicators.** Rather than hardcoding assumptions per screen, every feature
resolves through `IndicatorResolver.availability(of:given:)`
(`Sources/HRVCore/Sensing/`). Adding a new device means declaring its
`SensorCapabilities` — nothing else.

---

## Mode 1 — Apple Watch (passive)

**Transport:** HealthKit (`HKObserverQuery` + background delivery).

**Raw input**
- Apple's own computed **SDNN** — the primary detection signal
- Resting heart rate, workouts, sleep — context, for stratification and for the
  facts shown alongside an event
- Occasionally `HKHeartbeatSeriesSample` (ECG / some workouts) → RMSSD & friends

**Coverage:** roughly **5–12 readings per day**, and only at rest — SDNN is
written mainly by Mindfulness/Breathe sessions and sleep. That is ~1–2 % of the
waking day.

**Enables:** sustained ("silent") change detection over hours–days, the personal
baseline, trends, event context, calm-pole mapping, time-to-awareness, and the
breathing pacer.

**Cannot do:** live trigger detection. There simply isn't continuous data. The
watch's workout session can stream heart rate, but inter-beat timing derived
from it is *reconstructed*, not measured — hence `RRFidelity.derivedFromHR`,
and any HRV computed from it is labelled **approximate** in the UI.

---

## Mode 2 — BLE heart-rate strap (generic)

**Transport:** CoreBluetooth, the Bluetooth SIG standard
**Heart Rate Service `0x180D`** → **Heart Rate Measurement `0x2A37`** →
RR-Interval field. Battery via `0x180F`.

This is a *standards* integration, not a vendor one. Any compliant strap works:

```
Generic BLE HR provider
├── Polar H10 / H9 / Verity Sense
├── Garmin HRM-Pro / HRM-Dual
├── Wahoo TICKR / TICKR X
└── other compliant straps (Decathlon, Coospo, Magene, Movesense-based, …)
```

`KnownStraps` maps advertised names to friendly labels for the scan list — it is
**UI copy only, never a gate**. Unknown-but-compliant devices connect anyway.

**Raw input:** continuous RR intervals (units of 1/1024 s) + BPM + battery.

**Coverage:** continuous while worn (~100 %).

**Enables:** everything Apple Watch mode does, **plus** live trigger detection
(~2 minutes), true live coherence during breathing, and clean RR for the
validation study.

**Caveat — the RR field is optional in the spec.** Some straps report heart rate
only. The app therefore probes for ~15 s after connecting; if no RR arrives it
reports `noRRSupport`, downgrades capabilities to `.bleBpmOnly`, and every HRV
indicator switches off with an explanation rather than showing a blank screen.

---

## Indicator matrix

| Indicator | Apple Watch (passive) | + watch workout | Chest strap | Optical armband | BPM-only strap |
|---|---|---|---|---|---|
| Live BPM | ✗ | ✓ | ✓ | ✓ | ✓ |
| SDNN (Apple) | ✓ sparse | ✓ sparse | ✗ | ✗ | ✗ |
| RMSSD / pNN50 / SDSD | ~ occasional¹ | ~ approx | ✓ | ✓ noisier | ✗ |
| Coherence | ✗ | ~ **approx²** | ✓ | ~ noisier | ✗ |
| Resting HR · sleep · workout context | ✓ | ✓ | ✗³ | ✗³ | ✗³ |
| Sustained detection | ✓ (hours–days) | ✓ | ✓ (minutes) | ✓ | ✗ |
| **Live triggers** | ✗ | ✗ | ✓ ~2 min | ✓ | ✗ |

¹ only when an `HKHeartbeatSeriesSample` happens to exist.
² HR-derived, not beat-to-beat — labelled as approximate in the UI.
³ still available if the user also wears a watch: HealthKit context is merged in
regardless of which sensor drives detection (`SensorCapabilities.merging`).

---

## Two baselines, never pooled

**Hard architectural rule.** Apple's SDNN (a handful of resting snapshots a day)
and our strap RMSSD (a 2-minute window every 30 s) are different metrics measured
under different conditions. Pooling them would corrupt both distributions.

- Passive path → `MonitoringCoordinator`'s `BaselineEngine` +
  `AnomalyDetector` (60-day window, 7-day warm-up, `DetectorConfig()`).
- Strap path → `StrapMonitor`'s **own** `BaselineEngine(windowDays: 14,
  minBaselineDays: 1)` + `AnomalyDetector(config: .live)`.

Strap windows are persisted and charted (they show up in the Trends RMSSD view)
but are **never** fed to `MonitoringCoordinator.ingest`. There is a regression
test for exactly this (`StrapPipelineTests`).

`DetectorConfig.live` — `k 2.0`, `persistenceWindow 4` (≈2 min of sustained
drop), `cooldown 30 min`. Starting values; real tuning is the calibration study
(Q-B), alongside `EventShapeClassifier.acuteDepth`.

---

## Where the code lives

| Concern | File |
|---|---|
| Capabilities + presets | `Sources/HRVCore/Sensing/SensorCapabilities.swift` |
| Indicator registry + resolver | `Sources/HRVCore/Sensing/HealthIndicator.swift` |
| BLE payload parser (pure) | `Sources/HRVCore/Signal/HeartRateMeasurement.swift` |
| RR → analysis windows (pure) | `Sources/HRVCore/Signal/RRWindower.swift` |
| Provider protocol + simulator | `App/Sensing/HeartRateProvider.swift` |
| CoreBluetooth transport | `App/Sensing/BLEHeartRateProvider.swift` |
| Continuous monitor + live detector | `App/Sensing/StrapMonitor.swift` |
| Mode enum + persistence | `App/Sensing/SensorMode.swift` |
| Coherence source routing | `App/Coherence/RoutingHeartRateSource.swift` |
| Pairing UI | `App/UI/Screens/StrapSetupView.swift` |
| "What's available" checklist | `App/UI/Components/IndicatorAvailabilityList.swift` |

**Simulator note:** CoreBluetooth has no hardware in the Simulator, so simulator
builds use `SimulatedHeartRateProvider`, which drives the identical pipeline.
Launch with `-strapBpmOnly` to exercise the heart-rate-only path.

## Still to validate on real hardware

- Real payloads from an H10 (and ideally a second brand) parse correctly
- RR sanity (~600–1200 ms), reconnect after range loss, background delivery
- Battery cost of continuous BLE + a 30 s windowed statistics pass
- `bluetooth-central` background mode justification for App Review
