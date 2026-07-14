# Launch Readiness Checklist — HRV-C

רשימת-סיום לפני העלאה ל-App Store. כל פריט ממופה ל**סטטוס** ול**בעלים** (מי/איפה סוגרים אותו):
🟩 קוד (עשוי/עושים כאן) · 🍎 Mac/Xcode · ☁️ App Store Connect · 🌐 אתר/משפטי.

> **תלות-על:** ההעלאה עצמה דורשת **Mac + Xcode + חשבון Apple Developer ($99/שנה)**. ה-Mac מגיע בעוד ~חודשיים.
> כל פריטי ה-☁️/🍎/🌐 ממתינים לזה; פריטי ה-🟩 אפשר לסגור עכשiv.

## הרשימה

| # | פריט | סטטוס | בעלים | מה נדרש / הערה |
|---|------|--------|--------|----------------|
| 1 | **HealthKit permissions מדויקות** | ✅ | 🟩 | סט הבקשה צומצם ל-**SDNN + heartRate** בלבד (heartbeat/RR הוסר עד ש-RRExtractor ינחת — Q-A), ומחרוזת `NSHealthShareUsageDescription` חודדה לתאום. אימות סופי מול Apple Review ב-🍎 |
| 2 | **מסך הסבר לפני בקשת HealthKit** | ✅ | 🟩 | Onboarding M2.1 (Value & Privacy) לפני M2.2 (Apple Health); גם מסך `setupRequired` מסביר לפני `requestHealthAccess()` |
| 3 | **ניסוח Wellness עקבי** | ✅ | 🟩 | guardrails נאכפים: "זהו כלי wellness, לא אבחון רפואי" (onboarding/setup/Settings); "זוהה שינוי מתמשך" ולא "לופ"; אין טענת רגש/אבחנה |
| 4 | **כתב ויתור רפואי** | 🟡 חלקי | 🟩 + ☁️ | קיים באפליקציה (Settings → "הצהרת Wellness", onboarding). צריך גם בתיאור ה-App Store |
| 5 | **שמירה מקומית בלבד** | ✅ | 🟩 | SwiftData מקומי, בלי backend/ענן/analytics (AGENTS.md) |
| 6 | **חסימת גיבוי iCloud לנתונים רגישים** | ✅ קוד (אימות 🍎) | 🟩 | `PrivacyStore.makeContainer()`: `ModelConfiguration(cloudKitDatabase: .none)` + `isExcludedFromBackup` + `FileProtectionType.completeUnlessOpen` על ה-store וה-sidecars. אימות ההתנהגות בפועל ב-Mac |
| 7 | **מחיקת כל המידע מהאפליקציה** | ✅ | 🟩 | `coordinator.deleteAllData()` (מוחק את כל מודלי SwiftData, מאפס engine/detector, baseline, events, `didOnboard`) + מקטע "נתונים" ב-Settings עם דיאלוג אישור |
| 8 | **Privacy Policy (אתר + אפליקציה)** | ⬜ | 🌐 + 🟩 | לכתוב מדיניות פרטיות, לארח באתר, ולקשר מ-Settings |
| 9 | **App Privacy labels לפי התנהגות אמיתית** | ⬜ | ☁️ | לסמן: נתוני בריאות **נאספים אך לא מקושרים לזהות ולא למעקב**, נשארים על המכשיר |
| 10 | **Demo Mode לבודק** | ✅ | 🟩 | `DemoData.generate()` (מקביל ל-`sim/synthetic`) + `coordinator.loadDemoData()` דרך הצינור האמיתי; כפתור "טעינת נתוני הדגמה" ב-Settings → הבודק רואה Learning→Stable+Event בלי Apple Watch |
| 11 | **Review Notes מפורטים** | ⬜ | ☁️ | להסביר: דורש Apple Watch; איך להפעיל Demo Mode; מהות ה-wellness |
| 12 | **הצהרת Medical Device** | ⬜ | ☁️ + 🌐 | הצהרה מפורשת: **אינו מכשיר רפואי** (wellness), בתיאור וב-Review Notes |
| 13 | **Age Rating** | ⬜ | ☁️ | לקבוע ב-App Store Connect (סביר 4+/12+) |
| 14 | **DSA status (אירופה)** | ⬜ | ☁️ | סטטוס trader לפי ה-Digital Services Act ב-App Store Connect |
| 15 | **בדיקות TestFlight (iPhone + Apple Watch)** | ⬜ | 🍎 + ☁️ | דורש Mac + חשבון; התקנה ובדיקה על מכשירים אמיתיים |
| 16 | **אפס קריסות / מסכים ריקים / טקסט זמני** | 🟡 | 🍎 (QA) | ה-UI הראשי מלא; watchOS עדיין מינימלי (שלב 8 מוקפא); QA מלא על ה-Mac |

## מה נסגר בקוד (🟩, בלי Mac) — ✅ בוצע
פריטים **1, 6, 7, 10** מומשו: צמצום בקשת HealthKit + חידוד מחרוזת (#1), `PrivacyStore` ללא-CloudKit/לא-מגובה/מוגן (#6),
`deleteAllData()` + Settings (#7), ו-`DemoData`/`loadDemoData()` + Settings (#10). כל קוד ה-App הזה **Mac-only ולא מקומפל על
Windows** — נכתב מול ה-API המתועד; קומפילציה ו-QA ב-Xcode. אימות התנהגותי של #6 (גיבוי/הצפנה) דורש מכשיר 🍎.

## מה תלוי ב-Mac / חשבון / אתר
- 🍎 **Mac:** בנייה, QA, TestFlight (5, 15, 16), אימות 6.
- ☁️ **App Store Connect:** App Privacy labels, Review Notes, Medical Device, Age Rating, DSA (9, 11, 12, 13, 14).
- 🌐 **אתר/משפטי:** Privacy Policy + Medical Device (8, 12).

## הבהרת נתונים (כיול)
אין צורך להמתין 7 ימים: מנוע הכיול (`analysis/`) קורא את **כל ההיסטוריה** בייצוא Apple Health ומכייל
רטרואקטיבית על כל ה-HRV שכבר נצבר ב-Health.
