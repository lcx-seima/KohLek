import Testing
import SwiftUI
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

struct CPUAnimationThemeTests {
    @Test func defaultsUseCurrentStagePrimaryColors() {
        let theme = CPUAnimationTheme.defaults

        expectColor(theme.color(for: .low), red: 0.56, green: 0.86, blue: 1.0)
        expectColor(theme.color(for: .medium), red: 1.0, green: 0.74, blue: 0.28)
        expectColor(theme.color(for: .high), red: 1.0, green: 0.42, blue: 0.34)
    }

    @Test func clampsGlowSpeedMultiplier() {
        #expect(CPUAnimationTheme(glowSpeedMultiplier: 0.1).glowSpeedMultiplier == 0.25)
        #expect(CPUAnimationTheme(glowSpeedMultiplier: 1.5).glowSpeedMultiplier == 1.5)
        #expect(CPUAnimationTheme(glowSpeedMultiplier: 3.0).glowSpeedMultiplier == 2.0)
    }

    @Test func themeColorFormatsAsHexString() {
        let color = ThemeColor(red: 0.56, green: 0.86, blue: 1.0)

        #expect(color.hexString == "#8FDBFF")
    }

    @Test func rippleStyleScalesNeonCycleByThemeSpeed() {
        let theme = CPUAnimationTheme(glowSpeedMultiplier: 2.0)
        let style = RippleStyle(stage: .medium, theme: theme)

        #expect(abs(style.neonCycle - 1.6) < 0.001)
    }

    @Test func rippleStyleDerivesAnimationColorsFromThemeColor() {
        let theme = CPUAnimationTheme(
            lowColor: ThemeColor(red: 0.12, green: 0.34, blue: 0.56)
        )
        let style = RippleStyle(stage: .low, theme: theme)

        expectColor(style.borderPrimary, red: 0.12, green: 0.34, blue: 0.56)
        #expect(style.borderSecondary != style.borderPrimary)
        #expect(style.borderGlow != style.borderPrimary)
        #expect(style.waveColor != style.borderPrimary)
    }

    private func expectColor(_ color: ThemeColor, red: Double, green: Double, blue: Double) {
        #expect(abs(color.red - red) < 0.001)
        #expect(abs(color.green - green) < 0.001)
        #expect(abs(color.blue - blue) < 0.001)
    }

    private func expectColor(_ color: Color, red: Double, green: Double, blue: Double) {
        let resolved = color.resolve(in: EnvironmentValues())

        #expect(abs(Double(resolved.red) - red) < 0.01)
        #expect(abs(Double(resolved.green) - green) < 0.01)
        #expect(abs(Double(resolved.blue) - blue) < 0.01)
    }
}
