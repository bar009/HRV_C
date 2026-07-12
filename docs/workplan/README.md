# תזרים העבודה — HRV-C (התזרים הראשי)

זהו ה**מסלול הראשי (spine)** — נקרא מלמעלה למטה, מ"אין כלום" ועד אפליקציה משוחררת. כל שלב
מקושר ל**מסמך track** מפורט. ה-tracks הם תזרימי-המשנה: מחולקים לפי אחריות, ומקושרים חזרה לכאן.

**מקרא סטטוס:** ✅ הושלם · 🟡 בעבודה · ⬜ טרם התחיל · 🔒 מוקפא במכוון

## המסלול מקצה לקצה

| S | שלב | Track | פלטפורמה | סטטוס | תלוי ב־ |
|---|------|-------|----------|--------|---------|
| S0 | Toolchain + bootstrap פרויקט | [G](track-G-project-setup.md) | Windows + Mac | ✅ | — |
| S1 | פורט הליבה (HRVCore + XCTest oracle) | [A](track-A-core-port.md) | **Windows-מאומת ✅** | ✅ | S0 |
| S2 | מנוע אחסון (SwiftData) | [C](track-C-persistence.md) | Mac | ✅ קוד | S1 |
| S3 | גישת נתונים (HealthKit) + Orchestration | [B](track-B-healthkit.md) | Mac + מכשיר | ✅ קוד | S1, S2 |
| S4 | התראות מקומיות | [D](track-D-notifications.md) | Mac | ✅ קוד | S3 |
| S5 | UI ל-iOS | [F](track-F-ios-ui.md) | Mac | ✅ קוד | S2, S3 |
| S6 | אפליקציית watchOS | [E](track-E-watchos.md) | Mac | 🟡 מינימלי | S3 |
| S7 | אימות על מכשיר + כיול (Q-A, Q-B) | [H](track-H-validation-calibration.md) | Mac + מכשיר | ⬜ | S3, S4 |
| S8 | App Store + רגולציה (wellness) | [I](track-I-appstore-regulatory.md) | Mac | ⬜ | הכול |
| — | Coherence / מצב אקטיבי (D-COH) | [J](track-J-coherence-parked.md) | — | 🔒 | S8 |

## השלבים (נרטיב)

**S0 — Toolchain + bootstrap ([Track G](track-G-project-setup.md)).**
להתקין Swift, לאשר ש-`swift test` רץ, וליצור את שלד הפרויקט (`Package.swift`, `project.yml`,
`Info.plist`, entitlements). בלי זה שום דבר לא נבנה. *הושלם: Swift 6.3.3 + VS Build Tools
(C++/ARM64) + Windows SDK מותקנים; `swift\win-swift-test.cmd` בונה ומריץ את הבדיקות ירוק.*

**S1 — פורט הליבה ([Track A](track-A-core-port.md)). ✅**
פורט 1:1 של `hrv_core/` ל-`Sources/HRVCore` + `HRVCoreTests`. אבן-הדרך הושגה: `swift test`
ירוק על Windows ARM64 (23 XCTest, 0 כשלונות) עם אותם test vectors כמו `tests/` בפייתון —
ה-parity מוכח. הליבה תלויה ב-Foundation בלבד ולכן מתקמפלת מחוץ ל-Mac.

**S2 — אחסון ([Track C](track-C-persistence.md)).**
`SwiftDataRepository` שמממש את `HRVRepository` (אותו protocol כמו ה-in-memory). HealthKit הוא
כבר ה-DB הגולמי — שומרים רק דגימות מעובדות, baseline, התראות, ו-anchors.

**S3 — נתונים + Orchestration ([Track B](track-B-healthkit.md)).**
`HealthKitService` (ObserverQuery + background delivery + anchors) מזרים דגימות אמיתיות
במקום הסינתטיות; `MonitoringCoordinator` מחבר HealthKit → Signal/Detection → Persistence →
Notification (המקבילה ל-`sim/run_scenario.py`).

**S4 — התראות ([Track D](track-D-notifications.md)).**
`AlertService` שולח Local Notification בניסוח wellness כשהדיטקטור מזהה חריגה מאומתת.

**S5 — UI ל-iOS ([Track F](track-F-ios-ui.md)).**
SwiftUI: onboarding/הרשאות, מסך סטטוס, גרף מגמה (SwiftData `@Query` + Charts), היסטוריית
התראות.

**S6 — watchOS ([Track E](track-E-watchos.md)).**
target מינימלי לשעון (סטטוס + התראות). זרם הפעימות הצפוף וה-Workout Session שמורים למצב
האקטיבי העתידי (D-COH).

**S7 — אימות וכיול ([Track H](track-H-validation-calibration.md)).**
בדיקת שדה 3–5 ימים על iPhone+Watch מזווגים: כמה `HKHeartbeatSeriesSample` מגיעים פסיבית
(Q-A), וכיול `k`/`persistence`/`cooldown` על נתונים אמיתיים (Q-B).

**S8 — App Store + רגולציה ([Track I](track-I-appstore-regulatory.md)).**
מיצוב wellness (OP-1), Privacy Nutrition Labels, disclaimer, והכנה ל-App Review.

**Coherence — מוקפא ([Track J](track-J-coherence-parked.md)).**
מצב מדידה אקטיבי (תחום-תדר / FFT). לא נכתב קוד עד שהמסלול הפסיבי מסתיים — החלטת D-COH.

## מפת תלויות

```
G ─► A ─┬─► C ─┬─► F
        │      │
        └─► B ─┼─► D ─► H ─► I
               │
               └─► E
        (J מוקפא, אחרי I)
```

## החלטות והקשר
- **מיפוי לשיטת "קוד התת-מודע" (ה"למה" מאחורי המוצר):** [`../method-mapping.md`](../method-mapping.md)
- החלטות ננעלות ונקודות פתוחות: [`../DECISIONS.md`](../DECISIONS.md)
- מיפוי Python→Swift: [`../SWIFT_PORTING_MAP.md`](../SWIFT_PORTING_MAP.md)
- אפיון וארכיטקטורה מלאים: [`../HRV_App_Spec.md`](../HRV_App_Spec.md) · [`../HRV_Architecture_Deep_Dive.md`](../HRV_Architecture_Deep_Dive.md)
