import Combine
import Foundation

@MainActor
final class ApplicationController: ObservableObject {
    @Published private(set) var isMonitoring = true

    let model = AppModel()

    private lazy var overlayController = IslandOverlayController(model: model)
    private var cancellables: Set<AnyCancellable> = []
    private var didStart = false

    init() {
        model.$isMonitoring
            .sink { [weak self] isMonitoring in
                self?.isMonitoring = isMonitoring
            }
            .store(in: &cancellables)

        Task { @MainActor in
            start()
        }
    }

    func start() {
        guard !didStart else { return }
        didStart = true
        model.start()
        overlayController.show()
    }

    func toggleMonitoring() {
        setMonitoring(!isMonitoring)
    }

    func setMonitoring(_ enabled: Bool) {
        model.setMonitoring(enabled)
        isMonitoring = model.isMonitoring
        overlayController.refreshVisibility()
    }
}
