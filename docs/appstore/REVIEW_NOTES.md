# App Review notes — HRV-C

Paste into App Store Connect → App Review Information → Notes. (English, for the reviewer.)

---

**What HRV-C is:** a local-only wellness app. It reads passively collected Heart Rate
Variability (HRV/SDNN) and heart rate from Apple Health (read-only), learns a personal
baseline on-device, and notifies the user of a *sustained* change. It is a wellness tool,
**not a medical device** — it does not diagnose or detect any condition, emotion, or state.

**No account / no sign-in:** the app is fully local. There is no server, no login, and no
analytics. A demo account is not needed.

**Requires an Apple Watch** to collect real HRV data over time. Because a reviewer may not
have continuous Watch data, we built a **Demo Mode**:

> **How to see the app working without an Apple Watch:**
> 1. Launch the app and complete the short onboarding (tap through; you may allow or skip Health/Notifications).
> 2. Open **Settings** (gear icon, top of the main screen).
> 3. Under **"נתונים" (Data)**, tap **"טעינת נתוני הדגמה" (Load demo data)**.
> 4. Return to the main screens — you will now see a learned baseline, the trend chart
>    (Today/Trends), and one detected change under **Events**.
>
> To reset, use **Settings → נתונים → "מחיקת כל הנתונים" (Delete all data)**.

**Permissions:** HealthKit is requested **read-only** for HRV (SDNN) and heart rate, with a
specific usage string. An empty Health read is treated as "no data," never as "permission denied."

**Notifications** are local only (no push server).

**Privacy:** all data stays on device (SwiftData), is excluded from iCloud backup, and is
file-protected. Nothing is transmitted. See the Privacy Policy: {{PRIVACY_URL}}.

**UI language:** Hebrew, right-to-left.

Contact for review questions: {{CONTACT_EMAIL}}.
