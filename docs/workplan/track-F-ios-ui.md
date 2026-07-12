# Track F — UI ל-iOS (SwiftUI)

**מיקום ב-spine:** S5 · [← חזרה לתזרים הראשי](README.md)
**פלטפורמה:** Mac · **סטטוס:** ✅ קוד נכתב + מיושר ל-Figma design system (Mac-only)

## מטרה
לחשוף את מצב הניטור, ה-baseline, המגמה, וההתראות — כולל מסך הרשאות מקדים שמעלה את שיעור
האישור ל-HealthKit.

## תלויות
- **חוסם ב:** [Track C](track-C-persistence.md) (`@Query`), [Track B](track-B-healthkit.md) (`MonitoringCoordinator`).

## קלט
- **Figma:** `HRV-C — UX Wireframes v0.1` (file `hlCzE7OlX9yaZa7s5UJyhL`) — טוקנים + מוטיב, ראה [`../design/cover-v0.1.png`](../design/cover-v0.1.png)
- Deep Dive 2.2.1 (pre-permission), הדגמה ויזואלית: `sim/scenario_A.png` (גרף ה-baseline)

## משימות
- [x] `DesignSystem.swift` — טוקנים מ-Figma (palette טורקיז, SF Pro, chart band/line) + `BaselineMotif`
- [x] `OnboardingView` — hero motif + wellness disclaimer, בסגנון השער
- [x] `RootView` (טאבים) + `StatusView` (כרטיסים: מצב/baseline/מגמה)
- [x] `BaselineChartView` — פס "טווח נורמלי" (band) + קו חציון (line) + נקודות; SwiftData `@Query` + Charts
- [x] `AlertHistoryView` — כרטיסי התראות
- [x] RTL-first (`layoutDirection = .rightToLeft`) + אקצנט מערכתי
- [ ] Dynamic Type + נגישות מלאה
- [ ] יישור למסכי wireframe ספציפיים כשיתווספו ל-Figma (כרגע קיים רק דף השער)

## Windows-עכשיו / Mac-אחר-כך
נכתב עכשיו מול SwiftUI/Charts/SwiftData → קומפילציה ותצוגה על Mac.

## Definition of Done
- המשתמש רואה מצב, baseline, מגמה, והיסטוריית התראות; onboarding מופיע פעם אחת.

## אימות
- הרצה ב-Xcode Preview + על מכשיר; השוואת הגרף להתנהגות הסימולציה.
