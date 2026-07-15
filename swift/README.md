# swift/ — the Swift port

Two layers, split by what can be verified where:

| חלק | מה זה | איפה נבנה |
|-----|-------|-----------|
| `Sources/HRVCore` + `Tests` | הליבה הטהורה (Signal/Detection/Persistence) — Foundation בלבד | **Windows/Linux/Mac**: `swift test` |
| `App/`, `WatchApp/`, `Support/`, `project.yml` | אפליקציית iOS+watchOS (HealthKit/SwiftUI/SwiftData) | **Mac בלבד** (Xcode) |

`HRVCore` הוא פורט 1:1 של `hrv_core/` בפייתון; בדיקות ה-XCTest נושאות את אותם test vectors
ומספרים כמו `tests/` — הן ה-oracle שמוכיח שהפורט זהה מספרית.

## אימות הליבה

**Mac:**
```bash
cd swift && swift test          # Xcode כולל את כל ה-toolchain
```

**Windows (כולל Windows on ARM64) — עובד ✅:**
```bat
swift\win-swift-test.cmd         # 23 XCTest ירוקים, תואם ל-pytest
```
הסקריפט מגדיר את סביבת ה-Developer (`vcvarsall arm64`), את PATH ל-Swift, ו-`SDKROOT` ל-Swift
Windows SDK. דורש חד-פעמית: `Swift.Toolchain` + `VS Build Tools` (workload C++/ARM64) + Win11 SDK
— ראה [`../docs/workplan/track-G-project-setup.md`](../docs/workplan/track-G-project-setup.md).

## בניית האפליקציה (Mac)

```bash
cd swift
./mac-xcode.sh open           # מייצר HRV.xcodeproj ופותח אותו ב-Xcode
```

הסקריפט לא דורש Homebrew או הרשאות Admin. אם XcodeGen אינו מותקן, הוא בונה גרסה
מקובעת בתוך `~/Library/Caches` ומשתמש בה בפעמים הבאות. אחרי שינוי ב-Windows,
זרימת העבודה ב-Mac היא:

```bash
cd ~/Documents/HRV_C
git pull
./swift/mac-xcode.sh open
```

לאימות build מלא משורת הפקודה, ללא חתימה:

```bash
./swift/mac-xcode.sh test
```

`HRV.xcodeproj` הוא קובץ מיוצר ואינו נשמר ב-Git. מקור האמת נשאר `project.yml`.

מסלול העבודה המלא, שלב-אחר-שלב, נמצא ב-[`docs/workplan/README.md`](../docs/workplan/README.md).
