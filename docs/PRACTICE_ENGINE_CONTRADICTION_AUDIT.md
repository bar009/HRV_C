# Practice Engine Contradiction Audit

מסמך זה מתעד אילו הנחות ישנות הוחלפו בהחלטת מנוע התרגול שבסעיף 21 של
`PRODUCT_REQUIREMENTS_HE.md`. סעיף 21 הוא מקור האמת במקרה של סתירה.

| נושא | מצב ישן | החלטה מחייבת |
| --- | --- | --- |
| Coherence ב-V1 | נדחה ל-v1.1 או לעתיד | חלק מיעד V1, נפתח בהדרגה מאחורי feature flags |
| חיישן ראשי | Apple Watch / HealthKit-first | Polar H10 הוא מקור RR ראשי; HealthKit ממשיך במסלול הפסיבי |
| Watch RR | BPM הומר ל-IBI משוער | BPM אינו RR; מוצג רק `מדד קצב משוער` |
| תרגול | מסך קוהרנטיות יחיד | Technique ו-Protocol נפרדים, קטלוג 50 ומנוע המלצה |
| מדד הצלחה | ציון Coherence ממוצע ושיא | דיווח המשתמש קודם; פיזיולוגיה היא הקשר משני |
| כניסה מהתראה | Guided Moment יחיד | שתי כניסות: בדיקה או תרגול, עם מעבר אופציונלי |
| ללא חיישן | לא הוגדר | תרגול ומשוב מלאים ללא מדדים |
| קהל יעד | פתוח | מבוגרים בריאים בני 18 ומעלה |

## מסמכים וקוד הדורשים יישור בהמשך

- `README.md`, `HRV_App_Spec.md` ו-`HRV_Architecture_Deep_Dive.md` עדיין
  מתארים ברובם את הארכיטקטורה הפסיבית ההיסטורית. הם אינם מבטלים את סעיף 21.
- `PracticeScreen` ו-`CoherenceSessionController` הם אב-טיפוס Track J ואינם
  עדיין ה-UX הסופי של מנוע התרגול.
- `WorkoutCoherenceController` מפיק כיום IBI משוער מ-BPM. אסור לפתוח את
  התוצאה למשתמש כ-Coherence; החיבור יוחלף במדד קצב משוער לפני הפעלת flag.
- Figma עדיין אינו כולל את מסכי המנוע החדשים ודורש handoff נפרד.

## שערי אימות שאינם אפשריים ב-Windows

- חיבור BLE ו-RR אמיתי מול Polar H10.
- צפיפות ואמינות דופק ב-`HKWorkoutSession` על Apple Watch פיזי.
- קומפילציה מלאה של SwiftUI, SwiftData, HealthKit ו-watchOS ב-Xcode.
- VoiceOver, Dynamic Type, רטט, audio session והפעלה ברקע במכשירים.
