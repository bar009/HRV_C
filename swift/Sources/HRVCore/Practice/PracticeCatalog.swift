import Foundation

public enum PracticeCatalog {
    public static let techniques: [BreathingTechnique] = [
        t(1, "natural-awareness", "נשימה טבעית מודעת", "Natural breath awareness", .recommended, [.awareness, .grounding]),
        t(2, "diaphragmatic", "נשימה סרעפתית", "Diaphragmatic breathing", .recommended, [.calming, .grounding]),
        t(3, "crocodile", "נשימת תנין", "Crocodile breathing", .manual, [.grounding, .awareness]),
        t(4, "lateral-rib", "נשימה צלעית צדדית", "Lateral rib breathing", .manual, [.grounding, .awareness]),
        t(5, "posterior-rib", "נשימה לצלעות האחוריות", "Posterior rib breathing", .manual, [.grounding, .awareness]),
        t(6, "breathing-360", "נשימת 360 מעלות", "360-degree breathing", .recommended, [.grounding, .awareness]),
        t(7, "segmental-unilateral", "נשימה מקטעית חד־צדדית", "Unilateral segmental breathing", .knowledgeOnly, [.awareness]),
        t(8, "dirga", "דירגה", "Dirga full yogic breath", .manual, [.calming, .awareness]),
        t(9, "release-sigh", "אנחת שחרור", "Release sigh", .recommended, [.quickReset, .recovery]),
        t(10, "humming-exhale", "נשיפה בזמזום", "Humming exhale", .recommended, [.calming, .recovery]),
        t(11, "sama-vritti", "נשימה שווה", "Equal breathing", .manual, [.calming, .focus]),
        t(12, "ratio-one-two", "נשימת יחס 1:2", "One-to-two breathing", .manual, [.calming, .sleep]),
        t(13, "four-six", "נשימת 4–6", "Four-six breathing", .recommended, [.calming, .quickReset, .recovery]),
        t(14, "four-eight", "נשימת 4–8", "Four-eight breathing", .manual, [.calming, .sleep]),
        t(15, "triangle", "נשימת משולש", "Triangle breathing", .manual, [.focus], retention: true),
        t(16, "box", "נשימת ריבוע", "Box breathing", .manual, [.focus, .calming], retention: true),
        t(17, "four-seven-eight", "נשימת 4–7–8", "Four-seven-eight breathing", .manual, [.sleep, .calming], retention: true),
        t(18, "coherent-five-five", "נשימה קוהרנטית 5–5", "Five-five coherent breathing", .recommended, [.coherence, .calming]),
        t(19, "resonance-personal", "נשימת תהודה אישית", "Personal resonance breathing", .manual, [.coherence]),
        t(20, "breathing-365", "נשימת 365", "365 breathing", .manual, [.coherence, .calming]),
        t(21, "physiological-sigh", "אנחה פיזיולוגית", "Physiological sigh", .recommended, [.quickReset, .recovery]),
        t(22, "cyclic-sighing", "אנחות מחזוריות", "Cyclic sighing", .manual, [.recovery, .calming]),
        t(23, "straw-exhale", "נשיפה דרך קש", "Straw exhale", .manual, [.calming, .awareness]),
        t(24, "pursed-lip", "נשימת שפתיים קפוצות", "Pursed-lip breathing", .knowledgeOnly, [.recovery]),
        t(25, "movement-rhythm", "נשימת קצב בתנועה", "Movement-rhythm breathing", .manual, [.focus, .energizing]),
        t(26, "papworth", "שיטת Papworth", "Papworth method", .knowledgeOnly, [.calming]),
        t(27, "buteyko-reduced", "נשימה מופחתת בוטייקו", "Buteyko reduced breathing", .knowledgeOnly, [.awareness]),
        t(28, "susokukan", "סוסוקוקאן", "Susokukan breath counting", .recommended, [.focus, .awareness]),
        t(29, "dantian", "נשימת דנטיאן", "Dantian breathing", .manual, [.grounding, .traditional]),
        t(30, "reverse-abdominal", "נשימה בטנית הפוכה", "Reverse abdominal breathing", .knowledgeOnly, [.traditional]),
        t(31, "nadi-basic", "נאדי שודהנה בסיסית", "Basic Nadi Shodhana", .manual, [.calming, .focus, .traditional]),
        t(32, "anulom-vilom", "אנולום וילום", "Anulom Vilom", .manual, [.calming, .traditional]),
        t(33, "nadi-antara", "נאדי שודהנה עם עצירה פנימית", "Nadi Shodhana with internal retention", .knowledgeOnly, [.traditional], retention: true),
        t(34, "nadi-bahya", "נאדי שודהנה עם עצירה חיצונית", "Nadi Shodhana with external retention", .knowledgeOnly, [.traditional], retention: true),
        t(35, "surya-bhedana", "סוריה בהדנה", "Surya Bhedana", .manual, [.energizing, .traditional]),
        t(36, "chandra-bhedana", "צ׳נדרה בהדנה", "Chandra Bhedana", .manual, [.calming, .traditional]),
        t(37, "ujjayi", "אוג׳אי", "Ujjayi breathing", .manual, [.focus, .calming, .traditional]),
        t(38, "bhramari", "בהרמרי", "Bhramari humming breath", .recommended, [.calming, .recovery, .traditional]),
        t(39, "shanmukhi-bhramari", "שאנמוקהי בהרמרי", "Shanmukhi Bhramari", .knowledgeOnly, [.traditional]),
        t(40, "sitali", "שיטאלי", "Sitali cooling breath", .manual, [.recovery, .traditional]),
        t(41, "sitkari", "שיטקארי", "Sitkari breathing", .manual, [.recovery, .traditional]),
        t(42, "kaki-mudra", "קאקי מודרה", "Kaki Mudra breathing", .manual, [.calming, .traditional]),
        t(43, "viloma-inhale", "וילומה בשאיפה", "Viloma inhalation", .manual, [.focus, .traditional]),
        t(44, "viloma-exhale", "וילומה בנשיפה", "Viloma exhalation", .manual, [.calming, .traditional]),
        t(45, "pranava-om", "פראנבה / נשימת OM", "Pranava OM breathing", .manual, [.calming, .traditional]),
        t(46, "lion", "נשימת האריה", "Lion's breath", .manual, [.energizing, .traditional]),
        t(47, "kapalabhati", "קפלאבהטי", "Kapalabhati", .knowledgeOnly, [.energizing, .traditional], rapid: true),
        t(48, "bhastrika", "בהסטריקה", "Bhastrika", .knowledgeOnly, [.energizing, .traditional], rapid: true),
        t(49, "breath-of-fire", "Breath of Fire", "Breath of Fire", .knowledgeOnly, [.energizing, .traditional], rapid: true),
        t(50, "vase", "נשימת האגרטל", "Vase breathing", .knowledgeOnly, [.traditional], retention: true)
    ]

    public static let protocols: [PracticeProtocol] = [
        p("notice-now", "natural-awareness", "רק להבחין", "Simply notice",
          [.awareness, .grounding], 120, nil, nil, "שים לב לנשימה כפי שהיא", "Notice the breath as it is"),
        p("gentle-release", "release-sigh", "איפוס עדין", "Gentle reset",
          [.quickReset, .recovery], 60, nil, nil, "שאיפה רגועה, ואז נשיפה משוחררת", "Breathe in gently, then release the exhale"),
        p("long-release", "four-six", "שחרור ארוך", "Long release",
          [.calming, .quickReset, .recovery], 120, 4, 6, "שאיפה רגועה", "Breathe in gently"),
        p("coherent-wave", "coherent-five-five", "גל קוהרנטי", "Coherent wave",
          [.coherence, .calming], 300, 5, 5, "עקוב אחרי הקצב בלי להתאמץ", "Follow the pace without forcing"),
        p("grounding-360", "breathing-360", "נשימה מלאה 360°", "360-degree grounding",
          [.grounding, .awareness], 180, nil, nil, "אפשר לצלעות התחתונות להתרחב בעדינות", "Let the lower ribs expand gently"),
        p("calming-hum", "bhramari", "זמזום מרגיע", "Calming hum",
          [.calming, .recovery], 120, nil, nil, "נשוף בזמזום נוח ועדין", "Exhale with a comfortable, gentle hum")
    ]

    public static func technique(id: String) -> BreathingTechnique? {
        techniques.first { $0.id == id }
    }

    private static func t(_ number: Int, _ id: String, _ he: String, _ en: String,
                          _ tier: TechniqueAccessTier, _ goals: Set<PracticeGoal>,
                          retention: Bool = false, rapid: Bool = false) -> BreathingTechnique {
        let warning: LocalizedText? = tier == .knowledgeOnly
            ? LocalizedText(he: "מידע בלבד; לא זמין לתרגול עצמאי ב-V1.",
                            en: "Knowledge only; unavailable for self-guided practice in V1.")
            : nil
        return BreathingTechnique(id: id, catalogNumber: number,
                                  name: LocalizedText(he: he, en: en),
                                  accessTier: tier, goals: goals,
                                  hasRetention: retention, isRapid: rapid,
                                  safetyNote: warning)
    }

    private static func p(_ id: String, _ techniqueID: String, _ he: String, _ en: String,
                          _ goals: Set<PracticeGoal>, _ duration: Int,
                          _ inhale: Double?, _ exhale: Double?,
                          _ instructionHE: String, _ instructionEN: String) -> PracticeProtocol {
        PracticeProtocol(id: id, techniqueID: techniqueID,
                         name: LocalizedText(he: he, en: en), goals: goals,
                         durationSeconds: duration, inhaleSeconds: inhale,
                         exhaleSeconds: exhale,
                         instructions: [LocalizedText(he: instructionHE, en: instructionEN)])
    }
}
