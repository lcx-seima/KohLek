import SwiftUI

struct IslandRippleView: View {
    @ObservedObject var model: AppModel
    let islandFrame: CGRect
    let usesDetectedNotch: Bool
    let leftCornerRadius: CGFloat
    let rightCornerRadius: CGFloat

    init(
        model: AppModel,
        islandFrame: CGRect = CGRect(origin: CGPoint(x: 48, y: 7), size: IslandOverlayMetrics.fallbackIslandSize),
        usesDetectedNotch: Bool = false,
        leftCornerRadius: CGFloat = IslandOverlayMetrics.fallbackIslandSize.height / 2,
        rightCornerRadius: CGFloat = IslandOverlayMetrics.fallbackIslandSize.height / 2
    ) {
        self.model = model
        self.islandFrame = islandFrame
        self.usesDetectedNotch = usesDetectedNotch
        self.leftCornerRadius = leftCornerRadius
        self.rightCornerRadius = rightCornerRadius
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 45.0)) { timeline in
            Canvas { context, size in
                draw(context: context, size: size, date: timeline.date)
            }
        }
        .allowsHitTesting(false)
    }

    private func draw(context: GraphicsContext, size: CGSize, date: Date) {
        let style = RippleStyle(stage: model.loadStage, theme: model.animationTheme)
        let islandRect = islandFrame
        let time = date.timeIntervalSinceReferenceDate

        for layer in 0..<style.layerCount {
            let progress = style.progress(time: time, layer: layer)
            let expansion = style.expansion * progress
            let alpha = style.waveOpacity * pow(1.0 - progress, 1.35)
            let rect = expandedRippleRect(base: islandRect, expansion: expansion)
            let leftRadius = leftCornerRadius + expansion * (usesDetectedNotch ? 0.28 : 0.48)
            let rightRadius = rightCornerRadius + expansion * (usesDetectedNotch ? 0.28 : 0.48)
            let path = islandPath(in: rect, leftCornerRadius: leftRadius, rightCornerRadius: rightRadius)

            context.stroke(
                path,
                with: .color(style.waveColor.opacity(alpha)),
                lineWidth: style.waveLineWidth * (1.0 - progress * 0.28)
            )
        }

        drawNeonBorder(context: context, style: style, islandRect: islandRect, time: time)

        drawFeedbackPulse(context: context, style: style, islandRect: islandRect, time: time)

        let innerRect = usesDetectedNotch
            ? islandRect.insetBy(dx: 1.25, dy: 0).offsetBy(dx: 0, dy: 1.25)
            : islandRect.insetBy(dx: 1.25, dy: 1.25)
        context.stroke(
            islandPath(
                in: innerRect,
                leftCornerRadius: max(leftCornerRadius - 1.2, 2),
                rightCornerRadius: max(rightCornerRadius - 1.2, 2)
            ),
            with: .color(style.innerHighlightColor.opacity(style.innerHighlightOpacity)),
            lineWidth: 0.9
        )
    }

    private func drawNeonBorder(
        context: GraphicsContext,
        style: RippleStyle,
        islandRect: CGRect,
        time: TimeInterval
    ) {
        let borderPath = islandPath(in: islandRect, leftCornerRadius: leftCornerRadius, rightCornerRadius: rightCornerRadius)

        context.stroke(
            borderPath,
            with: .linearGradient(
                Gradient(colors: [
                    style.borderPrimary.opacity(0.74),
                    style.borderSecondary.opacity(0.52),
                    style.borderPrimary.opacity(0.74)
                ]),
                startPoint: CGPoint(x: islandRect.minX, y: islandRect.minY),
                endPoint: CGPoint(x: islandRect.maxX, y: islandRect.maxY)
            ),
            style: StrokeStyle(lineWidth: 2.05, lineCap: .round, lineJoin: .round)
        )

        let rawPhase = IslandBorderLightAnimation.phase(time: time, duration: style.neonCycle)
        let breathingPhase = IslandBorderLightAnimation.breathingPhase(rawPhase)
        let center = IslandBorderLightAnimation.counterclockwisePhase(clockwisePhase: breathingPhase)
        let ranges = IslandBorderLightAnimation.segmentRanges(center: center, length: style.neonSegmentLength)

        var glowContext = context
        glowContext.addFilter(.shadow(color: style.borderGlow.opacity(0.72), radius: 6, x: 0, y: 0))
        for range in ranges {
            let segment = borderPath.trimmedPath(from: range.start, to: range.end)
            glowContext.stroke(
                segment,
                with: .color(style.borderGlow.opacity(0.58)),
                style: StrokeStyle(lineWidth: 4.8, lineCap: .round, lineJoin: .round)
            )
        }

        for range in ranges {
            let segment = borderPath.trimmedPath(from: range.start, to: range.end)
            context.stroke(
                segment,
                with: .color(style.borderPrimary),
                style: StrokeStyle(lineWidth: 2.9, lineCap: .round, lineJoin: .round)
            )
            context.stroke(
                segment,
                with: .color(style.innerHighlightColor.opacity(0.72)),
                style: StrokeStyle(lineWidth: 1.05, lineCap: .round, lineJoin: .round)
            )
        }
    }

    private func drawFeedbackPulse(
        context: GraphicsContext,
        style: RippleStyle,
        islandRect: CGRect,
        time: TimeInterval
    ) {
        guard let start = model.islandFeedbackStart else { return }

        let elapsed = time - start
        guard elapsed >= 0, elapsed <= 0.58 else { return }

        let progress = elapsed / 0.58
        let easeOut = 1 - pow(1 - progress, 3)
        let press = max(0, 1 - progress / 0.18)
        let expansion = -2.2 * press + 13 * easeOut
        let alpha = 0.78 * pow(1 - progress, 1.55)
        let rect = expandedRippleRect(base: islandRect, expansion: expansion)
        let leftRadius = leftCornerRadius + max(expansion, 0) * (usesDetectedNotch ? 0.26 : 0.44)
        let rightRadius = rightCornerRadius + max(expansion, 0) * (usesDetectedNotch ? 0.26 : 0.44)
        let path = islandPath(in: rect, leftCornerRadius: leftRadius, rightCornerRadius: rightRadius)

        var pulseContext = context
        pulseContext.addFilter(.shadow(color: style.borderPrimary.opacity(alpha * 0.8), radius: 7, x: 0, y: 0))
        pulseContext.stroke(
            path,
            with: .color(style.borderPrimary.opacity(alpha)),
            lineWidth: 2.6 - progress * 0.8
        )

        if progress < 0.22 {
            context.stroke(
                islandPath(
                    in: islandRect.insetBy(dx: 1.6 * press, dy: usesDetectedNotch ? 0 : 1.2 * press),
                    leftCornerRadius: max(leftCornerRadius - 1.6 * press, 2),
                    rightCornerRadius: max(rightCornerRadius - 1.6 * press, 2)
                ),
                with: .color(style.innerHighlightColor.opacity(0.42 * press)),
                lineWidth: 1.1
            )
        }
    }

    private func expandedRippleRect(base: CGRect, expansion: CGFloat) -> CGRect {
        if usesDetectedNotch {
            return CGRect(
                x: base.minX - expansion,
                y: base.minY,
                width: base.width + expansion * 2,
                height: base.height + expansion * 0.72
            )
        }

        return base.insetBy(dx: -expansion, dy: -expansion * 0.58)
    }

    private func islandPath(in rect: CGRect, leftCornerRadius: CGFloat, rightCornerRadius: CGFloat) -> Path {
        if usesDetectedNotch {
            return notchPath(in: rect, leftCornerRadius: leftCornerRadius, rightCornerRadius: rightCornerRadius)
        }

        let cornerRadius = min(leftCornerRadius, rightCornerRadius)
        return RoundedRectangle(cornerRadius: min(cornerRadius, rect.height / 2), style: .continuous).path(in: rect)
    }

    private func notchPath(in rect: CGRect, leftCornerRadius: CGFloat, rightCornerRadius: CGFloat) -> Path {
        let leftRadius = min(leftCornerRadius, rect.width / 2, rect.height)
        let rightRadius = min(rightCornerRadius, rect.width / 2, rect.height)
        let kappa: CGFloat = 0.5522847498
        let leftControl = leftRadius * kappa
        let rightControl = rightRadius * kappa

        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - rightRadius))
        path.addCurve(
            to: CGPoint(x: rect.maxX - rightRadius, y: rect.maxY),
            control1: CGPoint(x: rect.maxX, y: rect.maxY - rightRadius + rightControl),
            control2: CGPoint(x: rect.maxX - rightRadius + rightControl, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX + leftRadius, y: rect.maxY))
        path.addCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - leftRadius),
            control1: CGPoint(x: rect.minX + leftRadius - leftControl, y: rect.maxY),
            control2: CGPoint(x: rect.minX, y: rect.maxY - leftRadius + leftControl)
        )
        path.closeSubpath()
        return path
    }
}

struct RippleStyle {
    let borderPrimary: Color
    let borderSecondary: Color
    let borderGlow: Color
    let waveColor: Color
    let innerHighlightColor: Color
    let cycle: Double
    let expansion: Double
    let waveOpacity: Double
    let waveLineWidth: Double
    let layerCount: Int
    let idleGap: Double
    let innerHighlightOpacity: Double
    let neonCycle: Double
    let neonSegmentLength: Double

    init(stage: LoadStage, theme: CPUAnimationTheme = .defaults) {
        let themeColor = theme.color(for: stage)
        borderPrimary = themeColor.color
        borderSecondary = themeColor.adjusted(saturationMultiplier: 1.28, brightnessMultiplier: 0.72).color
        borderGlow = themeColor.adjusted(saturationMultiplier: 1.16, brightnessMultiplier: 0.94).color
        waveColor = themeColor.adjusted(saturationMultiplier: 1.08, brightnessMultiplier: 0.9).color
        innerHighlightColor = themeColor.adjusted(saturationMultiplier: 0.22, brightnessMultiplier: 1.12).color

        switch stage {
        case .low:
            cycle = 5.2
            expansion = 18
            waveOpacity = 0.22
            waveLineWidth = 1.05
            layerCount = 2
            idleGap = 2.8
            innerHighlightOpacity = 0.48
            neonCycle = 4.2 / theme.glowSpeedMultiplier
            neonSegmentLength = 0.16
        case .medium:
            cycle = 2.55
            expansion = 24
            waveOpacity = 0.32
            waveLineWidth = 1.35
            layerCount = 3
            idleGap = 0
            innerHighlightOpacity = 0.42
            neonCycle = 3.2 / theme.glowSpeedMultiplier
            neonSegmentLength = 0.15
        case .high:
            cycle = 1.55
            expansion = 31
            waveOpacity = 0.42
            waveLineWidth = 1.6
            layerCount = 4
            idleGap = 0
            innerHighlightOpacity = 0.38
            neonCycle = 2.55 / theme.glowSpeedMultiplier
            neonSegmentLength = 0.14
        }
    }

    func progress(time: TimeInterval, layer: Int) -> Double {
        let offset = (cycle / Double(layerCount)) * Double(layer)
        let total = cycle + idleGap
        let value = (time + offset).truncatingRemainder(dividingBy: total)

        guard value <= cycle else { return 1 }
        return value / cycle
    }
}
