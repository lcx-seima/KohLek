import AppKit

struct IslandOverlayMetrics: Equatable {
    static let fallbackIslandSize = CGSize(width: 126, height: 37)
    static let horizontalWavePadding: CGFloat = 48
    static let bottomWavePadding: CGFloat = 50

    let islandFrameInPanel: CGRect
    let panelFrame: CGRect
    let usesDetectedNotch: Bool
    let cornerRadius: CGFloat
    let rightCornerRadius: CGFloat

    var islandHitFrameInScreen: CGRect {
        CGRect(
            x: panelFrame.minX + islandFrameInPanel.minX,
            y: panelFrame.maxY - islandFrameInPanel.maxY,
            width: islandFrameInPanel.width,
            height: islandFrameInPanel.height
        )
    }

    static func metrics(
        screenFrame: CGRect,
        auxiliaryTopLeftArea: CGRect,
        auxiliaryTopRightArea: CGRect
    ) -> IslandOverlayMetrics {
        if let notchRect = detectedNotchRect(
            screenFrame: screenFrame,
            auxiliaryTopLeftArea: auxiliaryTopLeftArea,
            auxiliaryTopRightArea: auxiliaryTopRightArea
        ) {
            let panelWidth = notchRect.width + horizontalWavePadding * 2
            let panelHeight = notchRect.height + bottomWavePadding
            let panelFrame = CGRect(
                x: notchRect.midX - panelWidth / 2,
                y: screenFrame.maxY - panelHeight,
                width: panelWidth,
                height: panelHeight
            )
            let islandFrame = CGRect(
                x: horizontalWavePadding,
                y: 0,
                width: notchRect.width,
                height: notchRect.height
            )

            let cornerRadius = min(notchRect.height * 0.42, notchRect.width * 0.18)

            return IslandOverlayMetrics(
                islandFrameInPanel: islandFrame,
                panelFrame: panelFrame,
                usesDetectedNotch: true,
                cornerRadius: cornerRadius,
                rightCornerRadius: cornerRadius
            )
        }

        let panelWidth = fallbackIslandSize.width + horizontalWavePadding * 2
        let panelHeight = fallbackIslandSize.height + bottomWavePadding
        let panelFrame = CGRect(
            x: screenFrame.midX - panelWidth / 2,
            y: screenFrame.maxY - panelHeight + 5,
            width: panelWidth,
            height: panelHeight
        )
        let islandFrame = CGRect(
            x: horizontalWavePadding,
            y: 7,
            width: fallbackIslandSize.width,
            height: fallbackIslandSize.height
        )

        return IslandOverlayMetrics(
            islandFrameInPanel: islandFrame,
            panelFrame: panelFrame,
            usesDetectedNotch: false,
            cornerRadius: fallbackIslandSize.height / 2,
            rightCornerRadius: fallbackIslandSize.height / 2
        )
    }

    private static func detectedNotchRect(
        screenFrame: CGRect,
        auxiliaryTopLeftArea: CGRect,
        auxiliaryTopRightArea: CGRect
    ) -> CGRect? {
        guard !auxiliaryTopLeftArea.isEmpty, !auxiliaryTopRightArea.isEmpty else {
            return nil
        }

        let notchWidth = auxiliaryTopRightArea.minX - auxiliaryTopLeftArea.maxX
        let notchHeight = max(auxiliaryTopLeftArea.height, auxiliaryTopRightArea.height)
        guard notchWidth > 40, notchHeight > 10 else {
            return nil
        }

        return CGRect(
            x: auxiliaryTopLeftArea.maxX,
            y: screenFrame.maxY - notchHeight,
            width: notchWidth,
            height: notchHeight
        )
    }
}
