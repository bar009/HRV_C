# Track H — אימות על מכשיר + כיול

**מיקום ב-spine:** S7 · [← חזרה לתזרים הראשי](README.md)
**פלטפורמה:** Mac + iPhone + Apple Watch · **סטטוס:** ⬜ דורש מכשיר

## מטרה
לסגור את שתי הנקודות הפתוחות שדורשות נתונים אמיתיים: זמינות סדרות פעימה פסיביות (Q-A)
וערכי הכיול הסופיים (Q-B).

## תלויות
- **חוסם ב:** [Track B](track-B-healthkit.md) (זרם נתונים), [Track D](track-D-notifications.md) (התראות).

## קלט
- Q-A, Q-B ב-[`../DECISIONS.md`](../DECISIONS.md) · Deep Dive A.2 (בדיקת שדה) · B.7 (פרמטרים)
- כלי הכיול הקיים: `sim/run_scenario.py` (נותן ערכי התחלה: k=2.0, persistence=3, cooldown=8h)

## משימות
- [ ] **Q-A:** בדיקת שדה 3–5 ימים — לספור כמה `HKHeartbeatSeriesSample` מגיעים פסיבית.
      התוצאה קובעת אם `RRExtractor` שווה מאמץ.
- [ ] **Q-B:** לאסוף baseline אישי אמיתי (7–14 יום) ולכייל `k`/`persistence`/`cooldown`
      מול אירועים ידועים (מאמץ, מחלה, לילה גרוע).
- [ ] לבדוק false-positives על נתונים אמיתיים; להשוות להתנהגות הסימולציה.
- [ ] דוח צריכת סוללה (Deep Dive 8.3.2).

## Windows-עכשיו / Mac-אחר-כך
כולו דורש מכשיר פיזי — Mac + iPhone + Watch מזווגים.

## Definition of Done
- ערכי `k`/`persistence`/`cooldown` ננעלו על סמך נתונים אמיתיים.
- הוכרע אם מוסיפים את מסלול ה-RRExtractor (Q-A).

## אימות
- אירוע ידוע (למשל יום אחרי לילה גרוע) מפיק התראה; ימים תקינים שקטים.
