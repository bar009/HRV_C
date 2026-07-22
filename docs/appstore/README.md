# App Store submission bundle — HRV-C

כל התוכן להגשת האפליקציה ל-App Store, מוכן להעתק-הדבק ל"יום ה-Mac". משלים את
[`../LAUNCH_CHECKLIST.md`](../LAUNCH_CHECKLIST.md) (הסטטוסים) — כאן נמצא **התוכן עצמו**.

> ⚠️ **לא ייעוץ משפטי.** אלה טיוטות שנכתבו לפי התנהגות האפליקציה בפועל. יש לעבור עליהן,
> למלא את ה-placeholders, ולשקול בדיקה משפטית — במיוחד מסגור ה-wellness (לא-רפואי).

## Placeholders למילוי (חוזרים בכל המסמכים)
`Trigger Bitter` · `bar16072000@gmail.com` · `{{SUPPORT_URL}}` · `{{MARKETING_URL}}` ·
`{{PRIVACY_URL}}` · `23 ביולי 2026` · `ישראל` (ברירת מחדל: ישראל)

## הקבצים → לאן הם הולכים

| קובץ | פריט checklist | יעד |
|------|----------------|-----|
| [`PRIVACY_POLICY.md`](PRIVACY_POLICY.md) | #8 | לארח באתר (למשל GitHub Pages) → הכתובת נכנסת ל-ASC "Privacy Policy URL" + קישור מ-Settings |
| [`APP_STORE_LISTING.md`](APP_STORE_LISTING.md) | #4 | ASC → App Information / Localizable (שם, subtitle, description, keywords, promo) |
| [`MEDICAL_DEVICE_STATEMENT.md`](MEDICAL_DEVICE_STATEMENT.md) | #12→#4 | מוטמע בתיאור + Review Notes (וכבר באפליקציה) |
| [`REVIEW_NOTES.md`](REVIEW_NOTES.md) | #11 | ASC → App Review Information → Notes |
| [`APP_PRIVACY_LABELS.md`](APP_PRIVACY_LABELS.md) | #9 | ASC → App Privacy (שאלון) |
| [`AGE_RATING_AND_DSA.md`](AGE_RATING_AND_DSA.md) | #13, #14 | ASC → Age Rating + Trader status (DSA) |
| [`QA_CHECKLIST.md`](QA_CHECKLIST.md) | #16, #15, אימות-#6 | על ה-Mac/מכשיר לפני הגשה |

## Mac-day runbook (סדר פעולות)
1. **בנייה:** `cd swift && xcodegen generate && open HRV.xcodeproj` → build & run על iPhone+Watch מזווגים.
2. **QA:** לעבור על [`QA_CHECKLIST.md`](QA_CHECKLIST.md) — כולל אימות #6 (גיבוי/הצפנה) ו-Demo Mode.
3. **אירוח Privacy Policy:** לפרסם את [`PRIVACY_POLICY.md`](PRIVACY_POLICY.md) לכתובת ציבורית → `{{PRIVACY_URL}}`.
4. **App Store Connect:** למלא App Information + Localizable מ-[`APP_STORE_LISTING.md`](APP_STORE_LISTING.md); Privacy מ-[`APP_PRIVACY_LABELS.md`](APP_PRIVACY_LABELS.md); Age/DSA מ-[`AGE_RATING_AND_DSA.md`](AGE_RATING_AND_DSA.md); Review Notes מ-[`REVIEW_NOTES.md`](REVIEW_NOTES.md).
5. **TestFlight** → **Submit for Review**.

**תלות-על:** Mac + Xcode + Apple Developer ($99/שנה).
