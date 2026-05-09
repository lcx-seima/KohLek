import Foundation

struct IslandBorderLightAnimation {
    struct SegmentRange {
        let start: Double
        let end: Double
    }

    static func phase(time: TimeInterval, duration: TimeInterval) -> Double {
        guard duration > 0 else { return 0 }

        let raw = time.truncatingRemainder(dividingBy: duration) / duration
        return raw >= 0 ? raw : raw + 1
    }

    static func breathingPhase(_ phase: Double) -> Double {
        let clamped = min(max(phase, 0), 1)
        let strength = 0.58
        return clamped - sin(clamped * 2 * .pi) * strength / (2 * .pi)
    }

    static func counterclockwisePhase(clockwisePhase: Double) -> Double {
        let normalized = clockwisePhase.truncatingRemainder(dividingBy: 1)
        let phase = normalized >= 0 ? normalized : normalized + 1
        return phase == 0 ? 0 : 1 - phase
    }

    static func segmentRanges(center: Double, length: Double) -> [SegmentRange] {
        let segmentLength = min(max(length, 0), 1)
        guard segmentLength > 0 else { return [] }
        guard segmentLength < 1 else { return [SegmentRange(start: 0, end: 1)] }

        let normalizedCenter = normalized(center)
        let halfLength = segmentLength / 2
        let start = normalizedCenter - halfLength
        let end = normalizedCenter + halfLength

        if start < 0 {
            return [
                SegmentRange(start: 1 + start, end: 1),
                SegmentRange(start: 0, end: end)
            ]
        }

        if end > 1 {
            return [
                SegmentRange(start: start, end: 1),
                SegmentRange(start: 0, end: end - 1)
            ]
        }

        return [SegmentRange(start: start, end: end)]
    }

    private static func normalized(_ value: Double) -> Double {
        let wrapped = value.truncatingRemainder(dividingBy: 1)
        return wrapped >= 0 ? wrapped : wrapped + 1
    }
}
