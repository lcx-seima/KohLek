import AppKit
import SwiftUI
import UserNotifications

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        UNUserNotificationCenter.current().delegate = self
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list]
    }
}

@main
struct KohLekApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var controller = ApplicationController()

    var body: some Scene {
        MenuBarExtra {
            StatusBarMenuView(controller: controller)
        } label: {
            Image("StatusBarIcon")
                .renderingMode(.template)
        }
        .menuBarExtraStyle(.window)
    }
}

private struct StatusBarMenuView: View {
    @ObservedObject private var controller: ApplicationController
    @ObservedObject private var model: AppModel

    init(controller: ApplicationController) {
        _controller = ObservedObject(wrappedValue: controller)
        _model = ObservedObject(wrappedValue: controller.model)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button(controller.isMonitoring ? "停止监测" : "开始监测") {
                controller.toggleMonitoring()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Text("CPU 动画主题色")
                    .font(.headline)

                stageColorButton("低负载", stage: .low)
                stageColorButton("中负载", stage: .medium)
                stageColorButton("高负载", stage: .high)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Glow 速度")
                    Spacer()
                    Text(String(format: "%.2fx", model.animationTheme.glowSpeedMultiplier))
                }
                .font(.subheadline)

                Slider(
                    value: Binding(
                        get: { model.animationTheme.glowSpeedMultiplier },
                        set: { model.setGlowSpeedMultiplier($0) }
                    ),
                    in: CPUAnimationTheme.minimumGlowSpeedMultiplier...CPUAnimationTheme.maximumGlowSpeedMultiplier
                )
            }

            HStack {
                Button("恢复默认") {
                    model.resetAnimationTheme()
                }

                Spacer()

                Button("退出 KohLek") {
                    NSApp.terminate(nil)
                }
            }
        }
        .padding(16)
        .frame(width: 260)
    }

    private func stageColorButton(_ title: String, stage: LoadStage) -> some View {
        let themeColor = model.animationTheme.color(for: stage)

        return Button {
            StatusBarColorPanel.shared.show(initialColor: themeColor.nsColor) { color in
                model.setThemeColor(color, for: stage)
            }
        } label: {
            HStack(spacing: 10) {
                Text(title)
                Spacer()
                Text(themeColor.hexString)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                RoundedRectangle(cornerRadius: 4)
                    .fill(themeColor.color)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(.secondary.opacity(0.35), lineWidth: 1)
                    )
                    .frame(width: 28, height: 18)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

@MainActor
private final class StatusBarColorPanel: NSObject {
    static let shared = StatusBarColorPanel()

    private var onChange: ((ThemeColor) -> Void)?
    private var colorChangeObserver: NSObjectProtocol?

    func show(initialColor: NSColor, onChange: @escaping (ThemeColor) -> Void) {
        self.onChange = onChange

        let panel = NSColorPanel.shared
        panel.showsAlpha = false
        panel.isContinuous = true
        panel.color = initialColor

        if colorChangeObserver == nil {
            colorChangeObserver = NotificationCenter.default.addObserver(
                forName: NSColorPanel.colorDidChangeNotification,
                object: panel,
                queue: .main
            ) { [weak self] notification in
                guard let panel = notification.object as? NSColorPanel else { return }
                Task { @MainActor [weak self] in
                    self?.colorDidChange(panel)
                }
            }
        }

        NSApp.activate(ignoringOtherApps: true)
        panel.orderFrontRegardless()
    }

    private func colorDidChange(_ sender: NSColorPanel) {
        guard let color = sender.color.usingColorSpace(.sRGB) else { return }

        onChange?(ThemeColor(
            red: Double(color.redComponent),
            green: Double(color.greenComponent),
            blue: Double(color.blueComponent)
        ))
    }
}
