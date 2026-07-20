# App Privacy labels — HRV-C (App Store Connect questionnaire, #9)

מדריך למילוי שאלון **App Privacy** ב-App Store Connect, לפי ההתנהגות האמיתית של האפליקציה.

## העיקרון הקובע
אפל מגדירה **"collect"** = העברת נתונים **מחוץ למכשיר** אל המפתח או צד ג'. HRV-C **אינה מעבירה
שום נתון מהמכשיר** — הכול מקומי (SwiftData, מוחרג מגיבוי, ללא CloudKit/שרת/analytics). לכן,
לפי הגדרת אפל, התשובה הנכונה היא **"Data Not Collected"**.

> מקור בקוד לאימות: `PrivacyStore` (מקומי/ללא CloudKit/מוחרג), `HealthKitService` (קריאה בלבד),
> `AlertService` (Local Notifications), ואין SDK רשת בפרויקט.

## התשובות בשאלון
1. **"Do you or your third-party partners collect data from this app?"** → **No**.
   → התוצאה: התווית **"Data Not Collected"**.

## הנימוק (לשמור לתיעוד, ואם reviewer שואל)
- נתוני הבריאות (HRV/SDNN, ואימונים/שינה/דופק במנוחה לצורך סינון מדידות שאינן במנוחה
  והצגת הקשר עובדתי לאירוע) נקראים מ-Apple Health ומעובדים ונשמרים **על המכשיר בלבד**.
- אין חשבון, אין שרת, אין ניתוח שימוש (analytics), אין פרסום, אין מזהי מעקב.
- התראות הן מקומיות; אינן עוברות דרך שרת.

## דגלים לעתיד (אם ההתנהגות תשתנה — לעדכן את התווית!)
כל אחד מאלה **הופך את התשובה ל-"collected"** ומחייב עדכון:
- הוספת analytics/crash-reporting SDK (למשל Firebase/Sentry).
- סנכרון ענן (CloudKit) או גיבוי נתונים לשרת.
- שיתוף/ייצוא נתונים לצד ג'.
- מצב אקטיבי (D-COH) — אם אי-פעם ישלח נתונים החוצה (כרגע מוקפא ומקומי).

## הערה
"Data Not Collected" הוא מצב פרטיות חזק ותואם למיצוב ה-wellness/local-first. חשוב שיישאר מדויק —
אם מתווספת כל תשתית רשת, לעדכן גם את [`PRIVACY_POLICY.md`](PRIVACY_POLICY.md).
