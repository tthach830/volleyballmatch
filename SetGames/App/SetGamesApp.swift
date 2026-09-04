import SwiftUI
import FirebaseCore
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        if let filePath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           let options = FirebaseOptions(contentsOfFile: filePath) {
            FirebaseApp.configure(options: options)
            print("✅ Firebase successfully configured from GoogleService-Info.plist")
        } else {
            print("⚠️ Warning: GoogleService-Info.plist not found in bundle, attempting default configure")
            FirebaseApp.configure()
        }
        
        // Request notification authorization & register for remote notifications
        NotificationService.shared.requestPermission()
        application.registerForRemoteNotifications()
        
        return true
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("📲 Registered for remote notifications with APNs token: \(token)")
        NotificationService.shared.apnsDeviceToken = token
        DataManager.shared.updateDeviceToken(token)
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("⚠️ Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable : Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        print("📩 Received remote notification in background: \(userInfo)")
        completionHandler(.newData)
    }
}

@main
struct SetGamesApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                NotificationService.shared.beginBackgroundKeepAlive()
            } else if newPhase == .active {
                NotificationService.shared.endBackgroundKeepAlive()
            }
        }
    }
}
