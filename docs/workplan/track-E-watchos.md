# Track E — אפליקציית watchOS

**מיקום ב-spine:** S6 · [← חזרה לתזרים הראשי](README.md)
**פלטפורמה:** Mac + Apple Watch · **סטטוס:** 🟡 target מינימלי נכתב

## מטרה
נוכחות על השעון: הצגת סטטוס והתראות. במסלול הפסיבי הטלפון קורא HealthKit ומחזיק את
הדיטקטור, כך שהשעון מינימלי. השעון הופך מרכזי רק במצב האקטיבי (D-COH).

## תלויות
- **חוסם ב:** [Track B](track-B-healthkit.md) (מקור המצב).
- **מזין את:** [Track J](track-J-coherence-parked.md) (Workout Session לזרם פעימות צפוף).

## קלט
- Deep Dive 1.1.2 (target נלווה), D-COH (מצב אקטיבי) ב-[`../DECISIONS.md`](../DECISIONS.md)

## משימות
- [x] target watchOS (`HRVWatchApp`, `WatchStatusView`) — שלד
- [ ] שיתוף מצב מהטלפון: WatchConnectivity / App Group
- [ ] (D-COH בלבד) `HKWorkoutSession` לזרם פעימות צפוף + לולאת biofeedback

## Windows-עכשיו / Mac-אחר-כך
השלד נכתב עכשיו. כל השאר על Mac + שעון פיזי.

## Definition of Done
- אפליקציית השעון עולה, מציגה סטטוס עדכני, ומגיבה להתראות.

## אימות
- הרצה על Apple Watch מזווג; לוודא שהמצב שמוצג תואם את הטלפון.
