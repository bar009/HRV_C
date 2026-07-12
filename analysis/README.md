# analysis/ — real-data calibration on an Apple Health export

Runs the passive core (`hrv_core`) on a real Apple Health export — **Mac-independent**.
Answers Track H: personal calibration of `k`/`persistence`/`cooldown` (Q-B) and passive
SDNN density (Q-A). Validate the pipeline now on synthetic data; run on a real Apple
Watch export later.

## Test the pipeline now (synthetic data)
```bash
python -m analysis.make_sample_export sample.xml   # fake Apple-Health export with HRV
python -m analysis.report    sample.xml            # what's in it (types, span, HRV?)
python -m analysis.calibrate sample.xml --plot     # density + baseline + detector + sweep + plot
```

## Collect real HRV (Apple Watch)
HRV SDNN is written mainly by the **Mindfulness/Breathe** app and during sleep. A Huawei
watch does **not** write HRV to Apple Health (see `docs/capabilities.md`). To get real HRV:

1. Pair the Apple Watch to **this** iPhone (HRV lands on the paired phone).
2. Do **1–2 Breathe/Mindfulness sessions per day** + wear the watch during sleep, ~1–2 weeks.
3. iPhone **Health** app → profile → **Export All Health Data** → unzip → `apple_health_export/export.xml`.

## Calibrate on your real export
```bash
python -m analysis.report    path/to/export.xml
python -m analysis.calibrate path/to/export.xml --plot --out my_hrv.png
```
Then lock the chosen `k`/`persistence`/`cooldown` in `docs/DECISIONS.md`.

> **Never commit the export or any health data** (AGENTS.md). The parser streams the file
> (`iterparse`), so a multi-hundred-MB export is fine.
