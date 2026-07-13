# Product State Model and Canonical Copy

Visual source: Figma page `13 — State Model & Canonical Copy`  
https://www.figma.com/design/hlCzE7OlX9yaZa7s5UJyhL?node-id=103-2

## User-visible states

### setupRequired — נדרש חיבור

**Entry:** Initial setup or Health access has not been completed.  
**Headline:** כדי להתחיל, נחבר את נתוני ה־HRV שלך  
**Body:** הנתונים נקראים מ־Apple Health ונשמרים במכשיר שלך.  
**Primary action:** המשך להגדרה  
**Exit:** Required setup is complete and the first valid sample is read.

### learning — למידת הטווח

**Entry:** Valid data exists, but there is not enough history for a personal baseline.  
**Headline:** לומדים את הטווח האישי שלך  
**Body:** אנחנו אוספים מדידות מנוחה כדי לזהות מה רגיל עבורך.  
**Primary action:** לצפייה בהתקדמות  
**Exit:** Learning window completes and a valid baseline exists.

### stable — בטווח האישי

**Entry:** Recent samples are within the personal range, or the detector is internally in Cooldown.  
**Headline:** בטווח האישי שלך  
**Body:** הדפוס הנוכחי תואם לטווח האישי שנלמד עבורך.  
**Primary action:** לצפייה במגמה  
**Exit:** A sustained deviation begins, or reliable recent data is unavailable.

### attention — שינוי מתמשך

**Entry:** Confirmed detector Alert only, after persistence requirements are met.  
**Headline:** זוהה שינוי מתמשך  
**Body:** כמה מדידות רצופות נמצאות מחוץ לטווח האישי שלך.  
**Primary action:** לבדוק מה קורה עכשיו  
**Exit:** Guided Moment is completed/skipped, or detector returns to Stable.

### unavailable — אין נתון עדכני

**Entry:** No reliable recent sample or a watch synchronization issue.  
**Headline:** ממתינים למדידה חדשה  
**Body:** המדידה האחרונה התקבלה בעבר. נעדכן כשיגיע נתון חדש.  
**Primary action:** בדיקת חיבור והרשאות  
**Exit:** A valid recent sample arrives.

## Internal-only detector states

### Watching

The detector is verifying persistence. Render the user experience as Stable. Do not show an alert, amber styling, or language suggesting that a change has been confirmed.

### Cooldown

Repeated alerts are being suppressed after a confirmed Alert. Normally render as Stable and preserve the event in history.

## Canonical transitions

```text
Setup Required → Learning → Stable
Stable → Watching (internal) → Attention → Cooldown (internal) → Stable
Any state → Unavailable → Learning or Stable when reliable data returns
```

## HealthKit language rule

An empty HealthKit read is not proof that permission was denied. Use factual no-data language unless direct evidence supports a permission-specific claim.
