# מסמך תכנון ארכיטקטורה — הכרעות OP-4, OP-5, OP-6

**גרסה:** 0.2
**תלוי במסמך:** `HRV_App_Spec.md` · `HRV_Research_HeartMath.md`
**מטרה:** לתכנן ברזולוציה גבוהה את שלוש ההחלטות שקובעות את מבנה הקוד — מקור ה־HRV, לוגיקת ההתראה, והאחסון — כולל נוסחאות, צינורות עיבוד, וחתימות מחלקות.

> **שינויי גרסה 0.2 (עקב מחקר HeartMath):** מוסגר מחדש סעיף A.3.1 — תחום התדר מודר מהמסלול הפסיבי בלבד, ולא באופן גורף · Q-A עודכן (נוטה לשלילה) · נוספה שורת החלטה D-COH בטבלת הנקודות הפתוחות.

---

# חלק א' — OP-4: מקור נתוני ה־HRV

## A.1 שתי האופציות
1. **SDNN מוכן של אפל** — קריאת `heartRateVariabilitySDNN` ישירות. אפל כבר חישבה, ניקתה, ונתנה ערך יחיד ב־ms (על חלון של בערך דקה).
2. **חישוב עצמאי מ־RR** — שליפת `HKHeartbeatSeriesSample`, חילוץ מרווחי הפעימות (RR/IBI), ניקוי, וחישוב המדדים בעצמנו.

## A.2 בדיקת מציאות — מה זמין בפסיבי בפועל
זו הנקודה שמכריעה את הארכיטקטורה, וחייבים לאמת אותה על מכשיר אמיתי:

- **`heartRateVariabilitySDNN`** — נמדד פסיבית מספר פעמים ביום (מנוחה, שינה, Breathe). **זמין ואמין.**
- **`HKHeartbeatSeriesSample`** (סדרת פעימות beat-to-beat) — מיוצר בעיקר סביב **ECG ו־Workout Sessions**. במצב פסיבי טהור, זמינותו **לא מובטחת ולא רציפה**.

**מסקנה ארכיטקטונית:** אי אפשר לבנות מוצר פסיבי על חישוב RR עצמאי כמקור ראשי. לכן:

> **החלטה D-OP4: ארכיטקטורת Hybrid**
> - מקור **ראשי**: `heartRateVariabilitySDNN` של אפל.
> - מקור **משני (אופורטוניסטי)**: חישוב RMSSD/SDNN מ־RR — *רק כאשר* קיימת סדרת פעימות תקינה.
> - שכבת נרמול שמאחדת את שני המקורות לרצף אחד של "דגימות HRV".

**⚠️ פעולה נדרשת:** לפני מימוש — להריץ בדיקת שדה של 3–5 ימים על מכשיר אמיתי ולספור כמה `HKHeartbeatSeriesSample` מגיעים פסיבית. התוצאה קובעת אם שכבה A.6.1 בכלל שווה מאמץ.

## A.3 הנוסחאות המלאות (Time-Domain)

הגדרה: `RR[i]` = מרווח בין פעימה i לפעימה i+1, במילישניות. אחרי ניקוי מסמנים אותם `NN` (Normal-to-Normal).

**SDNN — סטיית תקן של המרווחים (משקף שונות כוללת):**
```
mean = (1/N) · Σ NN[i]
SDNN = sqrt( (1/(N-1)) · Σ (NN[i] - mean)² )
```

**RMSSD — שורש ממוצע ריבועי ההפרשים העוקבים (משקף פעילות פאראסימפתטית / קצר־טווח):**
```
diff[i] = NN[i+1] - NN[i]          // יש N-1 הפרשים
RMSSD   = sqrt( (1/(N-1)) · Σ diff[i]² )
```

**pNN50 — אחוז ההפרשים העוקבים הגדולים מ־50ms:**
```
NN50   = count( |NN[i+1] - NN[i]| > 50ms )
pNN50  = (NN50 / (N-1)) · 100
```

**SDSD — סטיית תקן של ההפרשים העוקבים:**
```
SDSD = std(diff)
```

### A.3.1 איזה מדד ראשי לבחור
- **RMSSD** = הבחירה הראשית שלנו. הוא היציב ביותר לחלונות קצרים, עמיד יותר לאי־יציבות (non-stationarity), ומשקף היטב שינויים מהירים — בדיוק המטרה ("שינוי קיצוני").
- **SDNN** = נשמר כמדד משני ולצורך עקביות עם הערך שאפל נותנת.
- **תדר (LF/HF/LF·HF⁻¹, Coherence)** = **מחוץ למסלול הפסיבי** (לא "מחוץ ל־v1" באופן גורף — ראה תיקון להלן). דורש tachogram בדגימה אחידה (למשל resampling ל־4Hz + FFT, או Lomb-Scargle לדגימה לא־אחידה) ולפחות ~2–5 דקות פעימות רצופות. לא ריאלי עם נתונים פסיביים דלילים.
  - **⚠️ תיקון לאור מחקר HeartMath (`HRV_Research_HeartMath.md`):** תחום התדר מודר **מהמסלול הפסיבי בלבד** — אבל הוא **הבסיס המלא של "מצב מדידה אקטיבי" (Coherence)** אם תתקבל החלטה D-COH. אין לפרש את השורה הזו כאילו לעולם לא ניגע בתחום התדר. במצב אקטיבי (סשן נשימה + זרם פעימות צפוף) תחום התדר הוא דווקא הליבה. מודול Coherence המלא מתוכנן להתווסף כאן כחלק א'־2 נפרד.

## A.4 צינור ניקוי ה־Artifacts (קריטי — מכאן מגיעות רוב התראות השווא)

סדר הפעולות על רצף RR גולמי:

**שלב 1 — סינון טווח פיזיולוגי:**
```
לזרוק כל RR מחוץ לתחום [300ms, 2000ms]   // ≈ 30–200 bpm
```

**שלב 2 — סינון אדפטיבי לפי הפרש עוקב (שיטת Malik, 20%):**
```
לכל פעימה: אם |RR[i] - RR_מאושר_קודם| / RR_מאושר_קודם > 0.20
            → לפסול כ־ectopic beat
```

**שלב 3 — החלטת מחיקה מול אינטרפולציה:**
- **מחיקה (deletion)** — פשוט, בטוח, מקטין N. ברירת המחדל שלנו.
- **אינטרפולציה (cubic spline)** — שומר N אך עלול להטות. רק לחריגים בודדים ומבודדים.

**שלב 4 — בקרת איכות מינימלית לחלון:**
```
אם (מספר NN תקינים < 30) או (אחוז הפעימות שנפסלו > 20%)
   → לסמן את החלון כ־LOW_QUALITY ולא לחשב ממנו HRV
```

> **עיקרון:** עדיף להחזיר "אין מדידה אמינה" מאשר להחזיר ערך רועש שיפעיל התראת שווא.

## A.5 שכבת הנרמול בין המקורות
כל דגימה, לא משנה ממקורה, מומרת ל־struct אחיד:
```swift
struct HRVSample {
    let timestamp: Date
    let value: Double            // ms
    let metric: HRVMetric        // .sdnnApple / .rmssdComputed / .sdnnComputed
    let quality: SampleQuality   // .high / .low
    let source: HRVSource        // .healthKitDirect / .beatSeries
    let sampleCount: Int?        // כמה NN השתתפו (רק בחישוב עצמאי)
}
```
כך ה־baseline והדיטקטור בשלב ב' עובדים מול טיפוס אחד ולא מתעניינים מאיפה הגיע הערך.

## A.6 מבנה הקוד (מודול Signal / HRV)

**A.6.1 `RRExtractor`** — אחראי רק על חילוץ RR מסדרת פעימות:
```swift
protocol RRExtracting {
    /// ממיר HKHeartbeatSeriesSample לרצף RR במילישניות
    func extractRR(from series: HKHeartbeatSeriesSample) async throws -> [Double]
}
```

**A.6.2 `ArtifactCorrector`** — צינור A.4:
```swift
struct ArtifactCorrector {
    var physiologicalRange: ClosedRange<Double> = 300...2000
    var maxSuccessiveDelta: Double = 0.20
    var minValidBeats: Int = 30
    var maxRejectRatio: Double = 0.20

    func clean(_ rr: [Double]) -> CleanResult
    // CleanResult { nn: [Double], rejected: Int, quality: SampleQuality }
}
```

**A.6.3 `HRVCalculator`** — הנוסחאות מ־A.3, פונקציות טהורות (pure) → קלות לבדיקה ב־unit tests:
```swift
enum HRVCalculator {
    static func rmssd(_ nn: [Double]) -> Double?
    static func sdnn(_ nn: [Double]) -> Double?
    static func pnn50(_ nn: [Double]) -> Double?
}
```

מימוש מפתח (RMSSD ו־SDNN):
```swift
static func rmssd(_ nn: [Double]) -> Double? {
    guard nn.count >= 2 else { return nil }
    let diffs = zip(nn.dropFirst(), nn).map { $0 - $1 }   // NN[i+1]-NN[i]
    let meanSq = diffs.map { $0 * $0 }.reduce(0, +) / Double(diffs.count)
    return (meanSq).squareRoot()
}

static func sdnn(_ nn: [Double]) -> Double? {
    guard nn.count >= 2 else { return nil }
    let mean = nn.reduce(0, +) / Double(nn.count)
    let variance = nn.map { ($0 - mean) * ($0 - mean) }
                      .reduce(0, +) / Double(nn.count - 1)
    return variance.squareRoot()
}
```

**הערה על עקביות:** לא נצליח לשחזר בדיוק את SDNN הפנימי של אפל (חלון וניקוי לא מתועדים). זו סיבה נוספת להעדיף את הערך של אפל כמקור ראשי ולא לערבב באותו חישוב את שני המקורות.

---

# חלק ב' — OP-5: לוגיקת ה־Baseline והסף

## B.1 למה סף אחוזי נאיבי נכשל
"התראה בירידה מעל 30%" נשמע פשוט, אבל:
1. **שונות בין־אישית עצומה** — HRV נורמלי נע בין ~20ms ל~200ms בין אנשים. 30% אצל אחד זה רעש, אצל אחר זה אירוע.
2. **התפלגות מוטה־ימינה** — HRV אינו נורמלי; ממוצע וסטיית תקן מטעים.
3. **חריגים** — דגימה רועשת בודדת מזיזה ממוצע וסטיית תקן, ומרעילה את הסף עצמו.

## B.2 טרנספורמציית לוג — הבסיס של הכל
HRV (במיוחד RMSSD) מתפלג בקירוב **log-normal**. לכן כל החישובים נעשים על:
```
x = ln(RMSSD)
```
על הסקאלה הלוגריתמית ההתפלגות קרובה לנורמלית, וההשוואות הופכות תקפות. זו הנורמה במוצרי HRV רציניים.

## B.3 שלוש שיטות הסף

**שיטה 1 — אחוזי (baseline):** פשוט, אינטואיטיבי, אך מתעלם משונות אישית. *לא מומלץ כמנגנון ראשי.*
```
alert אם  (baseline_median - x_today) / baseline_median > P
```

**שיטה 2 — z-score קלאסי:** מתחשב בשונות, אך רגיש להתפלגות ולחריגים.
```
z = (x_today - μ) / σ           // μ,σ = ממוצע וסטיית תקן של ה-baseline
alert אם z < -k
```

**שיטה 3 — z-score עמיד (median + MAD) ← הבחירה שלנו:** עמיד לחריגים ולהטיה.
```
MAD = median( |x[i] - median(x)| )
robust_z = (x_today - median) / (1.4826 · MAD)
alert אם robust_z < -k
```
הקבוע `1.4826` הופך את ה־MAD לאומד עקבי של סטיית התקן עבור התפלגות נורמלית.

## B.4 בניית ה־Baseline המתגלגל
- **חלון baseline:** N ימים אחרונים (מומלץ להתחיל מ־60 יום; מינימום 7 ל־baseline ראשוני).
- **עדכון מתגלגל:** ה־baseline מחושב מחדש כל יום מהחלון הנע — הגוף משתנה וה־baseline נע איתו.
- **"טווח נורמלי" אישי:**
```
lower_bound = baseline_median - k · (1.4826 · MAD)
upper_bound = baseline_median + k · (1.4826 · MAD)
```
כאשר `k` הוא פרמטר הרגישות (נקודת כיול מרכזית, ראה B.8).

## B.5 Stratification לפי הקשר
דגימות HRV אינן ברות־השוואה אם נלקחו בהקשרים שונים. לפני כניסה ל־baseline, כל דגימה מתויגת:
- **שינה מול ערות** (הצלבה עם `sleepAnalysis`).
- **מנוחה מול פעילות** (הצלבה עם דופק גבוה / workout סמוך → פסילה).
- **שעה ביום** (אופציונלי מתקדם — baseline נפרד לבוקר/ערב).

**כלל־על:** אם דגימת HRV נלקחה בסמוך למאמץ (דופק גבוה), **לא מכניסים אותה ל־baseline ולא מתריעים עליה** — ירידת HRV במאמץ היא נורמלית לחלוטין.

## B.6 מכונת המצבים של ההתראה
```
             ┌──────────┐
             │ Learning │  (אין baseline מספיק — רק אוסף, לא מתריע)
             └────┬─────┘
                  │ נאספו ≥ minBaselineDays
                  ▼
             ┌──────────┐   robust_z < -k        ┌──────────┐
             │  Normal  │ ─────────────────────► │ Watching │
             └──────────┘                        └────┬─────┘
                  ▲                                    │
                  │ חזר לטווח                          │ החריגה נמשכה
                  │                                    │ ≥ persistenceWindow
                  │                                    ▼
             ┌──────────┐    אחרי cooldownPeriod  ┌──────────┐
             │ Cooldown │ ◄───────────────────── │  Alert   │ (שולח התראה)
             └──────────┘                        └──────────┘
```

הגנות מפני התראות שווא מובנות במכונה:
- **`persistenceWindow`** — החריגה חייבת להימשך על פני כמה דגימות/זמן לפני `Alert` (לא דגימה בודדת).
- **`cooldownPeriod`** — אחרי התראה, אין התראה נוספת עד שעובר פרק זמן מוגדר.
- **מצב `Learning`** — אין התראות עד שיש baseline אמין.

## B.7 פרמטרים לכיול (הלב של המוצר — ערכי התחלה, לא סופיים)
| פרמטר | תיאור | ערך התחלתי מוצע |
|--------|--------|------------------|
| `metric` | מדד ראשי | RMSSD (על ln) |
| `baselineWindowDays` | חלון ה־baseline | 60 |
| `minBaselineDays` | מינימום ליציאה מ־Learning | 7 |
| `k` | רגישות (מספר MAD-units) | 1.5–2.0 |
| `persistenceWindow` | כמה זמן החריגה נמשכת | 2–3 דגימות רצופות |
| `cooldownPeriod` | מרווח מינימלי בין התראות | 6–12 שעות |
| `direction` | כיוון ההתראה | ירידה בלבד (v1) |

## B.8 מבנה הקוד (מודול Baseline / Detection)

**B.8.1 `BaselineEngine`** — בונה ומתחזק את ה־baseline:
```swift
protocol BaselineEngining {
    func currentBaseline(asOf date: Date) -> Baseline?
    func ingest(_ sample: HRVSample)      // מוסיף לחלון הנע
}

struct Baseline {
    let median: Double            // על סקאלת ln
    let mad: Double
    let sampleCount: Int
    var lowerBound: Double { median - k * 1.4826 * mad }
}
```

**B.8.2 `AnomalyDetector`** — מיישם את השיטה מ־B.3.3 ואת מכונת המצבים:
```swift
final class AnomalyDetector {
    private(set) var state: DetectorState = .learning
    private let config: DetectorConfig

    /// מוזן בדגימה חדשה, מחזיר אירוע אם צריך להתריע
    func evaluate(_ sample: HRVSample,
                  baseline: Baseline,
                  context: SampleContext) -> AlertEvent?
}
```

מימוש מפתח — robust z + החלטה:
```swift
func robustZ(_ x: Double, baseline: Baseline) -> Double {
    (x - baseline.median) / (1.4826 * baseline.mad)
}

// בתוך evaluate:
let x = log(sample.value)                      // ln(RMSSD)
guard context.isRestful, sample.quality == .high else { return nil }
let z = robustZ(x, baseline: baseline)
let isAnomaly = z < -config.k
// ... הזנה למכונת המצבים (persistence + cooldown)
```

---

# חלק ג' — OP-6: אחסון

## C.1 תובנת המפתח — HealthKit *הוא* כבר מסד הנתונים
אין צורך לשכפל דגימות גולמיות. HealthKit שומר אותן ומאפשר שאילתות טווח. לכן **לא נשמור דגימות דופק/HRV גולמיות** אלא נשלוף אותן מחדש בעת הצורך. זה מקטין נפח, מקטין את משטח הפרטיות, ומצמצם באגים של סנכרון.

## C.2 מה כן נשמר מקומית (מה ש־HealthKit לא מחזיק)
1. **HealthKit anchors** — כדי לא למשוך דגימות כפולות (‏`HKQueryAnchor` מסורייל).
2. **דגימות HRV מעובדות** — התוצר של שלב א' (ln(RMSSD), quality, context). קטן, ומשמש ל־baseline בלי לחשב מחדש בכל פעם.
3. **מצב ה־baseline** — median, MAD, חלון נוכחי.
4. **היסטוריית התראות** — מתי, ערך, סיבה (ל־UI ולמניעת כפילויות/cooldown).
5. **הגדרות משתמש וכיול** — פרמטרי B.7.

## C.3 הערכת נפח נתונים (מדוע ביצועים אינם הגורם המכריע)
| נתון | קצב פסיבי | לשנה |
|------|-----------|------|
| דגימות HRV מעובדות | ~5–20 ליום | ~7,000 |
| התראות | בודדות בשבוע | עשרות |

הנפח זעום. **ביצועים לא מכריעים** את הבחירה — הגורמים האמיתיים הם גרסת OS מינימלית, מהירות פיתוח, וקלות migration.

## C.4 מטריצת השוואה
| קריטריון | Core Data | SwiftData | SQLite (GRDB) |
|----------|-----------|-----------|----------------|
| גרסת OS מינ' | iOS 13+ | **iOS 17+ בלבד** | iOS 12+ |
| Boilerplate | גבוה | נמוך | בינוני |
| נוחות Swift מודרנית | בינונית | **גבוהה** | גבוהה (GRDB) |
| שליטה בשאילתות זמן | טובה | טובה | **מצוינת** |
| בשלות/יציבות | **גבוהה מאוד** | חדש יחסית | גבוהה מאוד |
| הצפנה (File Protection) | כן | כן | כן |
| migrations | ידני־למחצה | מובנה | ידני (מפורש) |

## C.5 ההמלצה
> **החלטה D-OP6:**
> - אם אפשר לדרוש **iOS 17+ / watchOS 10+** → **SwiftData** (הכי נקי, פחות קוד, Swift-native).
> - אם צריך תמיכה רחבה יותר או שליטה מקסימלית כ־time-series → **GRDB/SQLite**.
> - **Core Data** רק אם הצוות כבר מנוסה בו.

בשני המקרים הנתונים קטנים, אז הבחירה היא בעיקר שאלת גרסת OS + טעם הצוות. **נקודת החלטה שנשארת פתוחה: מהי גרסת ה־iOS המינימלית הנתמכת?** — היא זו שסוגרת את OP-6 סופית.

## C.6 סכמת נתונים לוגית (agnostic למימוש)
```
ProcessedHRVSample
  - id: UUID
  - timestamp: Date
  - lnRmssd: Double
  - rawValueMs: Double
  - metric: String        // sdnnApple / rmssdComputed
  - quality: String       // high / low
  - context: String       // rest / sleep / active
  - source: String

BaselineState
  - id: UUID
  - computedAt: Date
  - median: Double
  - mad: Double
  - sampleCount: Int
  - windowStart: Date

AlertRecord
  - id: UUID
  - firedAt: Date
  - robustZ: Double
  - rawValueMs: Double
  - reason: String

SyncAnchor
  - dataType: String      // heartRate / hrvSDNN / heartbeatSeries
  - anchorData: Data      // HKQueryAnchor מסורייל
```

## C.7 מבנה הקוד (מודול Persistence)
Repository אחד שמסתיר את מנוע האחסון — כך שאם מחליפים SwiftData ב־GRDB בעתיד, שאר הקוד לא משתנה:
```swift
protocol HRVRepository {
    func save(_ sample: ProcessedHRVSample) throws
    func samples(in range: DateInterval) throws -> [ProcessedHRVSample]
    func latestBaseline() throws -> BaselineState?
    func upsert(_ baseline: BaselineState) throws
    func record(_ alert: AlertRecord) throws
    func recentAlerts(within: TimeInterval) throws -> [AlertRecord]
    func anchor(for type: String) throws -> HKQueryAnchor?
    func saveAnchor(_ anchor: HKQueryAnchor, for type: String) throws
}
```
כל השאר במערכת מכיר רק את ה־protocol הזה, לא את SwiftData/GRDB.

---

# חלק ד' — הארכיטקטורה הכוללת

## D.1 שכבות ואחריות
```
┌─────────────────────────────────────────────────────────────┐
│ 1. Data Access — HealthKitService                            │
│    ObserverQuery, background delivery, anchors, שליפת דגימות  │
├─────────────────────────────────────────────────────────────┤
│ 2. Signal — RRExtractor, ArtifactCorrector, HRVCalculator    │
│    (חלק א')  →  מייצר HRVSample מנוקה                          │
├─────────────────────────────────────────────────────────────┤
│ 3. Detection — BaselineEngine, AnomalyDetector               │
│    (חלק ב')  →  robust z, מכונת מצבים, מחליט אם להתריע         │
├─────────────────────────────────────────────────────────────┤
│ 4. Persistence — HRVRepository                               │
│    (חלק ג')  →  baseline, anchors, alerts                     │
├─────────────────────────────────────────────────────────────┤
│ 5. Notification — AlertService (Local Notifications)         │
├─────────────────────────────────────────────────────────────┤
│ Orchestration — MonitoringCoordinator                        │
│    מחבר הכל, מריץ את הזרימה מקצה לקצה                          │
└─────────────────────────────────────────────────────────────┘
```

## D.2 זרימת נתונים מקצה לקצה
```
Apple Watch (פסיבי)
   │  דוגם דופק + HRV
   ▼
HealthKit store
   │  ObserverQuery מעיר את האפליקציה ברקע
   ▼
HealthKitService  ── AnchoredObjectQuery → דגימות חדשות בלבד
   │
   ├── יש heartbeat series? → RRExtractor → ArtifactCorrector → HRVCalculator (RMSSD)
   └── רק SDNN?             → נרמול ישיר
   │
   ▼
HRVSample (מנוקה, מתויג הקשר)
   │
   ├──► Repository.save (persistence)
   │
   ▼
BaselineEngine.ingest  →  מעדכן median/MAD מהחלון הנע
   │
   ▼
AnomalyDetector.evaluate  →  robust_z + מכונת מצבים
   │  אם Alert:
   ▼
AlertService  →  Local Notification
```

## D.3 עץ מודולים מוצע
```
App/
├── DataAccess/
│   └── HealthKitService.swift
├── Signal/
│   ├── RRExtractor.swift
│   ├── ArtifactCorrector.swift
│   ├── HRVCalculator.swift
│   └── Models/ (HRVSample, SampleQuality, HRVMetric)
├── Detection/
│   ├── BaselineEngine.swift
│   ├── AnomalyDetector.swift
│   └── Models/ (Baseline, DetectorState, AlertEvent, DetectorConfig)
├── Persistence/
│   ├── HRVRepository.swift        (protocol)
│   └── SwiftDataRepository.swift  (מימוש — או GRDB)
├── Notification/
│   └── AlertService.swift
└── Orchestration/
    └── MonitoringCoordinator.swift
```

## D.4 סדר מימוש מומלץ
1. **HealthKitService + Repository (anchors בלבד)** — לוודא שדגימות נכנסות ברקע ולא כפולות. בלי זה שום דבר לא עובד.
2. **Signal (חלק א')** — פונקציות טהורות, קלות ל־unit tests. לבדוק RMSSD/SDNN מול ערכים ידועים.
3. **BaselineEngine** — לצבור baseline על נתונים אמיתיים (דורש כמה ימי ריצה).
4. **AnomalyDetector** — רק אחרי שיש baseline לכייל מולו.
5. **AlertService** — אחרון, כי הוא הכי פשוט וכי צריך שהכל לפניו יעבוד כדי לבדוק אותו נכון.

## D.5 עקרונות רוחב (Cross-cutting)
- **פונקציות טהורות בשכבת Signal ו־Detection** → כל הנוסחאות נבדקות ב־unit tests בלי HealthKit ובלי מכשיר.
- **Protocols בין שכבות** → אפשר להחליף מימוש (למשל SwiftData↔GRDB) בלי לגעת בלוגיקה.
- **כל החלטה מתקבלת על המכשיר** → תואם להחלטת האחסון המקומי (D4) ולפרטיות.
- **"אין מדידה" הוא ערך לגיטימי** → כל השכבות יודעות להחזיר nil/LOW_QUALITY במקום לנחש.

---

# נקודות שנותרו להכרעה אחרי מסמך זה
| # | נקודה | סוגר את |
|---|--------|----------|
| Q-A | תוצאת בדיקת השדה: כמה heartbeat series מגיעים פסיבית? **(נוטה לשלילה — מחקר HeartMath מאשש שנתוני פעימה צפופים מגיעים בעיקר מהקשר אקטיבי; לאמת בשדה)** | האם שכבת RRExtractor שווה מאמץ (A.2) |
| Q-B | ערכי הכיול הסופיים ל־k, persistence, cooldown | לב לוגיקת ההתראה (B.7) |
| Q-C | גרסת iOS מינימלית נתמכת | בחירת מנוע האחסון (C.5) |
| **D-COH** | **להוסיף מצב מדידה אקטיבי (Coherence)?** — ראה `HRV_App_Spec.md` §0.4 | **האם נבנה מודול תחום־תדר שלם (חלק א'־2) בנוסף למסלול הפסיבי** |
