# Track A — פורט הליבה (HRVCore)

**מיקום ב-spine:** S1 · [← חזרה לתזרים הראשי](README.md)
**פלטפורמה:** Windows/Linux/Mac (Foundation בלבד) · **סטטוס:** 🟡 קוד + בדיקות נכתבו; `swift test` ממתין ל-toolchain (ראה [Track G](track-G-project-setup.md))

## מטרה
פורט 1:1 של הליבה החישובית מפייתון ל-Swift, כך שהיא מתקמפלת ונבדקת מחוץ ל-Mac, ומשמשת
כ**מפרט בר-הרצה** לאפליקציה. ה-XCTests נושאים את אותם test vectors כמו `tests/` — הם ה-oracle.

## תלויות
- **חוסם:** [Track G](track-G-project-setup.md) (toolchain).
- **חוסם את:** כל השאר — [B](track-B-healthkit.md), [C](track-C-persistence.md), [D](track-D-notifications.md), [F](track-F-ios-ui.md) מייבאים את `HRVCore`.

## קלט
- מקור: `hrv_core/signal/*`, `hrv_core/detection/*`, `hrv_core/persistence/*`
- מיפוי: [`../SWIFT_PORTING_MAP.md`](../SWIFT_PORTING_MAP.md) · נוסחאות: Deep Dive A/B

## משימות
- [x] Signal: `Models.swift`, `HRVCalculator.swift`, `ArtifactCorrector.swift`
- [x] Detection: `Statistics.swift`, `Models.swift`, `BaselineEngine.swift`, `AnomalyDetector.swift`
- [x] Persistence: `HRVRepository.swift` (protocol), `InMemoryHRVRepository.swift`
- [x] Tests: פורט כל 25 הבדיקות ל-`Tests/HRVCoreTests/` עם אותם מספרים
- [ ] `swift test` ירוק על מכשיר עם toolchain (Windows כשיהיה SDK, או Mac)

## Windows-עכשיו / Mac-אחר-כך
כל ה-Track בלתי-תלוי-פלטפורמה. נכתב עכשיו; ההרצה תלויה רק בזמינות toolchain.

## Definition of Done
- `swift test` ירוק, וכל ערך תואם ל-`pytest` המקביל (parity).
- אין ב-`Sources/HRVCore` שום `import` מלבד `Foundation`.

## אימות
```bash
cd swift && swift test        # משווים מול: (repo root) pytest -q
```
