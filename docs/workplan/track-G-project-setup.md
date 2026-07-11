# Track G — Toolchain + bootstrap פרויקט

**מיקום ב-spine:** S0 · [← חזרה לתזרים הראשי](README.md)
**פלטפורמה:** Windows + Mac · **סטטוס:** 🟡 Swift מותקן ורץ; קומפילציה מקומית חסומה על MSVC/SDK

## מטרה
להעמיד סביבת build עובדת ולייצר את שלד הפרויקט, כך ש-`swift test` ירוץ, ועל Mac
`xcodegen generate` ייצר פרויקט מוכן.

## תלויות
- **חוסם את:** הכול (S1 ומעלה).

## משימות
- [x] `Package.swift` (HRVCore + test target), `project.yml` (XcodeGen), `Support/Info.plist`, `Support/HRV.entitlements`
- [x] התקנת Swift toolchain ל-Windows (`winget install Swift.Toolchain` → 6.3.3, arm64) + VCRedist
- [ ] **חסם פתוח:** קומפילציה על Windows דורשת **Windows SDK + MSVC (VC Build Tools)**

## מצב ה-toolchain על המכונה הזו (Windows on ARM)
- ✅ Swift 6.3.3 מותקן ורץ — `swift --version` תקין (target `aarch64-unknown-windows-msvc`).
- ❌ `swift build` נכשל: `could not find CLI tool 'link'` — חסר ה-MSVC linker + Windows SDK.
  (ב-VS Community 2022 המותקן חסר workload ה-C++; אין WSL; אין Docker.)

### כדי לאפשר `swift test` על Windows (פעם אחת)
התקנת workload ה-C++ (ARM64) — כמה GB, דורש הרשאות מנהל:
```powershell
winget install Microsoft.VisualStudio.2022.BuildTools --override `
  "--quiet --wait --add Microsoft.VisualStudio.Workload.VCTools `
   --add Microsoft.VisualStudio.Component.VC.Tools.ARM64 `
   --add Microsoft.VisualStudio.Component.Windows11SDK.22621"
```
לאחר מכן, מ-"Developer PowerShell" (או אחרי `vcvarsall`), הוסף את bin של ה-toolchain ל-PATH:
`%LOCALAPPDATA%\Programs\Swift\Toolchains\6.3.3+Asserts\usr\bin` ו-`...\Runtimes\6.3.3\usr\bin`.

### חלופה: אימות על Mac
Xcode כולל את כל ה-toolchain. `cd swift && swift test` עובד מיד, בלי כל ההתקנות לעיל.

## Definition of Done
- `swift test` ירוק (Windows עם SDK, או Mac).
- על Mac: `xcodegen generate` מפיק `HRV.xcodeproj` שנבנה.

## אימות
```bash
cd swift && swift build && swift test
```
