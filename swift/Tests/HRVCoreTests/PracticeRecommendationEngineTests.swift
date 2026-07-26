import XCTest
@testable import HRVCore

final class PracticeRecommendationEngineTests: XCTestCase {
    func testCatalogContainsExactlyFiftyStableTechniques() {
        XCTAssertEqual(PracticeCatalog.techniques.count, 50)
        XCTAssertEqual(Set(PracticeCatalog.techniques.map(\.id)).count, 50)
        XCTAssertEqual(Set(PracticeCatalog.techniques.map(\.catalogNumber)),
                       Set(1...50))
    }

    func testKnowledgeOnlyTechniqueIsNeverRecommended() {
        let locked = PracticeProtocol(
            id: "locked", techniqueID: "kapalabhati",
            name: LocalizedText(he: "נעול", en: "Locked"),
            goals: [.energizing], durationSeconds: 60,
            instructions: []
        )
        let result = PracticeRecommendationEngine.recommend(
            goal: .energizing, profile: RecommendationProfile(),
            protocols: [locked]
        )
        XCTAssertNil(result)
    }

    func testHiddenTechniqueIsExcluded() {
        let profile = RecommendationProfile(
            hiddenTechniqueIDs: ["four-six"]
        )
        let result = PracticeRecommendationEngine.recommend(
            goal: .quickReset, profile: profile
        )
        XCTAssertNotEqual(result?.protocolValue.techniqueID, "four-six")
    }

    func testSelfReportedBenefitOutranksPhysiology() {
        let outcomes = [
            PracticeOutcome(protocolID: "long-release", goal: .calming,
                            completed: true, comfortable: true,
                            wouldChooseAgain: true, intensityBefore: 8,
                            intensityAfter: 3, physiologicalTrend: -5),
            PracticeOutcome(protocolID: "coherent-wave", goal: .calming,
                            completed: true, comfortable: false,
                            wouldChooseAgain: false, intensityBefore: 8,
                            intensityAfter: 8, physiologicalTrend: 5)
        ]
        let result = PracticeRecommendationEngine.recommend(
            goal: .calming,
            profile: RecommendationProfile(outcomes: outcomes)
        )
        XCTAssertEqual(result?.protocolValue.id, "long-release")
    }

    func testExplorationSelectsTransparentAlternative() {
        let result = PracticeRecommendationEngine.recommend(
            goal: .calming, profile: RecommendationProfile(),
            exploreAlternative: true
        )
        XCTAssertTrue(result?.isExploration == true)
        XCTAssertTrue(result?.reason.he.contains("חלופה") == true)
    }

    func testTemporarilyHiddenAfterDiscomfortIsExcluded() {
        let profile = RecommendationProfile(
            temporarilyHiddenTechniqueIDs: ["four-six"]
        )
        let result = PracticeRecommendationEngine.recommend(
            goal: .quickReset, profile: profile
        )
        XCTAssertNotEqual(result?.protocolValue.techniqueID, "four-six")
    }
}
