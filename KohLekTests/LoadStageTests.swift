import Testing
@testable import KohLek

struct LoadStageTests {
    @Test func classifiesLowMediumAndHighLoad() {
        #expect(LoadStage.classify(smoothedLoad: 0.12) == .low)
        #expect(LoadStage.classify(smoothedLoad: 0.35) == .medium)
        #expect(LoadStage.classify(smoothedLoad: 0.70) == .high)
    }

    @Test func clampsOutOfRangeLoadBeforeClassifying() {
        #expect(LoadStage.classify(smoothedLoad: -0.4) == .low)
        #expect(LoadStage.classify(smoothedLoad: 1.8) == .high)
    }
}
