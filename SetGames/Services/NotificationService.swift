import Foundation
import UserNotifications
import SwiftUI

public class NotificationService: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    public static let shared = NotificationService()
    
    @Published public var latestToast: AppNotification?
    @Published public var showToast: Bool = false
    @Published public var apnsDeviceToken: String?
    
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    public func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Notification authorization granted.")
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else if let error = error {
                print("⚠️ Notification auth error: \(error.localizedDescription)")
            }
        }
    }
    
    /// Keep app process alive for up to ~30s when user backgrounds the app or locks screen to catch incoming chat
    public func beginBackgroundKeepAlive() {
        endBackgroundKeepAlive()
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "SetGamesBackgroundKeepAlive") { [weak self] in
            self?.endBackgroundKeepAlive()
        }
        print("🕒 Began background task with id: \(backgroundTaskID)")
    }
    
    public func endBackgroundKeepAlive() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
            print("🛑 Ended background task")
        }
    }
    
    /// Schedules an iOS system alert (shows on Lock Screen & Apple Watch)
    public func sendSystemNotification(title: String, body: String, timeInterval: TimeInterval = 0.2) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(0.1, timeInterval), repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error delivering notification: \(error.localizedDescription)")
            }
        }
    }
    
    /// Trigger an in-app visual toast banner
    public func triggerInAppToast(_ notification: AppNotification) {
        DispatchQueue.main.async {
            self.latestToast = notification
            withAnimation(.spring()) {
                self.showToast = true
            }
            
            // Auto hide after 4 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                withAnimation(.easeOut) {
                    self.showToast = false
                }
            }
        }
    }
    
    // Display banner even when app is in foreground
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge, .list])
    }
}
