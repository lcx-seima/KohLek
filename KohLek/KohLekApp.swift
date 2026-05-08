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
            Button(controller.isMonitoring ? "停止监测" : "开始监测") {
                controller.toggleMonitoring()
            }

            Divider()

            Button("退出 KohLek") {
                NSApp.terminate(nil)
            }
        } label: {
            Image("StatusBarIcon")
                .renderingMode(.template)
        }
        .menuBarExtraStyle(.menu)
    }
}
