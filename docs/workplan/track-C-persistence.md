# Track C — מנוע אחסון (SwiftData)

**מיקום ב-spine:** S2 · [← חזרה לתזרים הראשי](README.md)
**פלטפורמה:** Mac · **סטטוס:** ✅ קוד נכתב (Mac-only)

## מטרה
מימוש `HRVRepository` מעל SwiftData — אותו protocol כמו `InMemoryHRVRepository`, כך שהלוגיקה
מעליו לא משתנה כלל.

## תלויות
- **חוסם ב:** [Track A](track-A-core-port.md) (ה-protocol וה-DTOs).
- **מזין את:** [Track B](track-B-healthkit.md) (anchors), [Track F](track-F-ios-ui.md) (`@Query`).

## קלט
- סכמה לוגית: Deep Dive C.6 · protocol: C.7 · תובנת "HealthKit הוא ה-DB": C.1

## משימות
- [x] `@Model` types: `StoredSample`, `StoredBaseline`, `StoredAlert`, `StoredAnchor`
- [x] `SwiftDataRepository: HRVRepository` (fetch/insert/upsert/anchor)
- [ ] הצפנת מנוחה: `NSFileProtectionComplete` (Deep Dive 7.3)
- [ ] מדיניות retention/דחיסה לנתונים ישנים (Deep Dive 7.2.2)
- [ ] החלטת גרסת iOS מינימלית ננעלה על **17** → SwiftData (סוגר את Q-C)

## Windows-עכשיו / Mac-אחר-כך
נכתב עכשיו. SwiftData קיים רק ב-SDK של אפל → קומפילציה ובדיקה על Mac.

## Definition of Done
- נתונים נשמרים ונטענים בין הפעלות; baseline/alerts/anchors נשמרים.
- החלפת המימוש (in-memory ↔ SwiftData) לא נוגעת בשכבת Detection.

## אימות
- Unit test מול `InMemoryHRVRepository` מוכיח את החוזה; על Mac, בדיקת persistence אמיתית
  (הפעלה מחדש → הנתונים קיימים).
