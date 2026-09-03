import SwiftUI

public struct UserSwitcherView: View {
    @ObservedObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    public init(dataManager: DataManager) {
        self.dataManager = dataManager
    }
    
    public var body: some View {
        NavigationStack {
            List {
                Section("Switch to Existing Community Member") {
                    ForEach(dataManager.players) { player in
                        Button {
                            dataManager.switchUser(to: player)
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                PlayerAvatarView(player: player, dimension: 44)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(player.name)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.primary)
                                        
                                        if player.id == dataManager.currentUser?.id {
                                            Text("ACTIVE")
                                                .font(.system(size: 9, weight: .bold))
                                                .padding(.horizontal, 5)
                                                .padding(.vertical, 2)
                                                .background(Color.green.opacity(0.2))
                                                .foregroundColor(.green)
                                                .clipShape(Capsule())
                                        }
                                    }
                                    
                                    HStack(spacing: 8) {
                                        RatingBadge(rating: player.rating, size: .small)
                                        
                                        Text(player.formattedRecord)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.secondary)
                                        
                                        Text("• \(player.uniqueConnectionsCount) Connections")
                                            .font(.system(size: 11))
                                            .foregroundColor(.orange)
                                    }
                                }
                                
                                Spacer()
                                
                                if player.id == dataManager.currentUser?.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.orange)
                                        .font(.system(size: 14, weight: .bold))
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        dataManager.logOut()
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.plus")
                            Text("Create Brand New Account (Log Out)")
                        }
                    }
                }
            }
            .navigationTitle("Select Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}
