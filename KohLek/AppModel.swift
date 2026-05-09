import AppKit
import Combine
import Foundation
import SwiftUI

struct ThemeColor: Codable, Equatable {
    let red: Double
    let green: Double
    let blue: Double

    init(red: Double, green: Double, blue: Double) {
        self.red = Self.clampComponent(red)
        self.green = Self.clampComponent(green)
        self.blue = Self.clampComponent(blue)
    }

    var color: Color {
        Color(red: red, green: green, blue: blue)
    }

    var nsColor: NSColor {
        NSColor(calibratedRed: red, green: green, blue: blue, alpha: 1)
    }

    var hexString: String {
        let red = Int((red * 255).rounded())
        let green = Int((green * 255).rounded())
        let blue = Int((blue * 255).rounded())

        return String(format: "#%02X%02X%02X", red, green, blue)
    }

    func adjusted(saturationMultiplier: Double, brightnessMultiplier: Double) -> ThemeColor {
        let nsColor = NSColor(calibratedRed: red, green: green, blue: blue, alpha: 1)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        nsColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        let adjustedColor = NSColor(
            hue: hue,
            saturation: min(max(saturation * CGFloat(saturationMultiplier), 0), 1),
            brightness: min(max(brightness * CGFloat(brightnessMultiplier), 0), 1),
            alpha: alpha
        )

        return ThemeColor(
            red: Double(adjustedColor.redComponent),
            green: Double(adjustedColor.greenComponent),
            blue: Double(adjustedColor.blueComponent)
        )
    }

    static func from(color: Color) -> ThemeColor? {
        guard let converted = NSColor(color).usingColorSpace(.sRGB) else { return nil }

        return ThemeColor(
            red: Double(converted.redComponent),
            green: Double(converted.greenComponent),
            blue: Double(converted.blueComponent)
        )
    }

    private static func clampComponent(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}

struct CPUAnimationTheme: Codable, Equatable {
    static let minimumGlowSpeedMultiplier = 0.25
    static let maximumGlowSpeedMultiplier = 2.0

    static let defaults = CPUAnimationTheme(
        lowColor: ThemeColor(red: 0.56, green: 0.86, blue: 1.0),
        mediumColor: ThemeColor(red: 1.0, green: 0.74, blue: 0.28),
        highColor: ThemeColor(red: 1.0, green: 0.42, blue: 0.34),
        glowSpeedMultiplier: 1.0
    )

    var lowColor: ThemeColor
    var mediumColor: ThemeColor
    var highColor: ThemeColor
    var glowSpeedMultiplier: Double

    init(
        lowColor: ThemeColor = CPUAnimationTheme.defaults.lowColor,
        mediumColor: ThemeColor = CPUAnimationTheme.defaults.mediumColor,
        highColor: ThemeColor = CPUAnimationTheme.defaults.highColor,
        glowSpeedMultiplier: Double = CPUAnimationTheme.defaults.glowSpeedMultiplier
    ) {
        self.lowColor = lowColor
        self.mediumColor = mediumColor
        self.highColor = highColor
        self.glowSpeedMultiplier = Self.clampGlowSpeedMultiplier(glowSpeedMultiplier)
    }

    func color(for stage: LoadStage) -> ThemeColor {
        switch stage {
        case .low:
            return lowColor
        case .medium:
            return mediumColor
        case .high:
            return highColor
        }
    }

    func settingColor(_ color: ThemeColor, for stage: LoadStage) -> CPUAnimationTheme {
        var theme = self

        switch stage {
        case .low:
            theme.lowColor = color
        case .medium:
            theme.mediumColor = color
        case .high:
            theme.highColor = color
        }

        return theme
    }

    func settingGlowSpeedMultiplier(_ multiplier: Double) -> CPUAnimationTheme {
        CPUAnimationTheme(
            lowColor: lowColor,
            mediumColor: mediumColor,
            highColor: highColor,
            glowSpeedMultiplier: multiplier
        )
    }

    private static func clampGlowSpeedMultiplier(_ value: Double) -> Double {
        min(max(value, minimumGlowSpeedMultiplier), maximumGlowSpeedMultiplier)
    }
}

private final class CPUAnimationThemeStore {
    private let userDefaults: UserDefaults
    private let key = "cpuAnimationTheme"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func load() -> CPUAnimationTheme {
        guard
            let data = userDefaults.data(forKey: key),
            let theme = try? JSONDecoder().decode(CPUAnimationTheme.self, from: data)
        else {
            return .defaults
        }

        return CPUAnimationTheme(
            lowColor: theme.lowColor,
            mediumColor: theme.mediumColor,
            highColor: theme.highColor,
            glowSpeedMultiplier: theme.glowSpeedMultiplier
        )
    }

    func save(_ theme: CPUAnimationTheme) {
        guard let data = try? JSONEncoder().encode(theme) else { return }
        userDefaults.set(data, forKey: key)
    }
}

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var isMonitoring = true
    @Published private(set) var smoothedLoad = 0.0
    @Published private(set) var loadStage: LoadStage = .low
    @Published private(set) var islandFeedbackStart: TimeInterval?
    @Published private(set) var animationTheme: CPUAnimationTheme

    private let cpuMonitor = CPUMonitor()
    private let themeStore: CPUAnimationThemeStore

    init() {
        let themeStore = CPUAnimationThemeStore()
        self.themeStore = themeStore
        animationTheme = themeStore.load()
    }

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

    func setThemeColor(_ color: Color, for stage: LoadStage) {
        guard let themeColor = ThemeColor.from(color: color) else { return }
        setThemeColor(themeColor, for: stage)
    }

    func setThemeColor(_ themeColor: ThemeColor, for stage: LoadStage) {
        animationTheme = animationTheme.settingColor(themeColor, for: stage)
        themeStore.save(animationTheme)
    }

    func setGlowSpeedMultiplier(_ multiplier: Double) {
        animationTheme = animationTheme.settingGlowSpeedMultiplier(multiplier)
        themeStore.save(animationTheme)
    }

    func resetAnimationTheme() {
        animationTheme = .defaults
        themeStore.save(animationTheme)
    }
}
