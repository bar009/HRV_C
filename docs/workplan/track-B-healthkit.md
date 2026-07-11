# Track B — גישת נתונים (HealthKit) + Orchestration

**מיקום ב-spine:** S3 · [← חזרה לתזרים הראשי](README.md)
**פלטפורמה:** Mac + מכשיר פיזי · **סטטוס:** ✅ קוד נכתב (Mac-only, לא מקומפל עד Mac)

## מטרה
להזרים דגימות HRV אמיתיות מ-HealthKit במקום הנתונים הסינתטיים, ולחבר את כל הצינור מקצה לקצה.

## תלויות
- **חוסם ב:** [Track A](track-A-core-port.md) (Signal/Detection), [Track C](track-C-persistence.md) (anchors + שמירה).
- **מזין את:** [Track D](track-D-notifications.md), [Track F](track-F-ios-ui.md).

## קלט
- מקור רעיוני: `sim/run_scenario.py` (זרימת ה-orchestration)
- ארכיטקטורה: Deep Dive D.1 (HealthKitService), D.2 (זרימה), A.2/D-OP4 (מקור hybrid)

## משימות
- [x] `HealthKitService`: `HKObserverQuery` + `enableBackgroundDelivery` + `HKAnchoredObjectQuery`, סריאליזציית anchor, המרה ל-`HRVSample`
- [x] `MonitoringCoordinator`: HealthKit → detector → repository → alerts, `@Observable` ל-UI
- [ ] (Q-A, [Track H](track-H-validation-calibration.md)) מסלול משני: `RRExtractor` מ-`HKHeartbeatSeriesSample` — רק אם בדיקת השדה מצדיקה
- [ ] טיפול ברקע: זמן ריצה קצר, `BGProcessingTask` לעיבוד כבד
- [ ] context stratification אמיתי (דופק/שינה) במקום `isRestful=true` הקבוע

## Windows-עכשיו / Mac-אחר-כך
הקוד נכתב עכשיו מול ה-API המתועד. HealthKit קיים רק על מכשיר — קומפילציה, הרשאות ובדיקת
הזרמים כולן על iPhone פיזי + Watch. הסימולטור כמעט לא תומך ב-HealthKit.

## Definition of Done
- דגימות דופק/HRV נכנסות למאגר גם ברקע, בלי כפילויות (anchor עובד).
- הזרימה מקצה לקצה מייצרת התראה על ירידה מאומתת בנתונים אמיתיים.

## אימות
- על מכשיר: לחיות יום מלא; לוודא שדגימות נכנסות (log/DB) ושאין כפילויות.
- הזרקת מגמת ירידה (מנוחה מודרכת) → לוודא שהצינור מגיב.
