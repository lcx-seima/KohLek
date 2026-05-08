import Combine
import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var isMonitoring = true
    @Published private(set) var smoothedLoad = 0.0
    @Published private(set) var loadStage: LoadStage = .low
    @Published private(set) var islandFeedbackStart: TimeInterval?

    private let cpuMonitor = CPUMonitor()

    func start() {
        cpuMonitor.onLoadUpdate = { [weak self] load in
            guard let self else { return }
            smoothedLoad = load
            loadStage = LoadStage.classify(smoothedLoad: load)
        }
        cpuMonitor.start()
    }

    func toggleMonitoring() {
        setMonitoring(!isMonitoring)
    }

    func setMonitoring(_ enabled: Bool) {
        guard enabled != isMonitoring else { return }
        isMonitoring = enabled

        if enabled {
            cpuMonitor.start()
        } else {
            cpuMonitor.stop()
        }
    }

    func triggerIslandFeedback() {
        islandFeedbackStart = Date.timeIntervalSinceReferenceDate
    }
}
