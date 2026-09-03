import SwiftUI

public struct AutoMatchmakerView: View {
    @ObservedObject var dataManager: DataManager
    @State private var selectedOption: MatchmakingType = .smartAvailability
    @State private var showAvailabilityPicker: Bool = false
    @State private var matchFoundAlertMessage: String?
    @State private var showMatchFoundAlert: Bool = false
    
    public init(dataManager: DataManager) {
        self.dataManager = dataManager
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Option Selector Pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(MatchmakingType.allCases) { option in
                                Button {
                                    withAnimation(.spring()) {
                                        selectedOption = option
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: option.icon)
                                            .font(.system(size: 13, weight: .bold))
                                        Text(option.rawValue)
                                            .font(.system(size: 13, weight: .bold))
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 14)
                                    .background(
                                        selectedOption == option ? option.themeColor : Color(UIColor.secondarySystemGroupedBackground)
                                    )
                                    .foregroundColor(selectedOption == option ? .white : .primary)
                                    .clipShape(Capsule())
                                    .shadow(color: selectedOption == option ? option.themeColor.opacity(0.3) : Color.clear, radius: 4, y: 2)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 8)
                    
                    // Option Banner Card
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(selectedOption.tag)
                                .font(.system(size: 10, weight: .black))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(selectedOption.themeColor.opacity(0.2))
                                .foregroundColor(selectedOption.themeColor)
                                .clipShape(Capsule())
                            
                            Spacer()
                            
                            Image(systemName: selectedOption.icon)
                                .font(.system(size: 20))
                                .foregroundColor(selectedOption.themeColor)
                        }
                        
                        Text(selectedOption.title)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text(selectedOption.subtitle)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(16)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    // Dynamic Content based on selected option
                    switch selectedOption {
                    case .smartAvailability:
                        smartAvailabilitySection
                    case .instantQueue:
                        instantQueueSection
                    case .kingOfTheBeach:
                        kingOfBeachSection
                    case .openBoard:
                        openBoardSection
                    }
                }
                .padding(.bottom, 30)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Auto-Matchmaker")
            .sheet(isPresented: $showAvailabilityPicker) {
                AvailabilityPickerView(dataManager: dataManager)
            }
            .alert("Match Found!", isPresented: $showMatchFoundAlert) {
                Button("View Game", role: .cancel) { }
            } message: {
                Text(matchFoundAlertMessage ?? "A balanced set game has been automatically scheduled.")
            }
        }
    }
    
    // MARK: - Option A: Smart Availability View
    private var smartAvailabilitySection: some View {
        VStack(spacing: 16) {
            // Action buttons
            HStack(spacing: 12) {
                Button {
                    showAvailabilityPicker = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Free Window")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Button {
                    let count = dataManager.runAutoMatchmaking()
                    if count > 0 {
                        matchFoundAlertMessage = "Successfully matched \(count) balanced 4-player beach volleyball set(s) based on overlapping windows and skill levels!"
                        showMatchFoundAlert = true
                    } else {
                        matchFoundAlertMessage = "No full 4-player match found yet. Add more availability windows or wait for more players to post their free times."
                        showMatchFoundAlert = true
                    }
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Run Auto-Match")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .foregroundColor(.orange)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange, lineWidth: 1.5)
                    )
                }
            }
            .padding(.horizontal)
            
            // Player's Free Windows
            VStack(alignment: .leading, spacing: 12) {
                Text("YOUR ACTIVE AVAILABILITY WINDOWS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                let userSlots = dataManager.availabilitySlots.filter { $0.playerId == dataManager.currentUser?.id }
                
                if userSlots.isEmpty {
                    VStack(spacing: 8) {
                        Text("No free windows set yet.")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("Tap 'Add Free Window' to tell the engine when you can play.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal)
                } else {
                    ForEach(userSlots) { slot in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Text(slot.dayFormatted)
                                        .font(.system(size: 15, weight: .bold))
                                    if slot.isMatched {
                                        Text("MATCHED")
                                            .font(.system(size: 9, weight: .bold))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.green.opacity(0.2))
                                            .foregroundColor(.green)
                                            .clipShape(Capsule())
                                    }
                                }
                                
                                Text(slot.timeRangeFormatted)
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                
                                Text(slot.preferredBeach)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.orange)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                ForEach(slot.acceptedTiers) { tier in
                                    RatingBadge(rating: tier, size: .small)
                                }
                            }
                        }
                        .padding(14)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
    
    // MARK: - Option B: Instant Queue View
    private var instantQueueSection: some View {
        VStack(spacing: 18) {
            VStack(spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today's Beach Queue")
                            .font(.system(size: 18, weight: .bold))
                        Text("Auto-locks into a game when 4 players join")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    
                    Text("\(dataManager.pickupQueue.count) / 4 Players")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.15))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                }
                
                // Progress Bar
                ProgressView(value: Double(dataManager.pickupQueue.count), total: 4.0)
                    .tint(.blue)
                
                // Player slots
                HStack(spacing: 12) {
                    ForEach(0..<4) { index in
                        VStack(spacing: 6) {
                            if index < dataManager.pickupQueue.count {
                                let p = dataManager.pickupQueue[index]
                                PlayerAvatarView(player: p, dimension: 48)
                                Text(p.nickname)
                                    .font(.system(size: 11, weight: .semibold))
                                    .lineLimit(1)
                            } else {
                                Circle()
                                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                                    .foregroundColor(.secondary.opacity(0.5))
                                    .frame(width: 48, height: 48)
                                    .overlay(
                                        Image(systemName: "plus")
                                            .foregroundColor(.secondary)
                                    )
                                Text("Spot \(index + 1)")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 8)
                
                // Toggle Queue Button
                let inQueue = dataManager.pickupQueue.contains(where: { $0.id == dataManager.currentUser?.id })
                Button {
                    if inQueue {
                        dataManager.leavePickupQueue()
                    } else {
                        dataManager.joinPickupQueue()
                    }
                } label: {
                    HStack {
                        Image(systemName: inQueue ? "xmark.circle.fill" : "bolt.horizontal.circle.fill")
                        Text(inQueue ? "Leave Matchmaking Queue" : "Enter Matchmaking Queue")
                    }
                    .font(.system(size: 15, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(inQueue ? Color.red.opacity(0.8) : Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(18)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
        }
    }
    
    // MARK: - Option C: King of the Beach
    private var kingOfBeachSection: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text("How King of the Beach Works")
                    .font(.system(size: 16, weight: .bold))
                
                Text("No need to find a fixed partner beforehand! You queue as an individual. 4 players play 3 sets where you partner with everyone once:")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Set 1:")
                            .font(.system(size: 13, weight: .bold))
                        Text("Player 1 & 2 vs Player 3 & 4")
                            .font(.system(size: 13))
                    }
                    HStack {
                        Text("Set 2:")
                            .font(.system(size: 13, weight: .bold))
                        Text("Player 1 & 3 vs Player 2 & 4")
                            .font(.system(size: 13))
                    }
                    HStack {
                        Text("Set 3:")
                            .font(.system(size: 13, weight: .bold))
                        Text("Player 1 & 4 vs Player 2 & 3")
                            .font(.system(size: 13))
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.purple.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                
                Button {
                    // Create an instant King of the Beach game
                    if let user = dataManager.currentUser {
                        let opponents = dataManager.players.filter { $0.id != user.id }.shuffled().prefix(3)
                        let allFour = [user] + opponents
                        let game = SetGame(
                            title: "King of the Beach Session",
                            targetRating: user.rating,
                            format: .kingOfTheBeach,
                            status: .scheduled,
                            scheduledDate: Date().addingTimeInterval(3600 * 3),
                            courtLocation: user.homeBeach,
                            courtNumber: "Court #1",
                            team1PlayerIds: [allFour[0].id, allFour[1].id],
                            team2PlayerIds: [allFour[2].id, allFour[3].id],
                            isAutoMatched: true,
                            matchedOptionName: "King of the Beach"
                        )
                        dataManager.games.insert(game, at: 0)
                        matchFoundAlertMessage = "Created King of the Beach 4-player rotation with \(opponents.map { $0.nickname }.joined(separator: ", "))!"
                        showMatchFoundAlert = true
                    }
                } label: {
                    HStack {
                        Image(systemName: "crown.fill")
                        Text("Create King/Queen 4-Player Rotation")
                    }
                    .font(.system(size: 15, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(18)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
        }
    }
    
    // MARK: - Option D: Open Court Auto-Fill
    private var openBoardSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("OPEN SET GAMES NEEDING PLAYERS")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            let openGames = dataManager.games.filter { !$0.isFull && $0.status == .scheduled }
            
            if openGames.isEmpty {
                VStack(spacing: 8) {
                    Text("All scheduled games are currently full!")
                        .font(.system(size: 14, weight: .medium))
                    Text("Use Option A or B above to auto-create a new set.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal)
            } else {
                ForEach(openGames) { game in
                    let compat = dataManager.currentUser != nil ? MatchmakingEngine.shared.calculateCompatibility(player: dataManager.currentUser!, game: game) : 85
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(game.title)
                                    .font(.system(size: 16, weight: .bold))
                                Text(game.formattedDate)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            
                            // Compatibility badge
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(compat)% MATCH")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundColor(compat >= 80 ? .green : .orange)
                                Text("Rating & Schedule")
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                (compat >= 80 ? Color.green : Color.orange).opacity(0.12)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        
                        HStack {
                            Text(game.courtLocation)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                            Spacer()
                            RatingBadge(rating: game.targetRating, size: .small)
                        }
                        
                        HStack {
                            Text("Missing: \(game.spotsRemaining) Player(s)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.orange)
                            
                            Spacer()
                            
                            Button {
                                dataManager.joinOpenGame(gameId: game.id, teamNumber: 2)
                                matchFoundAlertMessage = "You joined \(game.title) at \(game.courtLocation)!"
                                showMatchFoundAlert = true
                            } label: {
                                Text("Auto-Fill & Join")
                                    .font(.system(size: 13, weight: .bold))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(Color.teal)
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(14)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal)
                }
            }
        }
    }
}
