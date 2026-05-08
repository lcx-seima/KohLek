import Foundation
import UserNotifications

@MainActor
final class IslandClickNotifier {
    private var didRequestAuthorization = false

    func notifyIslandClick(loadStage: LoadStage) {
        Task {
            guard await ensureAuthorization() else { return }

            let content = UNMutableNotificationContent()
            content.title = "KohLek"
            content.body = notificationBody(loadStage: loadStage)
            content.sound = nil

            let request = UNNotificationRequest(
                identifier: "KohLek-island-click-\(UUID().uuidString)",
                content: content,
                trigger: nil
            )

            try? await UNUserNotificationCenter.current().add(request)
        }
    }

    private func ensureAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            guard !didRequestAuthorization else { return false }
            didRequestAuthorization = true
            return (try? await center.requestAuthorization(options: [.alert])) ?? false
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    private func notificationBody(loadStage: LoadStage) -> String {
        switch loadStage {
        case .low:
            return "Notch 已响应，当前负载平稳。"
        case .medium:
            return "Notch 已响应，当前负载升温。"
        case .high:
            return "Notch 已响应，当前负载较高。"
        }
    }
}
