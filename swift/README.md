# swift/ — the Swift port

Two layers, split by what can be verified where:

| חלק | מה זה | איפה נבנה |
|-----|-------|-----------|
| `Sources/HRVCore` + `Tests` | הליבה הטהורה (Signal/Detection/Persistence) — Foundation בלבד | **Windows/Linux/Mac**: `swift test` |
| `App/`, `WatchApp/`, `Support/`, `project.yml` | אפליקציית iOS+watchOS (HealthKit/SwiftUI/SwiftData) | **Mac בלבד** (Xcode) |

`HRVCore` הוא פורט 1:1 של `hrv_core/` בפייתון; בדיקות ה-XCTest נושאות את אותם test vectors
ומספרים כמו `tests/` — הן ה-oracle שמוכיח שהפורט זהה מספרית.

## אימות הליבה (כל פלטפורמה עם Swift)

```bash
cd swift
swift test          # HRVCoreTests — חייב להיות ירוק ולתאום ל-pytest
```

> **הערה על Windows:** הליבה מכוונת ל-`*-windows-msvc`, ולכן קומפילציה מקומית דורשת
> **Windows SDK + MSVC (VC Build Tools)** בנוסף ל-Swift toolchain. אם `swift build` נכשל עם
> `could not find CLI tool 'link'` — חסר ה-MSVC. ראה `docs/workplan/track-G-project-setup.md`.
> על **Mac** ה-toolchain מגיע עם Xcode ו-`swift test` עובד מיד.

## בניית האפליקציה (Mac)

```bash
brew install xcodegen        # פעם אחת
cd swift
xcodegen generate            # יוצר HRV.xcodeproj מ-project.yml
open HRV.xcodeproj           # build & run על iPhone + Apple Watch מזווגים
```

מסלול העבודה המלא, שלב-אחר-שלב, נמצא ב-[`docs/workplan/README.md`](../docs/workplan/README.md).
