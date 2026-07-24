import SwiftUI

/// Log a calm moment — the safe pole (strategy memo, "map both poles"). Quick,
/// warm, and low-friction: tap where / with whom, add a word if you like, save.
/// The timestamp maps "when" on its own, so nothing here is required.
struct LogCalmMomentView: View {
    @Environment(MonitoringCoordinator.self) private var coordinator
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    @State private var place = ""
    @State private var people = ""
    @State private var note = ""

    private let places  = ["בית", "עבודה", "בחוץ", "טבע", "מיטה"]
    private let peoples = ["לבד", "בן/בת זוג", "משפחה", "חבר/ה", "ילדים"]

    var body: some View {
        let t = HRVTheme.resolve(scheme)
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HRVLayout.space24) {
                    Text("רגע שבו הרגשת רגוע. אין חובה למלא הכול — כל פרט עוזר לצייר את התמונה.")
                        .font(.hrvCallout).foregroundStyle(t.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    chipGroup(t, title: "איפה", options: places, selection: $place)
                    chipGroup(t, title: "עם מי", options: peoples, selection: $people)

                    VStack(alignment: .leading, spacing: HRVLayout.space8) {
                        Text("משהו להוסיף?").font(.hrvHeadline).foregroundStyle(t.textPrimary)
                        TextField("מה עזר לך להירגע…", text: $note, axis: .vertical)
                            .lineLimit(1...3)
                            .font(.hrvCallout)
                            .padding(HRVLayout.space12)
                            .background(t.surfacePrimary, in: RoundedRectangle(cornerRadius: HRVLayout.radius12, style: .continuous))
                    }

                    PrimaryButton(title: "שמירה") {
                        coordinator.saveCalmMoment(place: place, people: people, note: note.trimmingCharacters(in: .whitespacesAndNewlines))
                        dismiss()
                    }
                }
                .padding(HRVLayout.space20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(t.surfaceBackground)
            .navigationTitle("רגע רגוע")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("ביטול") { dismiss() } }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    private func chipGroup(_ t: HRVTheme, title: String, options: [String], selection: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: HRVLayout.space8) {
            Text(title).font(.hrvHeadline).foregroundStyle(t.textPrimary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: HRVLayout.space8) {
                    ForEach(options, id: \.self) { opt in
                        let active = selection.wrappedValue == opt
                        Button {
                            selection.wrappedValue = active ? "" : opt   // tap again to clear
                        } label: {
                            Text(opt)
                                .font(.hrvCallout)
                                .foregroundStyle(active ? t.textInverse : t.textPrimary)
                                .padding(.horizontal, HRVLayout.space16)
                                .padding(.vertical, HRVLayout.space8)
                                .background(active ? t.accentPrimary : t.surfacePrimary,
                                            in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, HRVLayout.space2)
            }
        }
    }
}
