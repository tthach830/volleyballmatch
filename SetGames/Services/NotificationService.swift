import Foundation
import UserNotifications
import SwiftUI
import CryptoKit

public class NotificationService: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    public static let shared = NotificationService()
    
    @Published public var latestToast: AppNotification?
    @Published public var showToast: Bool = false
    @Published public var apnsDeviceToken: String?
    
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    
    // MARK: - APNs Direct Push Configuration ($0 Serverless Architecture)
    private let apnsKeyId = "C84ZV9L33Y"
    private let apnsTeamId = "Z4WJ2G9N79"
    private let apnsBundleId = "com.peterthach.SetGames"
    private let apnsPrivateKeyPEM = """
    -----BEGIN PRIVATE KEY-----
    MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQgwdeID2PhucMZu9fs
    QeuicScCZCnQVTqPAEsTumHjnR2gCgYIKoZIzj0DAQehRANCAASQZItT7b6CwNDA
    jalMiCEWBEHDilj/g0xnhBe+BUPHN6ZnYq3EKYX7nVPBOfzz70ZzAPmTv2QXxkjA
    Iz4gxJw9
    -----END PRIVATE KEY-----
    """
    
    private var cachedJWT: String?
    private var cachedJWTDate: Date?
    private let jwtLock = NSLock()
    
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
    
    // MARK: - Push Deduplication Cache
    private static var recentPushes = [String: Date]()
    private static let pushLock = NSLock()
    
    // When the app is actively in the foreground, suppress system drop-down banners (.banner, .list)
    // because the app displays its own clean in-app toast view (NotificationToastView).
    // System banners, sound, and list display are handled automatically by iOS when the app
    // is in the background, locked, or killed.
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.badge])
    }
    
    // MARK: - Direct APNs Push Implementation ($0 Cost, Zero Backend)
    
    private func base64Url(_ data: Data) -> String {
        return data.base64EncodedString()
            .replacingOccurrences(of: "=", with: "")
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
    }
    
    private func getValidJWT() throws -> String {
        jwtLock.lock()
        defer { jwtLock.unlock() }
        
        if let jwt = cachedJWT, let date = cachedJWTDate, Date().timeIntervalSince(date) < 3000 {
            return jwt
        }
        
        let headerObj = ["alg": "ES256", "kid": apnsKeyId]
        let headerData = try JSONSerialization.data(withJSONObject: headerObj)
        let headerB64 = base64Url(headerData)
        
        let payloadObj: [String: Any] = [
            "iss": apnsTeamId,
            "iat": Int(Date().timeIntervalSince1970)
        ]
        let payloadData = try JSONSerialization.data(withJSONObject: payloadObj)
        let payloadB64 = base64Url(payloadData)
        
        let message = "\(headerB64).\(payloadB64)"
        guard let messageData = message.data(using: .utf8) else {
            throw NSError(domain: "APNs", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode JWT message"])
        }
        
        let privateKey = try P256.Signing.PrivateKey(pemRepresentation: apnsPrivateKeyPEM)
        let signature = try privateKey.signature(for: messageData)
        let signatureB64 = base64Url(signature.rawRepresentation)
        
        let newJWT = "\(message).\(signatureB64)"
        cachedJWT = newJWT
        cachedJWTDate = Date()
        return newJWT
    }
    
    /// Dispatches a push notification directly to Apple's APNs servers.
    /// Wakes the recipient's phone with sound and banner even when the app is terminated or screen is locked.
    /// Runs at $0 cost with zero external server dependencies.
    public func sendDirectRemotePush(
        to rawDeviceToken: String,
        title: String,
        body: String,
        gameId: UUID? = nil
    ) {
        let cleanToken = rawDeviceToken
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "<", with: "")
            .replacingOccurrences(of: ">", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            
        guard !cleanToken.isEmpty else { return }
        
        let dedupKey = "\(cleanToken):::\(title):::\(body)"
        Self.pushLock.lock()
        if let lastSent = Self.recentPushes[dedupKey], Date().timeIntervalSince(lastSent) < 15.0 {
            Self.pushLock.unlock()
            print("ℹ️ [APNs] Debounced duplicate push to \(cleanToken.prefix(8))... within 15s")
            return
        }
        Self.recentPushes[dedupKey] = Date()
        if Self.recentPushes.count > 100 {
            let now = Date()
            Self.recentPushes = Self.recentPushes.filter { now.timeIntervalSince($0.value) < 60 }
        }
        Self.pushLock.unlock()
        
        var bgTask: UIBackgroundTaskIdentifier = .invalid
        bgTask = UIApplication.shared.beginBackgroundTask(withName: "APNsDirectDispatch") {
            if bgTask != .invalid {
                UIApplication.shared.endBackgroundTask(bgTask)
                bgTask = .invalid
            }
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                if bgTask != .invalid {
                    UIApplication.shared.endBackgroundTask(bgTask)
                    bgTask = .invalid
                }
                return
            }
            do {
                let jwt = try self.getValidJWT()
                self.performAPNsRequest(
                    deviceToken: cleanToken,
                    title: title,
                    body: body,
                    gameId: gameId,
                    jwt: jwt,
                    useSandbox: true,
                    bgTaskId: bgTask
                )
            } catch {
                print("⚠️ [APNs] Failed to sign JWT: \(error.localizedDescription)")
                if bgTask != .invalid {
                    UIApplication.shared.endBackgroundTask(bgTask)
                    bgTask = .invalid
                }
            }
        }
    }
    
    private func performAPNsRequest(
        deviceToken: String,
        title: String,
        body: String,
        gameId: UUID?,
        jwt: String,
        useSandbox: Bool,
        bgTaskId: UIBackgroundTaskIdentifier = .invalid
    ) {
        let host = useSandbox ? "api.sandbox.push.apple.com" : "api.push.apple.com"
        guard let url = URL(string: "https://\(host)/3/device/\(deviceToken)") else {
            if bgTaskId != .invalid {
                UIApplication.shared.endBackgroundTask(bgTaskId)
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("bearer \(jwt)", forHTTPHeaderField: "authorization")
        request.setValue(apnsBundleId, forHTTPHeaderField: "apns-topic")
        request.setValue("alert", forHTTPHeaderField: "apns-push-type")
        request.setValue("10", forHTTPHeaderField: "apns-priority")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var aps: [String: Any] = [
            "alert": [
                "title": title,
                "body": body
            ],
            "sound": "default",
            "badge": 1
        ]
        
        var rootPayload: [String: Any] = ["aps": aps]
        if let gameId = gameId {
            rootPayload["gameId"] = gameId.uuidString
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: rootPayload)
        } catch {
            print("⚠️ [APNs] JSON serialization error: \(error.localizedDescription)")
            if bgTaskId != .invalid {
                UIApplication.shared.endBackgroundTask(bgTaskId)
            }
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            defer {
                if bgTaskId != .invalid {
                    UIApplication.shared.endBackgroundTask(bgTaskId)
                }
            }
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    print("✅ [APNs] Remote push successfully sent to (\(deviceToken.prefix(8))...) via \(host)!")
                } else if httpResponse.statusCode == 400 && useSandbox {
                    // In TestFlight or App Store builds, retry with production gateway
                    print("ℹ️ [APNs] Sandbox returned 400 BadDeviceToken. Retrying production gateway...")
                    self?.performAPNsRequest(
                        deviceToken: deviceToken,
                        title: title,
                        body: body,
                        gameId: gameId,
                        jwt: jwt,
                        useSandbox: false,
                        bgTaskId: bgTaskId
                    )
                } else {
                    var errorDetails = ""
                    if let data = data, let str = String(data: data, encoding: .utf8) {
                        errorDetails = str
                    }
                    print("⚠️ [APNs] Response \(httpResponse.statusCode) from \(host): \(errorDetails)")
                }
            } else if let error = error {
                print("⚠️ [APNs] Connection error: \(error.localizedDescription)")
            }
        }
        task.resume()
    }
    
    /// Dispatches an immediate test push to the local device and keeps the task alive even if app is closed/killed
    public func sendTestPushToSelf() {
        guard let token = apnsDeviceToken, !token.isEmpty else {
            print("⚠️ [APNs] Cannot send test push: no device token registered yet.")
            return
        }
        print("📲 Dispatching test remote push to Apple APNs for \(token.prefix(8))...")
        sendDirectRemotePush(
            to: token,
            title: "🏐 Volleyball Match Alert",
            body: "Lock screen push working! Delivered via Apple APNs even if app is killed."
        )
    }
}
