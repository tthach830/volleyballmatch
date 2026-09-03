import SwiftUI

public struct ConfirmedGamesView: View {
    @ObservedObject var dataManager: DataManager
    @State private var selectedFilter: GameFilter = .all
    @State private var showNotificationsSheet: Bool = false
    @State private var showCreateMatchSheet: Bool = false
    @State private var showRandomTeamsSheet: Bool = false
    @State private var qrGameForSheet: SetGame? = nil
    
    public enum GameFilter: String, CaseIterable {
        case all = "All Upcoming"
        case myGames = "My Games"
        case openSpots = "Needs Players"
    }
    
    public init(dataManager: DataManager) {
        self.dataManager = dataManager
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Filter picker: All Upcoming, My Games, Needs Players
                    Picker("Filter Games", selection: $selectedFilter) {
                        ForEach(GameFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Filtered Games List
                    let displayGames = filteredGames
                    
                    if displayGames.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "figure.volleyball")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("No games in this view")
                                .font(.system(size: 16, weight: .bold))
                            Text("Tap '+ New Match' to host a set game!")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        .padding(50)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(displayGames) { game in
                                NavigationLink {
                                    GameDetailView(dataManager: dataManager, gameId: game.id)
                                } label: {
                                    gameRow(game)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 30)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Set Games")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 12) {
                        Button {
                            showCreateMatchSheet = true
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: "plus.circle.fill")
                                Text("New Game")
                            }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.orange)
                        }
                        
                        Button {
                            showRandomTeamsSheet = true
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: "dice.fill")
                                Text("Random")
                            }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.purple)
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        NotificationService.shared.requestPermission()
                        showNotificationsSheet = true
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 17))
                                .foregroundColor(.orange)
                            
                            if dataManager.unreadNotificationsCount > 0 {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 9, height: 9)
                                    .offset(x: 3, y: -3)
                            }
                        }
                        .padding(4)
                    }
                }
            }
            .sheet(isPresented: $showNotificationsSheet) {
                NotificationsSheet(dataManager: dataManager)
            }
            .sheet(isPresented: $showCreateMatchSheet) {
                CreateMatchSheet(dataManager: dataManager)
            }
            .sheet(isPresented: $showRandomTeamsSheet) {
                RandomTeamGeneratorSheet(dataManager: dataManager)
            }
            .sheet(item: $qrGameForSheet) { game in
                GameQRCodeSheet(game: game)
            }
        }
    }
    
    private func canUserJoin(_ game: SetGame) -> Bool {
        guard game.spotsRemaining > 0 else { return false }
        guard let user = dataManager.currentUser else { return true }
        if game.allPlayerIds.contains(user.id) { return false }
        if game.isLevelLocked && user.rating != game.targetRating {
            return false
        }
        return true
    }
    
    private var filteredGames: [SetGame] {
        let currentUserId = dataManager.currentUser?.id
        
        // Only include upcoming matches (scheduled or in-progress)
        let upcoming = dataManager.games.filter { $0.status == .scheduled || $0.status == .inProgress }
        
        // Filter by user selection and sort by date and time
        switch selectedFilter {
        case .all:
            return upcoming.sorted { $0.scheduledDate < $1.scheduledDate }
        case .myGames:
            guard let currentUserId = currentUserId else { return [] }
            return upcoming
                .filter { $0.allPlayerIds.contains(currentUserId) || $0.hostPlayerId == currentUserId }
                .sorted { $0.scheduledDate < $1.scheduledDate }
        case .openSpots:
            return upcoming
                .filter { canUserJoin($0) }
                .sorted { $0.scheduledDate < $1.scheduledDate }
        }
    }
    
    private func gameRow(_ game: SetGame) -> some View {
        let isMyGame = dataManager.currentUser != nil && (game.allPlayerIds.contains(dataManager.currentUser!.id) || game.hostPlayerId == dataManager.currentUser!.id)
        
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                RatingBadge(rating: game.targetRating, size: .small)
                
                if isMyGame {
                    HStack(spacing: 3) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 8))
                        Text("My Game")
                    }
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.15))
                    .foregroundColor(.blue)
                    .clipShape(Capsule())
                }
                
                if !game.subMatches.isEmpty {
                    HStack(spacing: 3) {
                        Image(systemName: "circle.grid.2x2.fill")
                            .font(.system(size: 8))
                        Text("\(game.subMatches.count) Matches")
                    }
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.purple.opacity(0.15))
                    .foregroundColor(.purple)
                    .clipShape(Capsule())
                }
                
                if game.isLevelLocked {
                    HStack(spacing: 3) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 8))
                        Text("Locked")
                    }
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.15))
                    .foregroundColor(.orange)
                    .clipShape(Capsule())
                }
                
                if game.isAutoMatched {
                    HStack(spacing: 3) {
                        Image(systemName: "sparkles")
                        Text("Auto-Matched")
                    }
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.purple.opacity(0.15))
                    .foregroundColor(.purple)
                    .clipShape(Capsule())
                }
                
                Spacer()
                
                Button {
                    qrGameForSheet = game
                } label: {
                    Image(systemName: "qrcode")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.blue)
                        .padding(5)
                        .background(Color.blue.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                
                Text(game.status.rawValue)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.orange)
            }
            
            Text(game.title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)
            
            HStack(spacing: 12) {
                Label(game.formattedDate, systemImage: "clock")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Label("\(game.courtLocation)", systemImage: "mappin")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            // Player Lineup Icons & View Match link
            HStack {
                HStack(spacing: -6) {
                    ForEach(game.allPlayerIds.prefix(5), id: \.self) { pid in
                        let p = dataManager.player(for: pid)
                        PlayerAvatarView(player: p, dimension: 28, showBadge: false)
                    }
                    if game.allPlayerIds.count > 5 {
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(0.2))
                                .frame(width: 26, height: 26)
                            Text("+\(game.allPlayerIds.count - 5)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                if game.spotsRemaining > 0 {
                    Text("\(game.spotsRemaining) spot(s) open")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.orange)
                        .padding(.leading, 8)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("View Match")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.orange)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.orange)
                }
            }
            .padding(.top, 2)
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color.black.opacity(0.03), radius: 4, y: 2)
    }
}
