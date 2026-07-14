# QA + TestFlight + #6 verification (על ה-Mac/מכשיר)

לביצוע ביום ה-Mac, על iPhone + Apple Watch מזווגים. מכסה #16 (QA), #15 (TestFlight), ואימות #6.

## A. מצבים גלויים (5) — כל אחד נראה נכון ולפי ה-copy ב-`PRODUCT_STATE_MODEL.md`
- [ ] `setupRequired` — לפני הרשאות; מסביר ערך לפני הבקשה
- [ ] `learning` — יום N מתוך 7; ללא התראות בתקופה
- [ ] `stable` (היום) — baseline + גרף מגמה
- [ ] `attention` — רק אחרי Alert מאומת; "זוהה שינוי מתמשך"; מוביל ל-Guided Moment
- [ ] `unavailable` — כשאין דגימה עדכנית; מוביל להגדרות
- [ ] **Watching/Cooldown מוסתרים כ-stable** (לא נחשפים)

## B. זרימות
- [ ] Onboarding M2.1→M2.4 (ערך → HealthKit → Notifications → Learning)
- [ ] Guided Moment M3.1→M3.8 — שאלה אחת למסך, Skip תמיד זמין, **האפליקציה לא ממלאת** תשובות
- [ ] Events + Trends + Settings
- [ ] **Demo Mode:** Settings → "טעינת נתוני הדגמה" → baseline+גרף+Event מופיעים
- [ ] **מחיקת כל הנתונים:** Settings → מחיקה → חוזר ל-onboarding, הכול ריק

## C. נגישות ו-RTL (AGENTS.md)
- [ ] RTL תקין בכל מסך
- [ ] Dynamic Type עד XXXL — אין חיתוך/חפיפה
- [ ] סדר VoiceOver: **כותרת → מצב → הסבר → חותם-זמן → פעולה**
- [ ] צבע לא לבד — לכל מצב יש גם טקסט/אייקון
- [ ] פעולה ראשית אחת למסך

## D. יציבות
- [ ] אפס קריסות בכל המסלולים
- [ ] אין מסכים ריקים / טקסט placeholder / lorem
- [ ] watchOS: 5 המצבים מוצגים (מינימלי — מסונכרן מהטלפון)

## E. אימות #6 — פרטיות אחסון (מאמת את `PrivacyStore`)
- [ ] המאגר נוצר תחת Application Support/HRVC (לא ב-Documents)
- [ ] **מוחרג מגיבוי:** לאשר `isExcludedFromBackup` על ה-store וה-sidecars (`-wal`/`-shm`) — למשל ברישום זמני של `resourceValues([.isExcludedFromBackupKey])`, או בדיקה שהקובץ לא מופיע בגיבוי מכשיר
- [ ] **File Protection:** הקבצים לא נקראים כשהמכשיר נעול (completeUnlessOpen)
- [ ] אין תעבורת רשת יוצאת (Instruments/Proxy) — מאשר local-only ואת ה-App Privacy label

## F. TestFlight (#15)
- [ ] Archive ב-Xcode → Upload ל-App Store Connect
- [ ] בדיקה פנימית על iPhone+Watch אמיתיים
- [ ] לוודא שה-Review Notes (Demo Mode) עובדים בדיוק כפי שכתוב ב-[`REVIEW_NOTES.md`](REVIEW_NOTES.md)

## G. לפני Submit
- [ ] Privacy Policy מאורחת ומקושרת ({{PRIVACY_URL}})
- [ ] תיאור כולל את ה-disclaimer (#4)
- [ ] App Privacy = Data Not Collected · Age Rating · Trader status — מולאו
