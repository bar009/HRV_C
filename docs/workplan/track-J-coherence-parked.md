# Track J — Coherence / מצב אקטיבי (D-COH) 🟡 בעבודה (מאחורי דגל, מחוץ ל-v1)

**מיקום ב-spine:** אחרי S8 · [← חזרה לתזרים הראשי](README.md)
**פלטפורמה:** Mac + Watch · **סטטוס:** 🟡 מומש מאחורי `FeatureFlags.coherenceEnabled` (כבוי כברירת מחדל)

## סטטוס נוכחי
נפתח מוקדם לפי החלטת המשתמש, אך **מחוץ להגשת ה-App Store הראשונה**: v1 = המסלול הפסיבי המאומת;
קוהרנטיות נכנסת ב-v1.1 אחרי אימות על שעון אמיתי. הכול מאחורי דגל כבוי, ולכן סט ההרשאות
והמסמכים של v1 לא נגעו.

**מומש ואומת (בלי מכשיר):** `HRVCore/Coherence` — `FFT` (radix-2 pure-Swift) + `CoherenceEngine`
(הצינור המלא של §2): resample → Hanning → FFT → שיא 0.04–0.26Hz → יחס → ציון 0–100 + band.
מאומת מול אותות סינתטיים (סינוס 0.1Hz → גבוה, רעש → נמוך, זיהוי שיא, FFT מול DFT). כולל
`CoherenceSessionController` + `CoherenceSession` (SwiftData מקומי) + UI טלפון (`PracticeScreen`,
`CoherenceRing`) — מאומת בסימולטור light+dark עם מקור סינתטי.

**מחוץ ליכולת המכשיר כאן:** `WorkoutCoherenceController` (HKWorkoutSession → HR לטלפון) +
`WatchWorkoutHeartRateSource` — נכתבו, מתקמפלים, מאומתים ביום המכשיר (גם עונה על Q-A).

**יושרה:** נלקחה רק המתמטיקה (Coherence Ratio); ספי הציון 0–100 והבנדים הם **שלנו** (ספי HeartMath
קנייניים). כיול על נתונים אמיתיים = Q-B.

## למה היה מוקפא (רקע)
החלטת המשתמש הייתה לסיים קודם את המסלול הפסיבי; פורק כשהמשתמש בחר לפתוח את J בזמן ההמתנה לחשבון.

## מה זה יהיה (כשנחליט לפתוח)
פרדיגמה שנייה שלמה — מדידה אקטיבית מבוססת-**תבנית** (Coherence), להבדיל מהמסלול הפסיבי
מבוסס-**כמות** (RMSSD). ראה [`../HRV_Research_HeartMath.md`](../HRV_Research_HeartMath.md).

## היקף עתידי (לא לביצוע עכשיו)
- מודול `HRVCore/Coherence`: צינור תחום-תדר — resampling ל-tachogram אחיד → FFT → איתור שיא
  ב-0.04–0.26 Hz → `Coherence Ratio = PeakPower / (TotalPower − PeakPower)`.
  (חלון 64ש', עדכון כל 5ש', עוגן ~0.1 Hz.)
- `HKWorkoutSession` על השעון לזרם פעימות צפוף ([Track E](track-E-watchos.md)).
- UX: סשן נשימה מודרך + לולאת biofeedback.
- גם פותר את Q-A (בסשן אקטיבי יש זרם פעימות צפוף).

## תלות
- נפתח רק אחרי [Track I](track-I-appstore-regulatory.md) (המסלול הפסיבי שוחרר).

## הערת יושרה
לקחת רק את הכלים המתמטיים של HeartMath (Coherence Ratio, מתועד ושפיט), לא את המסגרת
המטאפיזית ("global coherence" וכו').
