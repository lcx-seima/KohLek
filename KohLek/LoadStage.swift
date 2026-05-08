import Foundation

enum LoadStage: Equatable {
    case low
    case medium
    case high

    static func classify(smoothedLoad: Double) -> LoadStage {
        let load = min(max(smoothedLoad, 0), 1)

        switch load {
        case ..<0.35:
            return .low
        case ..<0.70:
            return .medium
        default:
            return .high
        }
    }
}
