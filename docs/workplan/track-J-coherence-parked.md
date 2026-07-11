# Track J — Coherence / מצב אקטיבי (D-COH) 🔒 מוקפא

**מיקום ב-spine:** אחרי S8 · [← חזרה לתזרים הראשי](README.md)
**פלטפורמה:** Mac + Watch · **סטטוס:** 🔒 מוקפא במכוון — לא נכתב קוד

## למה מוקפא
החלטת המשתמש: מסיימים קודם את המסלול הפסיבי במלואו, ורק אז שוקלים להוסיף את מצב המדידה
האקטיבי. זהו placeholder כדי שהמסלול הראשי יישאר שלם וקריא.

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
