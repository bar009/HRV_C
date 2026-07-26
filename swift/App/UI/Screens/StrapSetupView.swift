import SwiftUI
import HRVCore

/// Pair and monitor a Bluetooth heart-rate strap. Vendor-neutral by design: the
/// app talks the standard Heart Rate Service, so any compliant strap works —
/// Polar, Garmin, Wahoo and others alike.
struct StrapSetupView: View {
    @Environment(StrapMonitor.self) private var strap
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let t = HRVTheme.resolve(scheme)
        ScrollView {
            VStack(alignment: .leading, spacing: HRVLayout.space16) {
                statusCard(t)

                if !strap.isConnected {
                    PrimaryButton(title: strap.state == .scanning ? "מחפש…" : "חיפוש רצועות") {
                        strap.startScan()
                    }
                    if !strap.discovered.isEmpty { deviceList(t) }
                    compatibilityNote(t)
                } else {
                    IndicatorAvailabilityList(capabilities: strap.capabilities)
                    Button(role: .destructive) { strap.forget() } label: {
                        Text("ניתוק ושכחת המכשיר")
                            .font(.hrvCallout).fontWeight(.semibold)
                            .frame(maxWidth: .infinity, minHeight: HRVLayout.minimumTouchSize)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(t.statusCritical)
                }
            }
            .padding(HRVLayout.space20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .animation(HRVMotion.gentle, value: strap.state)
        }
        .background(t.surfaceBackground)
        .navigationTitle("רצועת דופק")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { strap.stopScan() }
    }

    // MARK: status

    private func statusCard(_ t: HRVTheme) -> some View {
        VStack(alignment: .leading, spacing: HRVLayout.space8) {
            HStack(spacing: HRVLayout.space8) {
                Circle()
                    .fill(statusColor(t))
                    .frame(width: HRVLayout.statusDotSize, height: HRVLayout.statusDotSize)
                Text(statusTitle).font(.hrvHeadline).foregroundStyle(t.textPrimary)
                Spacer()
                if let battery = strap.batteryPercent, strap.isConnected {
                    Label("\(battery)%", systemImage: "battery.100")
                        .font(.hrvCaption).foregroundStyle(t.textSecondary)
                }
            }
            Text(statusDetail)
                .font(.hrvCallout).foregroundStyle(t.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if strap.isConnected, strap.currentBPM > 0 {
                HStack(spacing: HRVLayout.space12) {
                    Label("\(strap.currentBPM) bpm", systemImage: "heart.fill")
                        .font(.hrvCallout).foregroundStyle(t.statusStable)
                    Text("\(strap.bufferedBeats) פעימות בחלון")
                        .font(.hrvCaption).foregroundStyle(t.textTertiary)
                }
            }
        }
        .padding(HRVLayout.space16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(t.surfacePrimary, in: RoundedRectangle(cornerRadius: HRVLayout.radius20, style: .continuous))
    }

    private func statusColor(_ t: HRVTheme) -> Color {
        switch strap.state {
        case .connected:    return t.statusStable
        case .noRRSupport:  return t.statusAttention
        case .scanning, .connecting: return t.statusLearning
        default:            return t.textTertiary
        }
    }

    private var statusTitle: String {
        switch strap.state {
        case .idle:                 return "לא מחובר"
        case .scanning:             return "מחפש רצועות…"
        case .connecting:           return "מתחבר…"
        case .connected(let n):     return n
        case .noRRSupport(let n):   return n
        case .disconnected:         return "החיבור נותק"
        case .unauthorized:         return "אין הרשאת בלוטות'"
        case .poweredOff:           return "הבלוטות' כבוי"
        case .unsupported:          return "בלוטות' לא נתמך"
        }
    }

    private var statusDetail: String {
        switch strap.state {
        case .idle, .disconnected:
            return "חברו רצועת דופק כדי למדוד HRV ברציפות ולזהות שינוי בזמן אמת."
        case .scanning:
            return "ודאו שהרצועה לחה ולבושה — כך היא משדרת."
        case .connecting:
            return "מתחבר לרצועה…"
        case .connected:
            return "מחובר ומודד מרווחים בין פעימות."
        case .noRRSupport:
            return "המכשיר הזה משדר דופק בלבד, ללא מרווחים בין פעימות — לכן מדדי ה-HRV אינם זמינים איתו. רצועת חזה תאפשר את כל היכולות."
        case .unauthorized:
            return "יש לאשר גישה לבלוטות' בהגדרות המכשיר."
        case .poweredOff:
            return "הפעילו בלוטות' כדי להתחבר."
        case .unsupported:
            return "המכשיר הזה אינו תומך בבלוטות'."
        }
    }

    // MARK: devices

    private func deviceList(_ t: HRVTheme) -> some View {
        VStack(alignment: .leading, spacing: HRVLayout.space8) {
            Text("נמצאו").font(.hrvHeadline).foregroundStyle(t.textPrimary)
            ForEach(strap.discovered) { device in
                Button { strap.connect(device.id) } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: HRVLayout.space2) {
                            Text(device.displayName)
                                .font(.hrvCallout).fontWeight(.semibold)
                                .foregroundStyle(t.textPrimary)
                            Text(device.expectsRR ? "תומך במרווחי פעימות" : "יכולות ייבדקו לאחר חיבור")
                                .font(.hrvCaption).foregroundStyle(t.textTertiary)
                        }
                        Spacer()
                        Image(systemName: "chevron.forward")
                            .font(.hrvSubheadline).foregroundStyle(t.textTertiary)
                    }
                    .padding(HRVLayout.space16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(t.surfacePrimary, in: RoundedRectangle(cornerRadius: HRVLayout.radius16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func compatibilityNote(_ t: HRVTheme) -> some View {
        InformationCard(
            title: "רצועות תואמות",
            message: "האפליקציה עובדת עם כל רצועת דופק בתקן הבלוטות' הפתוח שמשדרת מרווחים בין פעימות — למשל Polar H10 / H9 / Verity Sense, Garmin HRM, ו-Wahoo TICKR. גם דגמים אחרים שתומכים בתקן יתחברו.")
    }
}
