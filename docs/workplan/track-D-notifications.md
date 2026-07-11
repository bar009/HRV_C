# Track D — התראות מקומיות

**מיקום ב-spine:** S4 · [← חזרה לתזרים הראשי](README.md)
**פלטפורמה:** Mac · **סטטוס:** ✅ קוד נכתב (Mac-only)

## מטרה
לשלוח למשתמש Local Notification כשהדיטקטור מזהה חריגה מאומתת — בניסוח wellness, ללא טענה רפואית.

## תלויות
- **חוסם ב:** [Track B](track-B-healthkit.md) (ה-`AlertEvent` מגיע מה-coordinator).

## קלט
- Deep Dive 6 (התראות), 6.2 (ניסוח), OP-1 (wellness) ב-[`../DECISIONS.md`](../DECISIONS.md)

## משימות
- [x] `AlertService`: בקשת הרשאה + `UNUserNotificationCenter` local notification
- [x] ניסוח wellness ("שינוי בדפוסי המנוחה") — לא אבחנה
- [ ] כיבוד cooldown ברמת ה-UX (כבר נאכף בדיטקטור; לוודא שאין הצפה)
- [ ] בחירה: התראה מהטלפון / השעון / שניהם (Deep Dive 6.3.2)

## Windows-עכשיו / Mac-אחר-כך
נכתב עכשיו. `UserNotifications` הוא framework של אפל → בדיקה על מכשיר.

## Definition of Done
- התראה נשלחת רק על חריגה מאומתת (persistence עבר), ולא יותר מאחת ל-cooldown.
- הניסוח עבר בדיקה משפטית בסיסית (אין טענה רפואית).

## אימות
- סימולציית ירידה מתמשכת על מכשיר → מגיעה התראה אחת; רעש → לא מגיעה.
