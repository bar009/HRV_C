# Track G — Toolchain + bootstrap פרויקט

**מיקום ב-spine:** S0 · [← חזרה לתזרים הראשי](README.md)
**פלטפורמה:** Windows + Mac · **סטטוס:** ✅ `swift test` ירוק על Windows (ARM64); פרויקט bootstrap מוכן

## מטרה
להעמיד סביבת build עובדת ולייצר את שלד הפרויקט, כך ש-`swift test` ירוץ, ועל Mac
`xcodegen generate` ייצר פרויקט מוכן.

## תלויות
- **חוסם את:** הכול (S1 ומעלה).

## משימות
- [x] `Package.swift` (HRVCore + test target), `project.yml` (XcodeGen), `Support/Info.plist`, `Support/HRV.entitlements`
- [x] התקנת Swift toolchain ל-Windows (`winget install Swift.Toolchain` → 6.3.3, arm64) + VCRedist
- [x] התקנת VS Build Tools 2022 עם workload C++ (VCTools) + `VC.Tools.ARM64` + Windows 11 SDK
- [x] מתכון build עובד → `swift/win-swift-test.cmd`

## מה נדרש כדי לבנות על Windows (Windows on ARM64) — עובד
1. `winget install Swift.Toolchain` (6.3.3) + `Microsoft.VCRedist.2015+.arm64`.
2. `winget install Microsoft.VisualStudio.2022.BuildTools --override "--quiet --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.VC.Tools.ARM64 --add Microsoft.VisualStudio.Component.Windows11SDK.22621"`.
3. הרצה עם סביבת ה-Developer מוגדרת — שלושת הדברים הקריטיים:
   - `vcvarsall.bat arm64` (מספק `link.exe` + libs)
   - Swift `Toolchains\...\usr\bin` + `Runtimes\...\usr\bin` ב-PATH
   - **`SDKROOT`** מוגדר ל-`...\Programs\Swift\Platforms\6.3.3\Windows.platform\Developer\SDKs\Windows.sdk`
     (winget משאיר את זה ריק — זו הסיבה ל-"unable to load standard library").
   כל אלה עטופים ב-[`swift/win-swift-test.cmd`](../../swift/win-swift-test.cmd).

**חוסם שנפתר בדרך:** שני קבצים בשם `Models.swift` באותו target גרמו ל-"multiple producers"
ב-SwiftPM → שונו ל-`SignalModels.swift` / `DetectionModels.swift`.

### אימות על Mac
Xcode כולל את כל ה-toolchain — `cd swift && swift test` עובד מיד, בלי כל ההתקנות לעיל.

## Definition of Done
- [x] `swift test` ירוק (Windows ARM64: 23 XCTest, 0 כשלונות — תואם ל-25 ה-pytest).
- [ ] על Mac: `xcodegen generate` מפיק `HRV.xcodeproj` שנבנה.

## אימות
```bash
cd swift && swift\win-swift-test.cmd        # Windows
cd swift && swift test                       # Mac
```
