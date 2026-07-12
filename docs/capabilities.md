# יכולות המדידה — מה כל מושג, והאם Apple Watch מכסה אותו

מסמך ייחוס: כל מדד/מושג שהמוצר נשען עליו, מה הוא, והאם Apple Watch / HealthKit נותן אותו
**נייטיב**, **בר-חישוב אצלנו** מחומר גלם, או **לא נמדד כלל**.

## הבהרה חשובה: Huawei מול Apple
ייצוא ה-"Apple Health" הראשון שנבדק הגיע משעון **Huawei** שסונכרן ל-Apple Health. Huawei
**לא כותב HRV (`HeartRateVariabilitySDNN`) ל-HealthKit**, ולכן היו בו 0 רשומות HRV (אך שפע דופק/שינה/SpO2).
**זה פער של מקור-הנתונים, לא כשל של הרעיון.** על **Apple Watch** אמיתי ה-HRV קיים (ראה למטה).

## מטריצת הכיסוי

| מושג | מה זה | Apple Watch / HealthKit |
|------|-------|--------------------------|
| **HRV** | שונות הזמן בין פעימות לב — אינדיקטור למצב האוטונומי (סטרס/מנוחה) | ✅ נמדד |
| **SDNN** | סטיית תקן של מרווחי הפעימה — מדד HRV "כמותי" יציב, ב-ms | ✅ **נייטיב**: `heartRateVariabilitySDNN` (יחיד ה-HRV שאפל חושפת ישירות). **המקור הפסיבי הראשי שלנו** (D-OP4). נוצר בעיקר מ-Mindfulness/Breathe ומשינה |
| **RR / IBI / Heartbeat Series** | הזמן המדויק בין כל שתי פעימות (beat-to-beat) — חומר הגלם לכל מדדי HRV | ✅ **נייטיב**: `HKHeartbeatSeriesSample` (query: `HKSeriesType.heartbeat()`). דיוק RR ~1.15% שגיאה במנוחה. מגיע בעיקר סביב ECG/Workout — כאן שאלת Q-A (כמה מגיע פסיבית) |
| **RMSSD** | שורש ממוצע ריבועי ההפרשים העוקבים — רגיש לפעילות פאראסימפתטית קצרת-טווח. **המדד הראשי שלנו** | ⚠️ **לא נייטיב, מחושב אצלנו** מ-RR. אפל לא חושפת RMSSD. אפליקציות צד-ג' (WatchMyHRV) עושות בדיוק זה. מיושם ב-`HRVCalculator` (A.6) |
| **pNN50 / SDSD** | מדדי HRV משניים בתחום הזמן | ⚠️ מחושבים אצלנו מ-RR, כמו RMSSD |
| **ECG** | אק"ג חד-ליד (30ש') — מקור לזרם פעימות צפוף ואמין | ✅ נייטיב: Apple Watch Series 4+ |
| **Coherence / Coherence Ratio (D-COH)** | מדד HeartMath בתחום התדר: יחס הספק סביב שיא LF (~0.1Hz) — "תבנית" ולא "כמות" | ❌ **לא נייטיב, מחושב אצלנו** מזרם RR צפוף בסשן אקטיבי (Workout Session). אפל נותנת חומר גלם (RR/ECG), לא את המדד. כרגע מוקפא (D-COH) |
| **דופק / דופק-מנוחה** | HR רגעי / דופק מנוחה יומי | ✅ נייטיב (`heartRate`, `restingHeartRate`) |
| **SpO2 / שינה / Mindfulness** | ריווי חמצן / שלבי שינה / סשן נשימה | ✅ נייטיב. Mindfulness/Breathe הוא **מה שמייצר את דגימות ה-SDNN** |
| **Baseline + זיהוי חריגה** | median+MAD על `ln`, robust-z, מכונת מצבים | 🔧 **שלנו** — לא של אפל. רץ מעל נתוני ה-HealthKit (`hrv_core`) |
| **קורטיזול / DHEA / קוהרנטיות רגשית** | פיזיולוגיה שהשיטה מסבירה | ❌ לא נמדד ע"י אף שעון — מוסק בעקיפין מ-HRV/דופק, לא נמדד ישירות |

## השורה התחתונה
כל מה שהנחנו **קיים על Apple Watch** — או **נייטיב** (SDNN, RR, ECG, דופק/שינה/SpO2), או
**מחושב על ידינו מ-RR** (RMSSD, pNN50, Coherence). היחידים ש"לא מוגשים מוכנים" הם RMSSD ו-Coherence,
ואותם תמיד תכננו לחשב בעצמנו (A.6, D-COH), ואפליקציות אחרות מוכיחות שזה עובד.

## שתי הסתייגויות מעשיות
1. **iPhone לבד לא מודד HRV** — צריך Apple Watch מזווג אליו (ה-HRV נרשם לטלפון שהשעון מזווג אליו).
2. **RR פסיבי דליל** (בעיקר סביב ECG/אימון) → RMSSD-מ-RR פסיבי מוגבל. **SDNN הוא המקור הפסיבי האמין**;
   זרם RR צפוף (ל-RMSSD/Coherence מדויקים) דורש את הסשן האקטיבי. תואם ל-Deep Dive A.2 ול-D-COH.

## מקורות
- [`heartRateVariabilitySDNN` — Apple Developer](https://developer.apple.com/documentation/healthkit/hkquantitytypeidentifier/heartratevariabilitysdnn)
- [HKHeartbeatSeries / beat-to-beat — Apple Developer Forums (WWDC19)](https://developer.apple.com/forums/thread/746218)
- [Apple Watch משתמש ב-SDNN ולא ב-RMSSD](https://trainingtodayapp.helpscoutdocs.com/article/22-does-apple-watch-use-sdnn-or-rmssd-for-hrv)
- [תקפות HRV/RR של Apple Watch מול מעבדה (PMC)](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC11478500/)
