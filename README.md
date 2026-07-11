# HRV-C — ניטור HRV והתראות (ליבה + תכנון)

פרויקט עצמאי לאפליקציית ניטור HRV והתראות ל-**iOS + watchOS**. המוצר קורא דופק ו-HRV
שה-Apple Watch אוסף פסיבית, בונה baseline אישי, ומתריע על שינוי קיצוני — הכל **מקומית
על המכשיר**, בלי backend ובלי ענן.

הריפו הזה מכיל כרגע שני דברים:

1. **`docs/`** — מסמכי התכנון המלאים (אפיון מוצר, ארכיטקטורה, מחקר HeartMath).
2. **`hrv_core/` + `sim/` + `tests/`** — **אב-טיפוס Python בלתי-תלוי-פלטפורמה** של הליבה
   החישובית הפסיבית: כל המתמטיקה והלוגיקה שהמסמכים מגדירים כ"לב המוצר".

## למה Python, אם המוצר הוא iOS/watchOS?

פיתוח נייטיב iOS/watchOS מחייב **macOS + Xcode + מכשירים פיזיים** (HealthKit כמעט לא עובד
בסימולטור). הפיתוח כרגע על Windows, ו-Mac יגיע בהמשך. אבל כל המתמטיקה — RMSSD, ניקוי
ארטיפקטים, baseline (median+MAD), מכונת המצבים — **בלתי-תלוית-פלטפורמה**. לכן היא נכתבת,
נבדקת ומכוילת עכשיו ב-Python, והופכת ל**מפרט בר-הרצה (executable reference)** שהפורט ל-Swift
אחריו הוא כמעט מכני. הבדיקות הן ה-oracle שגרסת ה-Swift חייבת לשחזר מספרית.

ראה [`docs/SWIFT_PORTING_MAP.md`](docs/SWIFT_PORTING_MAP.md) למיפוי המדויק Python → Swift,
ו-[`docs/DECISIONS.md`](docs/DECISIONS.md) לסטטוס ההחלטות והנקודות הפתוחות.

## מבנה

```
hrv_core/            # הליבה הבלתי-תלוית-פלטפורמה — Python תקני בלבד (stdlib), מראה 1:1 ל-Swift
  signal/            #   HRVSample, HRVCalculator (RMSSD/SDNN/pNN50), ArtifactCorrector   (Deep Dive A)
  detection/         #   BaselineEngine (median+MAD על ln), AnomalyDetector + מכונת מצבים  (Deep Dive B)
  persistence/       #   HRVRepository לוגי (in-memory)                                     (Deep Dive C)
sim/                 # מחולל נתונים סינתטיים + הרצת סימולציה מקצה-לקצה (numpy/matplotlib)
tests/               # בדיקות pytest מול ערכים ידועים — ה-oracle לגרסת Swift
docs/                # מסמכי התכנון + החלטות + מפת המרה
```

## הרצה

```bash
cd C:\dev\HRV-C
pip install -r requirements.txt

pytest                          # כל הבדיקות
python -m sim.run_scenario      # סימולציה רב-יומית: זיהוי אירוע + בקרת false-positive
python -m sim.run_scenario --plot   # + פלט PNG של scenario A
```

`run_scenario` הוא גם **כלי הכיול החי** לפרמטרים `k` / `persistence` / `cooldown`
(Deep Dive B.7, נקודה פתוחה Q-B):

```bash
python -m sim.run_scenario --k 2.0 --persistence 3 --cooldown-hours 12 --drop 0.4
```

## מה מחוץ לתחום כרגע (מכוון)

- **מודול Coherence / מצב אקטיבי (D-COH)** — צינור תחום-תדר (FFT). התחלנו פסיבי; זה מודול
  נפרד עתידי (`hrv_core/coherence/`).
- **כל הנייטיב** — פרויקט Xcode, HealthKitService, watchOS, SwiftUI, Local Notifications,
  מנוע אחסון SwiftData/GRDB — כשיגיע Mac. ראה מפת ההמרה.
