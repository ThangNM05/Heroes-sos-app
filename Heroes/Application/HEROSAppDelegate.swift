import UIKit
import UserNotifications
import FirebaseCore
import FirebaseMessaging

final class HEROSAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        if FirebaseApp.app() == nil,
           Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
        }
        if FirebaseApp.app() != nil { Messaging.messaging().delegate = self }
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        guard FirebaseApp.app() != nil else { return }
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        #if DEBUG
        print("Push registration failed: \(error.localizedDescription)")
        #endif
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken, !fcmToken.isEmpty else { return }
        NotificationCenter.default.post(
            name: .fcmTokenDidRefresh,
            object: nil,
            userInfo: ["token": fcmToken]
        )
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        postSOSPush(notification.request.content.userInfo)
        completionHandler([.banner, .list, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        postSOSPush(response.notification.request.content.userInfo, opened: true)
        completionHandler()
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        postSOSPush(userInfo)
        completionHandler(.newData)
    }

    private func postSOSPush(_ payload: [AnyHashable: Any], opened: Bool = false) {
        guard let type = payload["type"] as? String, type.hasPrefix("SOS_") else { return }
        if opened, type == "SOS_CHAT_MESSAGE", let chatId = payload["chatId"] as? String {
            Task { @MainActor in SOSChatPushRouter.shared.pendingChatId = chatId }
        }
        NotificationCenter.default.post(
            name: .sosPushReceived,
            object: nil,
            userInfo: ["type": type, "sosId": payload["sosId"] as? String ?? "",
                       "chatId": payload["chatId"] as? String ?? "",
                       "messageId": payload["messageId"] as? String ?? "", "opened": opened]
        )
    }
}

enum PushNotificationCoordinator {
    @MainActor
    static func requestAuthorization() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .badge, .sound])
        }
        let updatedSettings = await center.notificationSettings()
        if updatedSettings.authorizationStatus == .authorized || updatedSettings.authorizationStatus == .provisional {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}
