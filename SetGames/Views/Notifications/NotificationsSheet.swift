import SwiftUI

public struct NotificationsSheet: View {
    @ObservedObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    public init(dataManager: DataManager) {
        self.dataManager = dataManager
    }
    
    public var body: some View {
        NavigationStack {
            List {
                Section {
                    Button(action: {
                        NotificationService.shared.sendTestPushToSelf(delay: 3.0)
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "bell.badge.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 20))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Send Test Remote Push (3s)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.primary)
                                Text("Tap, then lock your phone or swipe home to see lock screen banner.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Remote Notifications")
                }
                
                if dataManager.notifications.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary)
                        Text("No notifications yet")
                            .font(.system(size: 15, weight: .bold))
                        Text("You will get notified whenever an auto-match is confirmed or match scores are logged!")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(30)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(dataManager.notifications) { item in
                        HStack(alignment: .top, spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.orange.opacity(0.15))
                                    .frame(width: 36, height: 36)
                                Image(systemName: item.type.icon)
                                    .font(.system(size: 15))
                                    .foregroundColor(.orange)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(item.title)
                                        .font(.system(size: 14, weight: item.isRead ? .medium : .bold))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text(item.timeAgoFormatted)
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                                
                                Text(item.message)
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                if !dataManager.notifications.isEmpty {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Mark All Read") {
                            dataManager.markAllNotificationsRead()
                        }
                        .font(.system(size: 13, weight: .semibold))
                    }
                }
            }
        }
    }
}
