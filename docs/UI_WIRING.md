# UI Wiring — כל מסך → ה-backend

מסמך-האב לחיווט: איך **כל מסך** ב-Figma מתחבר לתהליכי ה-compute וה-נתונים. זהו מקור-האמת לשלבים 3–8
(מימוש המסכים). כל מסך חדש חייב להתאים לשורה כאן. משלים את [`PRODUCT_STATE_MODEL.md`](PRODUCT_STATE_MODEL.md)
(מצבים+copy) ו-[`method-mapping.md`](method-mapping.md) (שיטה→פיצ'רים).

## התהליכים (backend)

| # | תהליך | מה הוא עושה | קוד |
|---|-------|-------------|-----|
| **P1** | **צינור הניטור** | HealthKit (SDNN, background delivery, anchors) → Signal (`ArtifactCorrector`+`HRVCalculator`) → Detection (`BaselineEngine`+`AnomalyDetector`) → **`PresentationMapper`** → `coordinator.presentation` | `HealthKitService`, `MonitoringCoordinator`, `HRVCore` |
| **P2** | **אחסון (SwiftData)** | דגימות מעובדות, baseline, **`EventRecord`** (היסטוריה), **`GuidedResponse`** (M3), anchors | `SwiftDataRepository`, `GuidedModels` |
| **P3** | **התראות** | `AnomalyDetector` יורה Alert → `AlertService` (Local Notification, ניסוח wellness) → tap → Attention → Guided Moment | `AlertService` |
| **P4** | **הרשאות / setup** | בקשת HealthKit + Notifications (נפרד, אחרי הסבר ערך); קובע `hasCompletedSetup` | `HealthKitService`, `AlertService`, coordinator |
| **P5** | **התקדמות למידה** | `BaselineEngine.distinctDays()` → יום N מתוך `minBaselineDays` | `BaselineEngine` |
| **P6** | **אירועים** | כל Alert מאומת → `EventRecord` (firedAt, משך, isNew) → מסך אירועים; "לצפייה במגמה" → Trends | repository + `MonitoringCoordinator` |

## זרימת הנתונים
```
Apple Watch ─(HealthKit SDNN)→ HealthKitService ─→ ArtifactCorrector/HRVCalculator
   → BaselineEngine (median+MAD על ln) → AnomalyDetector (robust-z, 5 מצבים)
   → PresentationMapper → coordinator.presentation (5 מצבים גלויים)  →  מסכי Status
   AnomalyDetector.Alert → EventRecord (P6) + AlertService notification (P3) → Attention → Guided Moment (P2)
```

## מצב → מסך (מ-`PresentationMapper`)
`setupRequired→Setup/Welcome · learning→Learning · stable→Stable(היום) · attention→Attention · unavailable→Unavailable`.
Watching/Cooldown מוסתרים כ-stable.

## מה ה-`MonitoringCoordinator` חושף ל-UI (ה-API שהמסכים נקשרים אליו)
- `presentation: HRVPresentationState` — המצב הגלוי (מ-P1).
- `baseline: Baseline?` — median/lowerBound/upperBound לגרף ולכרטיס.
- `recentSamples: [ProcessedHRVSample]` — 30 יום, לגרף (P2).
- `events: [EventRecord]` — היסטוריה (P6).
- `learningDay / learningTotalDays` — להתקדמות (P5).
- `isHealthAuthorized`, `hasCompletedSetup` — ל-setup/Settings (P4).
- פעולות: `start()`, `requestHealthAccess()`, `requestNotifications()`, `saveGuidedResponse(_:)`, `markEventSeen(_:)`.

## טבלת מסך → backend

### Status / היום (3 טאבים; Settings בנפרד)
| מסך | מוצג כאשר | מידע-נכנס | פעולות → תהליך | ניווט |
|-----|-----------|-----------|-----------------|-------|
| **Welcome** | הפעלה ראשונה (`!didOnboard`) | סטטי + הבטחת מוצר | "התחלה" → Onboarding | → M2.1 |
| **setupRequired** | `presentation==.setupRequired` | סטטוס הרשאה (P4) | "המשך להגדרה" → `requestHealthAccess()` (P4) | דגימה ראשונה → learning |
| **Permission-Skipped** | דילוג ב-M2 | — (copy "אין חיבור פעיל") | "לחבר" → P4 · "להמשיך ללא חיבור" | Status מוגבל |
| **Learning** | `.learning(day,total)` | `learningDay/Total` (P5), "אנחנו אוספים…" | — (ללא התראות בתקופה) | אוטו→stable כשה-baseline מוכן |
| **Stable / היום** | `.stable` | `baseline.median/lowerBound`, `lastUpdated` (P1); גרף מ-`recentSamples` (P2) | ניווט טאבים; גלגל→Settings | Trends/Events |
| **Attention** | `.attention` (Alert מאומת בלבד) | `EventRecord` אחרון (P6); copy "זוהה שינוי מתמשך" | **"לבדוק מה קורה עכשיו" → Guided Moment** (P3/M3) | → M3.1 |
| **Unavailable** | `.unavailable` | `lastValidSample`, reason (P1) | "בדיקת חיבור והרשאות" → Settings/P4 | Settings |

### Trends / מגמות · Events / אירועים · Settings
| מסך | מידע-נכנס | פעולות → תהליך |
|-----|-----------|-----------------|
| **Trends** | 30 יום `recentSamples` + פס baseline (P2); כרטיס עזרה (עובדתי) | — |
| **Events** | `events: [EventRecord]` (P6): "היום · שינוי מתמשך · חדש", "3 ביולי · נמשך 4ש'" | שורה "לצפייה במגמה" → Trends; פתיחה → `markEventSeen` |
| **Settings** (נפרד) | סטטוס P4 + טקסטים | HealthKit/Notifications → P4; פרטיות/אודות/Wellness (סטטי) |

### Onboarding (M2)
| שלב | מידע | פעולות → תהליך |
|-----|------|-----------------|
| M2.1 Value & Privacy | Step 1/4, הסבר ערך + local-first | "המשך" → M2.2 |
| M2.2 Apple Health | Step 2/4, נימוק גישה | "המשך ל-HealthKit" → **`requestHealthAccess()`** (P4) |
| M2.3 Notifications | Step 3/4, נימוק | "אפשר התראות" → **`requestNotifications()`** (P4) |
| M2.4 Learning Begins | Step 4/4, Learning Progress יום 1 | "סיום" → Status(learning) |

### Guided Moment (M3) — מופעל מ-Attention / notification tap
| שלב | מידע | פעולה → תהליך |
|-----|------|----------------|
| M3.1 Alert Detail | ה-`EventRecord` (עובדתי, ללא פרשנות) | "להתחיל" / Skip |
| M3.2 Guided Intro | הסבר קצר | Continue |
| M3.3 Body / M3.4 Mind / M3.5 Context | שאלה אחת למסך, שדה תשובה **של המשתמש** | תשובה → נשמר ל-`GuidedResponse` (P2, נפרד מ-detector) |
| M3.6 Support Choice | 3 פעולות תמיכה (נשימה/תנועה/דחייה) | בחירה → `GuidedResponse` |
| M3.7 If-Then Plan | תוכנית "אם-אז" של המשתמש | שמירה |
| M3.8 Relevance Feedback | Timely / Not-Relevant / Unsure | → `GuidedResponse.relevance` → מדד הצלחה |
> כללי M3: שאלה אחת למסך · 20–60ש' · Skip/Not-Now תמיד · האפליקציה **לא ממלאת** את הפרשנות · context נשמר בנפרד מ-detector-truth.

### Watch (5 מצבים)
| מסך | מידע | פעולה |
|-----|------|-------|
| Learning / Normal / No-Data / Change / Sync-Issue | מצב משוקף מהטלפון דרך **WatchConnectivity** (`presentation`) | "פתח באייפון" (לשינוי/סנכרון) |

## Guardrails (חלים על כל שורה)
"זוהה שינוי מתמשך" ולא "לופ"/רגש/אבחנה · Watching/Cooldown מוסתרים · צבע לא לבד · פעולה ראשית אחת למסך ·
local-first · תשובות המשתמש נשמרות בנפרד מאמת-הגלאי.
