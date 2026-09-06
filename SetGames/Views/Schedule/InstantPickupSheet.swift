import SwiftUI

public struct InstantPickupSheet: View {
    @ObservedObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedBeach: String = "Main Beach"
    @State private var showPlayerPickerForSpot: Int? = nil
    
    public var onGameCreated: ((UUID) -> Void)?
    
    public init(dataManager: DataManager, onGameCreated: ((UUID) -> Void)? = nil) {
        self.dataManager = dataManager
        self.onGameCreated = onGameCreated
    }
    
    private var currentQueue: [Player] {
        dataManager.pickupQueue(for: selectedBeach)
    }
    
    private var isCurrentUserInQueue: Bool {
        guard let currentUserId = dataManager.currentUser?.id else { return false }
        return currentQueue.contains(where: { $0.id == currentUserId })
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Top Hero Banner (Matches Reference Design)
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("FASTEST")
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.12))
                                .foregroundColor(.blue)
                                .clipShape(Capsule())
                            
                            Spacer()
                            
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.orange)
                        }
                        
                        Text("Instant Pickup Lobby")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Drop into today's live morning or sunset waves. Fills 4-player lobbies and alerts you once full.")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(18)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    // Beach Selection (Main Beach vs Harbor Beach)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("SELECT BEACH LOCATION")
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                        
                        HStack(spacing: 12) {
                            beachPill(name: "Main Beach", icon: "beach.umbrella.fill")
                            beachPill(name: "Harbor Beach", icon: "sailboat.fill")
                        }
                    }
                    .padding(.horizontal)
                    
                    // Today's Beach Queue Card (Matches Reference Image)
                    VStack(alignment: .leading, spacing: 18) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Today's Beach Queue")
                                    .font(.system(size: 18, weight: .bold))
                                Text("Auto-locks into a game when 4 players join")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("\(currentQueue.count) / 4 Players")
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.blue.opacity(0.12))
                                .foregroundColor(.blue)
                                .clipShape(Capsule())
                        }
                        
                        // Progress Bar
                        ProgressView(value: Double(currentQueue.count), total: 4.0)
                            .tint(.blue)
                        
                        // 4 Interactive Spots (Matches Reference Image)
                        HStack(spacing: 12) {
                            ForEach(0..<4) { index in
                                spotView(index: index)
                            }
                        }
                        .padding(.vertical, 8)
                        
                        // Primary Queue Action Button
                        Button {
                            handleToggleQueue()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: isCurrentUserInQueue ? "xmark" : "bolt.fill")
                                Text(isCurrentUserInQueue ? "Leave Matchmaking Queue" : "Enter Matchmaking Queue")
                            }
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(isCurrentUserInQueue ? Color.red : Color(red: 0.01, green: 0.52, blue: 0.84))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        
                        // Auto-Fill Button for Fast Testing / Community Match
                        Button {
                            handleAutoFill()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "person.3.fill")
                                Text(currentQueue.count == 0 ? "Quick-Fill 4 Players" : "Auto-Fill Remaining Spots")
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(red: 0.01, green: 0.52, blue: 0.84))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.blue.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .padding(18)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                }
                .padding(.vertical, 16)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Instant Pickup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(item: Binding<SelectableSpot?>(
                get: { showPlayerPickerForSpot.map { SelectableSpot(index: $0) } },
                set: { showPlayerPickerForSpot = $0?.index }
            )) { spot in
                playerPickerSheet(for: spot.index)
            }
        }
    }
    
    // MARK: - Beach Pill
    private func beachPill(name: String, icon: String) -> some View {
        let isSelected = selectedBeach == name
        let count = dataManager.pickupQueue(for: name).count
        
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedBeach = name
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                Text(name)
                    .font(.system(size: 14, weight: .bold))
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .black))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.white.opacity(0.3) : Color.blue.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.orange : Color(UIColor.secondarySystemGroupedBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.orange : Color.gray.opacity(0.2), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Spot View (Matches 4 Spots from Reference Image)
    private func spotView(index: Int) -> some View {
        VStack(spacing: 8) {
            if index < currentQueue.count {
                let player = currentQueue[index]
                let isMe = player.id == dataManager.currentUser?.id
                
                Button {
                    // Tap filled spot to remove
                    withAnimation {
                        dataManager.leaveBeachPickupQueue(beach: selectedBeach, playerId: player.id)
                    }
                } label: {
                    ZStack(alignment: .topTrailing) {
                        PlayerAvatarView(player: player, dimension: 50)
                            .shadow(color: Color.black.opacity(0.08), radius: 3, y: 2)
                        
                        Circle()
                            .fill(Color.red)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Image(systemName: "xmark")
                                    .font(.system(size: 8, weight: .black))
                                    .foregroundColor(.white)
                            )
                            .offset(x: 2, y: -2)
                    }
                }
                .buttonStyle(.plain)
                
                Text(isMe ? "You" : player.nickname)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            } else {
                Button {
                    handleSpotTap(index: index)
                } label: {
                    Circle()
                        .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                        .foregroundColor(Color.gray.opacity(0.5))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                        )
                }
                .buttonStyle(.plain)
                
                Text("Spot \(index + 1)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Tap Spot Action
    private func handleSpotTap(index: Int) {
        if !isCurrentUserInQueue, let user = dataManager.currentUser {
            withAnimation {
                if let game = dataManager.joinBeachPickupQueue(beach: selectedBeach, player: user) {
                    navigateToGame(game)
                }
            }
        } else {
            // Already in queue: offer to add another player or open picker
            showPlayerPickerForSpot = index
        }
    }
    
    // MARK: - Toggle Queue Button
    private func handleToggleQueue() {
        guard let user = dataManager.currentUser else { return }
        withAnimation {
            if isCurrentUserInQueue {
                dataManager.leaveBeachPickupQueue(beach: selectedBeach, playerId: user.id)
            } else {
                if let game = dataManager.joinBeachPickupQueue(beach: selectedBeach, player: user) {
                    navigateToGame(game)
                }
            }
        }
    }
    
    // MARK: - Auto-Fill Handler
    private func handleAutoFill() {
        withAnimation {
            if let game = dataManager.fillBeachPickupQueue(beach: selectedBeach) {
                navigateToGame(game)
            }
        }
    }
    
    // MARK: - Navigate to Game Details Once Filled
    private func navigateToGame(_ game: SetGame) {
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onGameCreated?(game.id)
        }
    }
    
    // MARK: - Player Picker Sheet
    private func playerPickerSheet(for spotIndex: Int) -> some View {
        NavigationStack {
            List {
                let availablePlayers = dataManager.players.filter { p in
                    !currentQueue.contains(where: { $0.id == p.id })
                }
                
                Section("Available Community Players") {
                    ForEach(availablePlayers) { player in
                        Button {
                            showPlayerPickerForSpot = nil
                            withAnimation {
                                if let game = dataManager.joinBeachPickupQueue(beach: selectedBeach, player: player) {
                                    navigateToGame(game)
                                }
                            }
                        } label: {
                            HStack(spacing: 12) {
                                PlayerAvatarView(player: player, dimension: 36)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(player.name)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.primary)
                                    Text("\(player.rating.rawValue) • \(player.homeBeach)")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Select Player for Spot \(spotIndex + 1)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showPlayerPickerForSpot = nil
                    }
                }
            }
        }
    }
}

private struct SelectableSpot: Identifiable {
    let index: Int
    var id: Int { index }
}
