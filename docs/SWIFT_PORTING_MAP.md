# מפת המרה ל-Swift — HRV-C

הליבה ב-`hrv_core/` נכתבה כ**מפרט בר-הרצה**. כשיהיה Mac, כל מודול עובר ל-Swift לפי
הטבלה. הפונקציות הטהורות (Signal, Detection) הן פורט מכני 1:1; ה-oracle הוא `tests/` —
בדיקות ה-XCTest צריכות לשחזר את אותם מספרים בדיוק על אותם test vectors.

## מיפוי מודולים

| Python (עכשיו) | Swift (על Mac — Deep Dive D.3) | סוג הפורט |
|---|---|---|
| `hrv_core/signal/calculator.py` | `Signal/HRVCalculator.swift` (A.6.3) | 1:1 מכני |
| `hrv_core/signal/artifact.py` | `Signal/ArtifactCorrector.swift` (A.6.2) | 1:1 מכני |
| `hrv_core/signal/models.py` | `Signal/Models/{HRVSample,SampleQuality,HRVMetric,HRVSource}.swift` (A.5) | 1:1 |
| `hrv_core/detection/baseline.py` | `Detection/BaselineEngine.swift` (B.8.1) | 1:1 מכני |
| `hrv_core/detection/detector.py` | `Detection/AnomalyDetector.swift` (B.8.2) | 1:1 מכני |
| `hrv_core/detection/models.py` | `Detection/Models/{Baseline,DetectorState,DetectorConfig,AlertEvent,SampleContext}.swift` (B.7) | 1:1 |
| `hrv_core/persistence/repository.py` | `Persistence/HRVRepository.swift` (protocol, C.7) + `SwiftDataRepository.swift` | חתימה זהה, מימוש חדש |
| `tests/` | `Tests/` (XCTest) — אותם test vectors | הבדיקות מוכיחות שהפורט זהה מספרית |

## מה אין לו מקבילה ב-Python (חדש לגמרי על ה-Mac)

| רכיב | תפקיד | הערה |
|------|-------|------|
| `DataAccess/HealthKitService.swift` | ObserverQuery, background delivery, anchors, שליפת דגימות (D.1) | HealthKit קיים רק על מכשיר אמיתי — כאן הוזרק נתון סינתטי במקומו |
| `Notification/AlertService.swift` | Local Notifications | פשוט; אחרון בסדר המימוש |
| `Orchestration/MonitoringCoordinator.swift` | מחבר את הזרימה מקצה-לקצה (D.2) | ב-Python המקבילה הרעיונית היא `sim/run_scenario.py` |
| watchOS target + Workout Session | זרם פעימות צפוף (רלוונטי בעיקר ל-Coherence העתידי) | ראה D-COH |
| SwiftUI views | UI | לא נכלל בליבה |

## עקרונות ששומרים על הפורט מכני

1. **`hrv_core/` = stdlib בלבד** — אין numpy/pandas בליבה, כדי שכל שורה תהיה לה מקבילה
   ישירה ב-Swift. numpy/matplotlib חיים רק ב-`sim/` ו-`tests/`.
2. **פונקציות טהורות** ב-Signal ו-Detection — בלי תלות ב-I/O, בדיוק כמו החתימות ב-Deep Dive.
3. **Protocol אחד לאחסון** — מחליפים in-memory ↔ SwiftData/GRDB בלי לגעת בלוגיקה.
4. **"אין מדידה" הוא ערך לגיטימי** — `None`/`nil` וגם `LOW_QUALITY` במקום ניחוש.

## סדר המרה מומלץ (Deep Dive D.4)

1. `HealthKitService` + anchors — לוודא שדגימות נכנסות ברקע ולא כפולות.
2. Signal (פורט מ-`calculator.py` + `artifact.py`) — לבדוק מול אותם test vectors.
3. `BaselineEngine` — לצבור baseline על נתונים אמיתיים.
4. `AnomalyDetector` — רק אחרי שיש baseline לכייל מולו.
5. `AlertService` — אחרון.
