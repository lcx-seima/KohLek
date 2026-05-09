import Foundation
import Testing
@testable import KohLek

struct IslandOverlayMetricsTests {
    @Test func derivesNotchSizeAndPositionFromAuxiliaryTopAreas() {
        let metrics = IslandOverlayMetrics.metrics(
            screenFrame: CGRect(x: 0, y: 0, width: 1512, height: 982),
            auxiliaryTopLeftArea: CGRect(x: 0, y: 944, width: 675, height: 38),
            auxiliaryTopRightArea: CGRect(x: 837, y: 944, width: 675, height: 38)
        )

        #expect(metrics.usesDetectedNotch)
        #expect(metrics.islandFrameInPanel == CGRect(x: 48, y: 0, width: 162, height: 38))
        #expect(metrics.panelFrame == CGRect(x: 627, y: 894, width: 258, height: 88))
        #expect(metrics.islandHitFrameInScreen == CGRect(x: 675, y: 944, width: 162, height: 38))
        #expect(abs(metrics.cornerRadius - 12.16) < 0.001)
        #expect(abs(metrics.rightCornerRadius - 12.16) < 0.001)
    }

    @Test func fallsBackToCenteredIslandWhenNoNotchAreasExist() {
        let metrics = IslandOverlayMetrics.metrics(
            screenFrame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            auxiliaryTopLeftArea: .zero,
            auxiliaryTopRightArea: .zero
        )

        #expect(!metrics.usesDetectedNotch)
        #expect(metrics.islandFrameInPanel.size == IslandOverlayMetrics.fallbackIslandSize)
        #expect(metrics.panelFrame.midX == 720)
        #expect(metrics.islandHitFrameInScreen == CGRect(x: 657, y: 861, width: 126, height: 37))
        #expect(metrics.cornerRadius == 18.5)
        #expect(metrics.rightCornerRadius == 18.5)
    }
}
