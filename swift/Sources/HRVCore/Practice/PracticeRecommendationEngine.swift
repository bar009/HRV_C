import Foundation

public enum PracticeRecommendationEngine {
    public static func recommend(
        goal: PracticeGoal,
        profile: RecommendationProfile,
        exploreAlternative: Bool = false,
        protocols: [PracticeProtocol] = PracticeCatalog.protocols,
        techniques: [BreathingTechnique] = PracticeCatalog.techniques
    ) -> PracticeRecommendation? {
        let techniquesByID = Dictionary(uniqueKeysWithValues: techniques.map { ($0.id, $0) })

        let eligible = protocols.filter { protocolValue in
            guard let technique = techniquesByID[protocolValue.techniqueID] else { return false }
            return technique.accessTier == .recommended
                && !profile.hiddenTechniqueIDs.contains(technique.id)
                && !profile.temporarilyHiddenTechniqueIDs.contains(technique.id)
                && protocolValue.goals.contains(goal)
        }

        let ranked = eligible
            .map { ($0, score($0, goal: goal, profile: profile)) }
            .sorted {
                if $0.1 == $1.1 { return $0.0.id < $1.0.id }
                return $0.1 > $1.1
            }

        guard !ranked.isEmpty else { return nil }
        let selectedIndex = exploreAlternative && ranked.count > 1 ? 1 : 0
        let selected = ranked[selectedIndex].0
        let reason = exploreAlternative && selectedIndex == 1
            ? LocalizedText(
                he: "חלופה בטוחה כדי ללמוד מה מתאים לך.",
                en: "A safe alternative to learn what works for you."
            )
            : recommendationReason(for: selected, profile: profile)
        return PracticeRecommendation(protocolValue: selected, reason: reason,
                                      isExploration: selectedIndex == 1)
    }

    private static func score(_ protocolValue: PracticeProtocol, goal: PracticeGoal,
                              profile: RecommendationProfile) -> Double {
        var value = protocolValue.goals.contains(goal) ? 40.0 : 0
        if profile.favoriteProtocolIDs.contains(protocolValue.id) { value += 8 }

        let outcomes = profile.outcomes.filter {
            $0.protocolID == protocolValue.id && $0.goal == goal
        }
        guard !outcomes.isEmpty else { return value }

        // Self-report intentionally dominates physiology.
        let intensityChanges = outcomes.compactMap { outcome -> Double? in
            guard let before = outcome.intensityBefore, let after = outcome.intensityAfter else {
                return nil
            }
            return Double(before - after)
        }
        if !intensityChanges.isEmpty {
            let average = intensityChanges.reduce(0, +) / Double(intensityChanges.count)
            value += max(-20, min(20, average * 4))
        }

        let comfort = ratio(outcomes.compactMap(\.comfortable))
        let chooseAgain = ratio(outcomes.compactMap(\.wouldChooseAgain))
        let completion = ratio(outcomes.map(\.completed))
        value += comfort * 10
        value += chooseAgain * 10
        value += completion * 5

        let physiology = outcomes.compactMap(\.physiologicalTrend)
        if !physiology.isEmpty {
            let average = physiology.reduce(0, +) / Double(physiology.count)
            value += max(-5, min(5, average))
        }
        return value
    }

    private static func ratio(_ values: [Bool]) -> Double {
        guard !values.isEmpty else { return 0 }
        return Double(values.filter { $0 }.count) / Double(values.count)
    }

    private static func recommendationReason(for protocolValue: PracticeProtocol,
                                             profile: RecommendationProfile) -> LocalizedText {
        let prior = profile.outcomes.filter { $0.protocolID == protocolValue.id }
        if !prior.isEmpty {
            return LocalizedText(
                he: "התרגול התאים לצורך הזה ועזר לך בעבר.",
                en: "This practice matches your need and has helped you before."
            )
        }
        return LocalizedText(
            he: "התרגול מתאים לצורך שבחרת וזמין לשימוש עצמאי.",
            en: "This practice matches your selected need and is available for self-guided use."
        )
    }
}
