# החלטות ונקודות פתוחות — HRV-C

מסמך חי שמרכז את מצב ההחלטות. מקורות מלאים: [`HRV_App_Spec.md`](HRV_App_Spec.md),
[`HRV_Architecture_Deep_Dive.md`](HRV_Architecture_Deep_Dive.md),
[`HRV_Research_HeartMath.md`](HRV_Research_HeartMath.md).

## החלטות שנסגרו

| # | החלטה | הבחירה | מקור |
|---|--------|---------|------|
| D2 | מודל ניטור | פסיבי לאורך היום (v1) | Spec §0.2 |
| D3 | פלטפורמה | iOS + watchOS משלנו | Spec §0.2 |
| D4 | אחסון | מקומי בלבד, ללא ענן | Spec §0.2 |
| **D-COH** | מצב מדידה אקטיבי (Coherence)? | **פסיבי-קודם** — Coherence נדחה למודול נפרד עתידי (`hrv_core/coherence/`) | Spec §0.4 |
| D-OP4 | מקור HRV | Hybrid: SDNN של אפל ראשי, RMSSD מ-RR משני/אופורטוניסטי | Deep Dive A.2 |
| OP-5 | שיטת סף | robust z-score על `ln(RMSSD)` עם median + MAD | Deep Dive B.3 |

## המלצות פתוחות (לא חוסמות את שלב הליבה)

| # | נקודה | המלצה | מתי להכריע |
|---|--------|--------|-------------|
| OP-1 | "אבחוני" מול wellness | **להתחיל wellness** (חשיפה משפטית נמוכה; §9.3.3) | לפני שלב Notifications / פרסום |
| OP-2 | נלווה לספר או עצמאי | — | לפני מיצוב App Store |
| OP-3 | קהל יעד: בריא מול חולה | — | לפני כיול ספי ההתראה |

## נקודות פתוחות שדורשות מכשיר אמיתי / כיול

| # | נקודה | סטטוס | סוגר את |
|---|--------|--------|----------|
| Q-A | כמה `HKHeartbeatSeriesSample` מגיעים פסיבית? (נוטה לשלילה) | בדיקת שדה 3–5 ימים על מכשיר אמיתי | האם `RRExtractor` שווה מאמץ (A.2/A.6.1) |
| Q-B | ערכי `k` / `persistence` / `cooldown` סופיים | הסימולציה נותנת ערכי התחלה; כיול סופי דורש נתונים אמיתיים | לב לוגיקת ההתראה (B.7) |
| Q-C | גרסת iOS מינימלית נתמכת | פתוח | בחירת מנוע אחסון: SwiftData (17+) מול GRDB (C.5) |

## סטטוס מימוש (הליבה הפסיבית ב-Python)

| שכבה | מודול | מצב |
|------|-------|-----|
| Signal | `HRVCalculator` (RMSSD/SDNN/pNN50/SDSD) | ✅ מומש + נבדק |
| Signal | `ArtifactCorrector` (טווח + Malik 20% + quality gate) | ✅ מומש + נבדק |
| Detection | `BaselineEngine` (חלון נע, median+MAD על ln) | ✅ מומש + נבדק |
| Detection | `AnomalyDetector` (robust-z + מכונת מצבים + cooldown + context) | ✅ מומש + נבדק |
| Persistence | `InMemoryHRVRepository` (סכמה לוגית C.6) | ✅ מומש |
| Sim | מחולל סינתטי + `run_scenario` | ✅ מומש |
| Coherence | מצב אקטיבי / תחום-תדר (D-COH) | ⏸️ נדחה (מכוון) |
| Native | Xcode / HealthKit / watchOS / Notifications / SwiftData | ⏸️ ממתין ל-Mac |
