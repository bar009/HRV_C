# Launch Readiness Checklist — HRV-C

רשימת-סיום לפני העלאה ל-App Store. כל פריט ממופה ל**סטטוס** ול**בעלים** (מי/איפה סוגרים אותו):
🟩 קוד (עשוי/עושים כאן) · 🍎 Mac/Xcode · ☁️ App Store Connect · 🌐 אתר/משפטי.

> **תלות-על:** ההעלאה עצמה דורשת **Mac + Xcode + חשבון Apple Developer ($99/שנה)**. ה-Mac מגיע בעוד ~חודשיים.
> כל פריטי ה-☁️/🍎/🌐 ממתינים לזה; פריטי ה-🟩 אפשר לסגור עכשiv.

> 📦 **חבילת התוכן** לכל הפריטים החסומים (Privacy Policy, תיאור+disclaimer, Review Notes, Medical Device,
> App Privacy labels, Age Rating/DSA, QA) מוכנה ב-[`appstore/`](appstore/README.md) — העתק-הדבק ליום ה-Mac.

## הרשימה

| # | פריט | סטטוס | בעלים | מה נדרש / הערה |
|---|------|--------|--------|----------------|
| 1 | **HealthKit permissions מדויקות** | ✅ | 🟩 | סט הבקשה צומצם ל-**SDNN + heartRate** בלבד (heartbeat/RR הוסר עד ש-RRExtractor ינחת — Q-A), ומחרוזת `NSHealthShareUsageDescription` חודדה לתאום. אימות סופי מול Apple Review ב-🍎 |
| 2 | **מסך הסבר לפני בקשת HealthKit** | ✅ | 🟩 | Onboarding M2.1 (Value & Privacy) לפני M2.2 (Apple Health); גם מסך `setupRequired` מסביר לפני `requestHealthAccess()` |
| 3 | **ניסוח Wellness עקבי** | ✅ | 🟩 | guardrails נאכפים: "זהו כלי wellness, לא אבחון רפואי" (onboarding/setup/Settings); "זוהה שינוי מתמשך" ולא "לופ"; אין טענת רגש/אבחנה |
| 4 | **כתב ויתור רפואי** | 🟢 תוכן מוכן | 🟩 + ☁️/🌐 | קיים באפליקציה; ה-disclaimer לתיאור החנות מוכן ב-[`appstore/APP_STORE_LISTING`](appstore/APP_STORE_LISTING.md) + [`MEDICAL_DEVICE_STATEMENT`](appstore/MEDICAL_DEVICE_STATEMENT.md) |
| 5 | **שמירה מקומית בלבד** | ✅ | 🟩 | SwiftData מקומי, בלי backend/ענן/analytics (AGENTS.md) |
| 6 | **חסימת גיבוי iCloud לנתונים רגישים** | ✅ קוד (אימות 🍎) | 🟩 | `PrivacyStore.makeContainer()`: `ModelConfiguration(cloudKitDatabase: .none)` + `isExcludedFromBackup` + `FileProtectionType.completeUnlessOpen` על ה-store וה-sidecars. אימות ההתנהגות בפועל ב-Mac |
| 7 | **מחיקת כל המידע מהאפליקציה** | ✅ | 🟩 | `coordinator.deleteAllData()` (מוחק את כל מודלי SwiftData, מאפס engine/detector, baseline, events, `didOnboard`) + מקטע "נתונים" ב-Settings עם דיאלוג אישור |
| 8 | **Privacy Policy (אתר + אפליקציה)** | 🟢 תוכן מוכן | 🌐 + 🟩 | טיוטה מלאה ב-[`appstore/PRIVACY_POLICY`](appstore/PRIVACY_POLICY.md); נותר לארח בכתובת ציבורית ולקשר |
| 9 | **App Privacy labels לפי התנהגות אמיתית** | 🟢 תוכן מוכן | ☁️ | מיפוי מדויק ב-[`appstore/APP_PRIVACY_LABELS`](appstore/APP_PRIVACY_LABELS.md): **Data Not Collected** (הכול מקומי) |
| 10 | **Demo Mode לבודק** | ✅ | 🟩 | `DemoData.generate()` (מקביל ל-`sim/synthetic`) + `coordinator.loadDemoData()` דרך הצינור האמיתי; כפתור "טעינת נתוני הדגמה" ב-Settings → הבודק רואה Learning→Stable+Event בלי Apple Watch |
| 11 | **Review Notes מפורטים** | 🟢 תוכן מוכן | ☁️ | מוכן (אנגלית, כולל צעדי Demo Mode) ב-[`appstore/REVIEW_NOTES`](appstore/REVIEW_NOTES.md) |
| 12 | **הצהרת Medical Device** | 🟢 תוכן מוכן | ☁️ + 🌐 | HE+EN ב-[`appstore/MEDICAL_DEVICE_STATEMENT`](appstore/MEDICAL_DEVICE_STATEMENT.md) |
| 13 | **Age Rating** | 🟢 תוכן מוכן | ☁️ | המלצה 4+ + רציונל ב-[`appstore/AGE_RATING_AND_DSA`](appstore/AGE_RATING_AND_DSA.md) |
| 14 | **DSA status (אירופה)** | 🟢 תוכן מוכן | ☁️ | אפשרויות + המלצה (non-trader) ב-[`appstore/AGE_RATING_AND_DSA`](appstore/AGE_RATING_AND_DSA.md) — המשתמש מאשר |
| 15 | **בדיקות TestFlight (iPhone + Apple Watch)** | ⬜ (checklist מוכן) | 🍎 + ☁️ | צעדים ב-[`appstore/QA_CHECKLIST`](appstore/QA_CHECKLIST.md §F); דורש Mac + חשבון |
| 16 | **אפס קריסות / מסכים ריקים / טקסט זמני** | 🟡 (checklist מוכן) | 🍎 (QA) | מעבר QA מלא ב-[`appstore/QA_CHECKLIST`](appstore/QA_CHECKLIST.md); UI ראשי מלא; watchOS מינימלי |

## מה נסגר בקוד (🟩, בלי Mac) — ✅ בוצע
פריטים **1, 6, 7, 10** מומשו: צמצום בקשת HealthKit + חידוד מחרוזת (#1), `PrivacyStore` ללא-CloudKit/לא-מגובה/מוגן (#6),
`deleteAllData()` + Settings (#7), ו-`DemoData`/`loadDemoData()` + Settings (#10). כל קוד ה-App הזה **Mac-only ולא מקומפל על
Windows** — נכתב מול ה-API המתועד; קומפילציה ו-QA ב-Xcode. אימות התנהגותי של #6 (גיבוי/הצפנה) דורש מכשיר 🍎.

## מה תלוי ב-Mac / חשבון / אתר
**כל תוכן ה-☁️/🌐 כבר כתוב ומחכה ב-[`appstore/`](appstore/README.md)** — נותר רק להעלות/לארח ולמלא שדות ביום ה-Mac.
- 🍎 **Mac:** בנייה, QA, TestFlight (5, 15, 16), אימות 6 — לפי [`appstore/QA_CHECKLIST`](appstore/QA_CHECKLIST.md).
- ☁️ **App Store Connect:** App Privacy labels, Review Notes, Medical Device, Age Rating, DSA (9, 11, 12, 13, 14) — תוכן מוכן.
- 🌐 **אתר/משפטי:** Privacy Policy + Medical Device (8, 12) — תוכן מוכן.

## הבהרת נתונים (כיול)
אין צורך להמתין 7 ימים: מנוע הכיול (`analysis/`) קורא את **כל ההיסטוריה** בייצוא Apple Health ומכייל
רטרואקטיבית על כל ה-HRV שכבר נצבר ב-Health.
