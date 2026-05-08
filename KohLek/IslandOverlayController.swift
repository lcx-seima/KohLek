import AppKit
import SwiftUI

@MainActor
final class IslandOverlayController {
    private let model: AppModel
    private let notifier = IslandClickNotifier()
    private var panel: NSPanel?
    private var metrics: IslandOverlayMetrics?
    private var localClickMonitor: Any?
    private var globalClickMonitor: Any?

    init(model: AppModel) {
        self.model = model
        installClickMonitors()
    }

    deinit {
        if let localClickMonitor {
            NSEvent.removeMonitor(localClickMonitor)
        }
        if let globalClickMonitor {
            NSEvent.removeMonitor(globalClickMonitor)
        }
    }

    func show() {
        guard let screen = NSScreen.main else { return }
        let nextMetrics = IslandOverlayMetrics.metrics(
            screenFrame: screen.frame,
            auxiliaryTopLeftArea: screen.auxiliaryTopLeftArea ?? .zero,
            auxiliaryTopRightArea: screen.auxiliaryTopRightArea ?? .zero
        )

        if panel == nil || metrics != nextMetrics {
            metrics = nextMetrics
            panel?.close()
            panel = makePanel(metrics: nextMetrics)
        }

        positionPanel(metrics: nextMetrics)
        panel?.orderFrontRegardless()
    }

    func hide() {
        panel?.orderOut(nil)
    }

    func refreshVisibility() {
        model.isMonitoring ? show() : hide()
    }

    private func makePanel(metrics: IslandOverlayMetrics) -> NSPanel {
        let size = metrics.panelFrame.size
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.level = .statusBar
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.hidesOnDeactivate = false

        let hostingView = NSHostingView(rootView: IslandRippleView(
            model: model,
            islandFrame: metrics.islandFrameInPanel,
            usesDetectedNotch: metrics.usesDetectedNotch,
            leftCornerRadius: metrics.cornerRadius,
            rightCornerRadius: metrics.rightCornerRadius
        ))
        hostingView.frame = NSRect(origin: .zero, size: size)
        hostingView.autoresizingMask = [.width, .height]
        panel.contentView = hostingView

        return panel
    }

    private func positionPanel(metrics: IslandOverlayMetrics) {
        panel?.setFrame(metrics.panelFrame, display: true)
    }

    private func installClickMonitors() {
        localClickMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            self?.triggerFeedbackIfNeeded(at: NSEvent.mouseLocation)
            return event
        }

        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] _ in
            Task { @MainActor in
                self?.triggerFeedbackIfNeeded(at: NSEvent.mouseLocation)
            }
        }
    }

    private func triggerFeedbackIfNeeded(at screenPoint: CGPoint) {
        guard model.isMonitoring, let metrics else { return }
        let hitFrame = metrics.islandHitFrameInScreen

        guard hitFrame.contains(screenPoint) else { return }
        model.triggerIslandFeedback()
        notifier.notifyIslandClick(loadStage: model.loadStage)
    }
}
