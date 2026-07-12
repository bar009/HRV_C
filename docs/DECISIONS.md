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
| Q-C | גרסת iOS מינימלית | **iOS 17 / watchOS 10** → מנוע אחסון **SwiftData** | Deep Dive C.5 |
| D-BUILD | ייצור פרויקט Xcode | **XcodeGen** (`project.yml` דקלרטיבי, לא `.pbxproj` ידני) | Track G |
| D-SPLIT | ארכיטקטורת קוד | `HRVCore` (SPM, Foundation בלבד, בר-אימות מחוץ ל-Mac) נפרד מקוד האפליקציה (Xcode) | Track A/G |

## המלצות פתוחות (לא חוסמות את שלב הליבה)

| # | נקודה | המלצה | מתי להכריע |
|---|--------|--------|-------------|
| OP-1 | "אבחוני" מול wellness | **להתחיל wellness** (חשיפה משפטית נמוכה; §9.3.3) | לפני שלב Notifications / פרסום |
| OP-2 | נלווה לספר או עצמאי | — | לפני מיצוב App Store |
| OP-3 | קהל יעד: בריא מול חולה | — | לפני כיול ספי ההתראה |

## נקודות פתוחות שדורשות מכשיר אמיתי / כיול

| # | נקודה | סטטוס | סוגר את |
|---|--------|--------|----------|
| Q-A | כמה `HKHeartbeatSeriesSample` מגיעים פסיבית? (נוטה לשלילה) | ממתין ל-Apple Watch. ייצוא ראשון היה משעון **Huawei** → 0 HRV (פער מקור, לא רעיון) | האם `RRExtractor` שווה מאמץ (A.2/A.6.1) |
| Q-B | ערכי `k` / `persistence` / `cooldown` סופיים | מנוע הכיול (`analysis/`) בנוי ומאומת על נתונים סינתטיים; ממתין ל-HRV אמיתי מ-Apple Watch | לב לוגיקת ההתראה (B.7) |
| Q-C | גרסת iOS מינימלית נתמכת | ✅ נסגר: **iOS 17 → SwiftData** | — |

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

## סטטוס פורט ה-Swift (`swift/`)

| שכבה | מצב |
|------|-----|
| `HRVCore` (Signal/Detection/Persistence) + XCTest | ✅ נכתב + **`swift test` ירוק על Windows ARM64** (23 XCTest = parity מול pytest) |
| App: HealthKit, Coordinator, SwiftData, Notifications, SwiftUI | ✅ נכתב (Mac-only, לא מקומפל עד Mac) |
| watchOS | 🟡 שלד מינימלי |
| `project.yml` / `Info.plist` / entitlements | ✅ נכתב |
| אימות: `swift test` על Windows | ✅ ירוק — Swift 6.3.3 + VS Build Tools (C++/ARM64) + Win11 SDK; מתכון: [`swift/win-swift-test.cmd`](../swift/win-swift-test.cmd) |

## יכולות מדידה ובדיקת נתונים אמיתיים

- **יכולות מאומתות מול Apple** ([`capabilities.md`](capabilities.md)): כל מה שהנחנו קיים על
  Apple Watch — נייטיב (SDNN, RR/heartbeat-series, ECG, דופק/שינה/SpO2) או מחושב אצלנו מ-RR
  (RMSSD, pNN50, Coherence). RMSSD ו-Coherence אינם נייטיב — תמיד תוכננו כמחושבים (A.6, D-COH).
- **ממצא feasibility:** ייצוא ראשון (Huawei, 410MB) הכיל **0 HRV** — פער של מקור-הנתונים
  (Huawei לא כותב SDNN ל-HealthKit), לא כשל של הרעיון. שפע דופק/שינה/SpO2, אך דופק=ממוצע BPM
  (לא RR) ולכן לא בר-המרה ל-RMSSD.
- **מנוע הכיול** ([`../analysis/`](../analysis/)): parser זורם ל-`export.xml` + `calibrate`/`report`,
  מאומת על נתונים סינתטיים (`make_sample_export`). מוכן ל-HRV אמיתי מ-Apple Watch (Breathe+שינה).
- **בדיקה נוכחית = נתונים סינתטיים** (אישור המשתמש): בודקים את הצינור והנוסחאות ותופסים באגים.

מסלול העבודה המלא: [`workplan/README.md`](workplan/README.md).
