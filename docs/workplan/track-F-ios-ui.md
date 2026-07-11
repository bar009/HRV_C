# Track F — UI ל-iOS (SwiftUI)

**מיקום ב-spine:** S5 · [← חזרה לתזרים הראשי](README.md)
**פלטפורמה:** Mac · **סטטוס:** ✅ קוד נכתב (Mac-only)

## מטרה
לחשוף את מצב הניטור, ה-baseline, המגמה, וההתראות — כולל מסך הרשאות מקדים שמעלה את שיעור
האישור ל-HealthKit.

## תלויות
- **חוסם ב:** [Track C](track-C-persistence.md) (`@Query`), [Track B](track-B-healthkit.md) (`MonitoringCoordinator`).

## קלט
- Deep Dive 2.2.1 (pre-permission), הדגמה ויזואלית: `sim/scenario_A.png` (גרף ה-baseline)

## משימות
- [x] `OnboardingView` — הסבר מקדים + wellness disclaimer
- [x] `RootView` (טאבים) + `StatusView` (מצב/baseline)
- [x] `BaselineChartView` — SwiftData `@Query` + Charts (מקביל ל-`scenario_A.png`)
- [x] `AlertHistoryView` — רשימת התראות
- [ ] הצגת פס "טווח נורמלי" (lowerBound..upperBound) על הגרף
- [ ] RTL/עברית מלא + נגישות

## Windows-עכשיו / Mac-אחר-כך
נכתב עכשיו מול SwiftUI/Charts/SwiftData → קומפילציה ותצוגה על Mac.

## Definition of Done
- המשתמש רואה מצב, baseline, מגמה, והיסטוריית התראות; onboarding מופיע פעם אחת.

## אימות
- הרצה ב-Xcode Preview + על מכשיר; השוואת הגרף להתנהגות הסימולציה.
