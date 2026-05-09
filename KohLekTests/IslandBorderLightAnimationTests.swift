import Testing
@testable import KohLek

struct IslandBorderLightAnimationTests {
    @Test func normalizesPhaseIntoUnitRange() {
        #expect(IslandBorderLightAnimation.phase(time: 0, duration: 4) == 0)
        #expect(IslandBorderLightAnimation.phase(time: 5, duration: 4) == 0.25)
        #expect(IslandBorderLightAnimation.phase(time: -1, duration: 4) == 0.75)
    }

    @Test func breathingPhaseRemainsMonotonic() {
        let samples = stride(from: 0.0, through: 1.0, by: 0.05).map {
            IslandBorderLightAnimation.breathingPhase($0)
        }

        #expect(samples.first == 0)
        #expect(samples.last == 1)

        for pair in zip(samples, samples.dropFirst()) {
            #expect(pair.0 < pair.1)
        }
    }

    @Test func counterclockwisePhaseReversesTravelDirection() {
        #expect(IslandBorderLightAnimation.counterclockwisePhase(clockwisePhase: 0) == 0)
        #expect(IslandBorderLightAnimation.counterclockwisePhase(clockwisePhase: 0.25) == 0.75)
        #expect(abs(IslandBorderLightAnimation.counterclockwisePhase(clockwisePhase: 0.9) - 0.1) < 0.001)
    }

    @Test func segmentRangesWrapAroundPathBoundary() {
        let ranges = IslandBorderLightAnimation.segmentRanges(center: 0.95, length: 0.2)

        #expect(ranges.count == 2)
        #expect(abs(ranges[0].start - 0.85) < 0.001)
        #expect(ranges[0].end == 1)
        #expect(ranges[1].start == 0)
        #expect(abs(ranges[1].end - 0.05) < 0.001)
    }
}
