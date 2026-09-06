import SwiftUI

public struct ConfirmedGamesView: View {
    @ObservedObject var dataManager: DataManager
    @ObservedObject private var weatherService = WeatherService.shared
    @State private var selectedFilter: GameFilter = .all
    @State private var showNotificationsSheet: Bool = false
    @State private var showCreateMatchSheet: Bool = false
    @State private var showRandomTeamsSheet: Bool = false
    @State private var showInstantPickupSheet: Bool = false
    @State private var qrGameForSheet: SetGame? = nil
    @State private var editGameForSheet: SetGame? = nil
    @State private var gameForRandomTeams: SetGame? = nil
    @State private var chatGameForSheet: SetGame? = nil
    @State private var navigationPath = NavigationPath()
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var showDeleteAlert: Bool = false
    @State private var gameToDelete: SetGame? = nil
    @State private var expandedMatches: Set<UUID> = []
    @State private var collapsedPoolGameIds: Set<UUID> = []
    @State private var playerToRemove: (gameId: UUID, player: Player)? = nil
    @State private var showRemovePlayerAlert: Bool = false
    
    public enum GameFilter: String, CaseIterable {
        case all = "🗺️ All Upcoming"
        case myGames = "🤝 My Games"
        case pastGames = "📜 Past Games"
    }
    
    public init(dataManager: DataManager) {
        self.dataManager = dataManager
    }
    
    public var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: 16) {
                    // Custom Dark Capsule Filter Bar
                    HStack(spacing: 0) {
                        ForEach(Array(GameFilter.allCases.enumerated()), id: \.offset) { index, filter in
                            if index > 0 {
                                Rectangle()
                                    .fill(Color.white.opacity(0.18))
                                    .frame(width: 1, height: 14)
                            }
                            Button {
                                selectedFilter = filter
                            } label: {
                                Text(filter.rawValue)
                                    .font(.system(size: 13, weight: selectedFilter == filter ? .bold : .medium))
                                    .foregroundColor(selectedFilter == filter ? .white : .white.opacity(0.65))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .background(Color(red: 0.11, green: 0.13, blue: 0.17))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.1), lineWidth: 0.8)
                    )
                    .padding(.horizontal)
                    .padding(.top, 4)
                    
                    // Filtered Games List
                    let displayGames = filteredGames
                    
                    if displayGames.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "figure.volleyball")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("No games in this view")
                                .font(.system(size: 16, weight: .bold))
                            Text("Tap '+ New Game' to host a set game!")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        .padding(50)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(displayGames) { game in
                                gameRow(game)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 30)
            }
            .background(Color(red: 0.08, green: 0.09, blue: 0.12).ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: UUID.self) { gameId in
                GameDetailView(dataManager: dataManager, gameId: gameId)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 8) {
                        Button {
                            showCreateMatchSheet = true
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "plus")
                                    .font(.system(size: 13, weight: .bold))
                                Text("New Game")
                                    .font(.system(size: 13, weight: .bold))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(Color(red: 0.17, green: 0.43, blue: 0.48)) // #2b6e7a
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                        }
                        
                        Button {
                            showInstantPickupSheet = true
                        } label: {
                            HStack(spacing: 5) {
                                Text("🚀")
                                    .font(.system(size: 13))
                                Text("Quick Play")
                                    .font(.system(size: 13, weight: .bold))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(Color(red: 0.17, green: 0.43, blue: 0.48)) // #2b6e7a
                            .foregroundColor(.white)
                            .clipShape(Capsule())
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
            .fullScreenCover(isPresented: $showCreateMatchSheet) {
                CreateMatchSheet(dataManager: dataManager)
            }
            .sheet(isPresented: $showRandomTeamsSheet) {
                RandomTeamGeneratorSheet(dataManager: dataManager)
            }
            .sheet(isPresented: $showInstantPickupSheet) {
                InstantPickupSheet(dataManager: dataManager) { gameId in
                    navigationPath.append(gameId)
                }
            }
            .sheet(item: $qrGameForSheet) { game in
                GameQRCodeSheet(game: game)
            }
            .sheet(item: $editGameForSheet) { game in
                EditMatchSheet(dataManager: dataManager, game: game)
            }
            .sheet(item: $gameForRandomTeams) { game in
                let matchPlayers = game.allPlayerIds.map { dataManager.player(for: $0) }
                RandomTeamGeneratorSheet(
                    dataManager: dataManager,
                    initialGameId: game.id,
                    initialPlayers: matchPlayers,
                    initialBeach: game.courtLocation,
                    initialCourtNumber: game.courtNumber,
                    initialFormat: game.format
                )
            }
            .sheet(item: $chatGameForSheet) { game in
                MatchChatSheet(dataManager: dataManager, game: game)
            }
            .alert("Notice", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .alert("Cancel & Delete Game", isPresented: $showDeleteAlert) {
                Button("Keep Game", role: .cancel) { gameToDelete = nil }
                Button("Cancel Game", role: .destructive) {
                    if let g = gameToDelete {
                        let res = dataManager.deleteGame(gameId: g.id)
                        alertMessage = res.message
                        showAlert = true
                        gameToDelete = nil
                    }
                }
            } message: {
                Text("Are you sure you want to cancel this game and delete it from the schedule?")
            }
            .alert("Remove Player from Match?", isPresented: $showRemovePlayerAlert) {
                Button("Cancel", role: .cancel) { playerToRemove = nil }
                Button("Remove", role: .destructive) {
                    if let target = playerToRemove {
                        let res = dataManager.removePlayerFromPool(gameId: target.gameId, playerId: target.player.id)
                        alertMessage = res.message
                        showAlert = true
                        playerToRemove = nil
                    }
                }
            } message: {
                if let target = playerToRemove {
                    Text("Are you sure you want to remove \(target.player.nickname.isEmpty ? target.player.name : target.player.nickname) from the player pool? If players are on the waitlist, the next player will be auto-promoted.")
                }
            }
        }
    }
    
    private func canUserJoin(_ game: SetGame) -> Bool {
        guard game.spotsRemaining > 0 else { return false }
        if game.isPrivate { return false }
        guard let user = dataManager.currentUser else { return true }
        if game.allPlayerIds.contains(user.id) { return false }
        if game.isLevelLocked && !game.isPlayerTierAllowed(user.rating) {
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
            return dataManager.games
                .filter { $0.status != .canceled && ($0.allPlayerIds.contains(currentUserId) || $0.hostPlayerId == currentUserId) }
                .sorted { $0.scheduledDate < $1.scheduledDate }
        case .pastGames:
            let past = dataManager.games.filter { $0.status == .completed || $0.scheduledDate < Date() }
            return past.sorted { $0.scheduledDate > $1.scheduledDate }
        }
    }
    
    private func hostPlayer(for g: SetGame) -> Player? {
        if let hid = g.hostPlayerId {
            return dataManager.player(for: hid)
        }
        if let firstId = g.team1PlayerIds.first {
            return dataManager.player(for: firstId)
        }
        return nil
    }
    
    private func formatCourt(_ c: String) -> String {
        let trimmed = c.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "#1" }
        if trimmed.hasPrefix("#") { return trimmed }
        let numbers = trimmed.filter { $0.isNumber }
        return numbers.isEmpty ? trimmed : "#\(numbers)"
    }
    
    private func resolveNames(_ pids: [UUID]) -> String {
        if pids.isEmpty { return "TBD" }
        return pids.map { pid in
            let p = dataManager.player(for: pid)
            return p.nickname.isEmpty ? p.name : p.nickname
        }.joined(separator: " & ")
    }

    private func playerCardTile(pid: UUID, game: SetGame, isHost: Bool, isMyGame: Bool, isTeam1: Bool) -> some View {
        let p = dataManager.player(for: pid)
        let displayName = isMyGame ? (p.nickname.isEmpty ? p.name : p.nickname) : "Player"
        let ratingTier = p.rating
        let starStr = String(format: "%.1f", p.averageStarRating)
        let borderColor = isTeam1 ? Color(red: 0.22, green: 0.74, blue: 0.97) : Color(red: 0.94, green: 0.27, blue: 0.27)
        
        return HStack(spacing: 8) {
            if isMyGame {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 34, height: 34)
                    CourtAvatarIconView(avatarKey: p.avatarEmoji, size: 24)
                }
            } else {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 34, height: 34)
                    CourtAvatarIconView(avatarKey: "🏐", size: 22)
                }
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(displayName)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 5) {
                    Text(ratingTier.rawValue)
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(ratingTier == .intermediate ? Color(red: 0.02, green: 0.52, blue: 0.78) : .white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1.5)
                        .background(ratingTier == .intermediate ? Color(red: 0.75, green: 0.90, blue: 0.99) : ratingTier.badgeColor)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    
                    HStack(spacing: 2) {
                        Text("⭐")
                            .font(.system(size: 9))
                        Text(starStr)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(red: 1.0, green: 0.75, blue: 0.2))
                    }
                }
            }
            
            Spacer(minLength: 0)
            
            if isHost && pid != game.hostPlayerId {
                Button {
                    playerToRemove = (game.id, p)
                    showRemovePlayerAlert = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(red: 0.94, green: 0.27, blue: 0.27))
                }
                .buttonStyle(.borderless)
                .padding(.trailing, 2)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(minHeight: 52)
        .background(Color(red: 0.07, green: 0.09, blue: 0.13))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: 1.5)
        )
    }

    private func emptyPlayerSpotTile(game: SetGame, isTeam1: Bool) -> some View {
        let borderColor = isTeam1 ? Color(red: 0.22, green: 0.74, blue: 0.97).opacity(0.6) : Color(red: 0.94, green: 0.27, blue: 0.27).opacity(0.6)
        
        return Button {
            if canUserJoin(game) {
                let res = dataManager.joinGamePool(gameId: game.id)
                alertMessage = res.message
                showAlert = true
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .bold))
                Text("Open Spot")
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundColor(.white.opacity(0.7))
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(Color(red: 0.07, green: 0.09, blue: 0.13).opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                    .foregroundColor(borderColor)
            )
        }
        .buttonStyle(.borderless)
    }

    private func cardHeader(game: SetGame, isMyGame: Bool, isHost: Bool) -> some View {
        HStack(alignment: .center) {
            Button {
                navigationPath.append(game.id)
            } label: {
                HStack(spacing: 6) {
                    Text("🗓️")
                        .font(.system(size: 16))
                    Text(game.formattedDate)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Menu {
                Button {
                    editGameForSheet = game
                } label: {
                    Label("Edit Details", systemImage: "pencil")
                }
                
                if isHost || dataManager.currentUser?.isRoot == true {
                    Button(role: .destructive) {
                        gameToDelete = game
                        showDeleteAlert = true
                    } label: {
                        Label("Cancel Game", systemImage: "trash")
                    }
                }
                
                Button {
                    qrGameForSheet = game
                } label: {
                    Label("View QR Code", systemImage: "qrcode")
                }
                
                if isMyGame {
                    Button {
                        chatGameForSheet = game
                    } label: {
                        Label("Match Chat (\(game.messages.count))", systemImage: "message")
                    }
                    Button(role: .destructive) {
                        let res = dataManager.leaveGame(gameId: game.id)
                        alertMessage = res.message
                        showAlert = true
                    } label: {
                        Label("Leave Game", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } else if canUserJoin(game) {
                    Button {
                        let res = dataManager.joinGamePool(gameId: game.id)
                        alertMessage = res.message
                        showAlert = true
                    } label: {
                        Label("Join Game", systemImage: "plus.circle")
                    }
                }
                
                Button {
                    gameForRandomTeams = game
                } label: {
                    Label("Generate Matches", systemImage: "dice")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.85))
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.top, 2)
    }

    private func cardMetadataLines(game: SetGame) -> some View {
        let skillStr = (game.allowedRatings.count >= RatingTier.allCases.count || game.allowedRatings.isEmpty) ? "All Levels" : game.allowedRatings.map(\.rawValue).joined(separator: "/")
        let host = hostPlayer(for: game)
        let hostName = host?.nickname.isEmpty == false ? host!.nickname : (host?.name ?? "Host")
        let hostRating = host != nil ? String(format: "%.1f", host!.averageStarRating) : "5.0"
        let formatStr = game.maxPlayers == 2 ? "1v1" : (game.maxPlayers == 6 ? "3v3" : "2v2")
        
        return VStack(alignment: .leading, spacing: 6) {
            // Line 1: Location & Court
            HStack(spacing: 6) {
                Text("📍")
                    .font(.system(size: 14))
                Text("\(game.courtLocation) - \(formatCourt(game.courtNumber))")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            // Line 2: Format & Skill & Privacy
            HStack(spacing: 6) {
                Text("\(formatStr) Skill: \(skillStr)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.9))
                if game.isPrivate {
                    Text("🔒")
                        .font(.system(size: 13))
                }
                if game.isLevelLocked {
                    HStack(spacing: 2) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9))
                        Text("Locked")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
            
            // Line 3: Host & Rating
            HStack(spacing: 6) {
                Text("Host: \(hostName)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.85))
                HStack(spacing: 3) {
                    Text("⭐")
                        .font(.system(size: 12))
                    Text(hostRating)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(red: 1.0, green: 0.75, blue: 0.2))
                }
            }
            
            // Weather Forecast Capsule
            weatherCapsuleView(game: game)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            navigationPath.append(game.id)
        }
    }

    private func weatherCapsuleView(game: SetGame) -> some View {
        let forecast = weatherService.cachedForecast(for: game.courtLocation, on: game.scheduledDate)
        return HStack(alignment: .center) {
            if let w = forecast {
                // Section 1: Temp
                HStack(spacing: 5) {
                    Text(w.conditionEmoji.isEmpty ? "☀️" : w.conditionEmoji)
                        .font(.system(size: 16))
                    Text("\(w.tempF)°F")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                }
                Spacer()
                // Section 2: UV
                VStack(alignment: .center, spacing: 1) {
                    HStack(spacing: 4) {
                        Text("☀️")
                            .font(.system(size: 12))
                        Text("UV \(Int(w.uvIndex.rounded()))")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Text("(\(w.uvCategory))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(w.uvColor)
                }
                Spacer()
                // Section 3: Wind
                VStack(alignment: .center, spacing: 1) {
                    HStack(spacing: 4) {
                        Text("💨")
                            .font(.system(size: 12))
                        Text("\(w.windMph) mph \(w.windDirection)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Text("(\(w.windCategory))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(red: 0.35, green: 0.65, blue: 0.95))
                }
            } else {
                HStack(spacing: 6) {
                    Text("☀️")
                        .font(.system(size: 14))
                    Text("Loading forecast...")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.vertical, 4)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color(red: 0.05, green: 0.07, blue: 0.10))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .onAppear {
            weatherService.loadForecast(for: game.courtLocation, on: game.scheduledDate)
        }
    }

    private func playersPoolBox(game: SetGame, isMyGame: Bool, currentUserId: UUID?) -> some View {
        let isHost = (game.hostPlayerId == currentUserId) || (dataManager.currentUser?.isRoot == true)
        let t1Ids: [UUID] = !game.team1PlayerIds.isEmpty ? game.team1PlayerIds : Array(game.allPlayerIds.prefix(2))
        let t2Ids: [UUID] = !game.team2PlayerIds.isEmpty ? game.team2PlayerIds : Array(game.allPlayerIds.dropFirst(2).prefix(2))
        
        return VStack(spacing: 8) {
            // Row 1: Team 1 (Cyan/Blue Border)
            HStack(spacing: 8) {
                if t1Ids.count > 0 {
                    playerCardTile(pid: t1Ids[0], game: game, isHost: isHost, isMyGame: isMyGame, isTeam1: true)
                } else {
                    emptyPlayerSpotTile(game: game, isTeam1: true)
                }
                
                if t1Ids.count > 1 {
                    playerCardTile(pid: t1Ids[1], game: game, isHost: isHost, isMyGame: isMyGame, isTeam1: true)
                } else {
                    emptyPlayerSpotTile(game: game, isTeam1: true)
                }
            }
            
            // Row 2: Team 2 (Coral/Red Border)
            HStack(spacing: 8) {
                if t2Ids.count > 0 {
                    playerCardTile(pid: t2Ids[0], game: game, isHost: isHost, isMyGame: isMyGame, isTeam1: false)
                } else {
                    emptyPlayerSpotTile(game: game, isTeam1: false)
                }
                
                if t2Ids.count > 1 {
                    playerCardTile(pid: t2Ids[1], game: game, isHost: isHost, isMyGame: isMyGame, isTeam1: false)
                } else {
                    emptyPlayerSpotTile(game: game, isTeam1: false)
                }
            }
            
            // Waitlist Section (Visible whenever pool is full or waitlist has queued players)
            if game.spotsRemaining == 0 || !game.waitlistPlayerIds.isEmpty {
                waitlistSection(game: game, currentUserId: currentUserId, isMyGame: isMyGame, isHost: isHost)
            }
        }
    }

    private func waitlistSection(game: SetGame, currentUserId: UUID?, isMyGame: Bool, isHost: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "clock.badge.checkmark.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.purple)
                Text("⏳ WAITLIST (\(game.waitlistPlayerIds.count) QUEUED)")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundColor(.purple)
                Spacer()
                Text("Auto-promotes when spot opens")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            
            // Join / Leave Waitlist Controls for non-members
            if game.spotsRemaining == 0 && !isMyGame {
                if let uid = currentUserId, let index = game.waitlistPlayerIds.firstIndex(of: uid) {
                    let pos = index + 1
                    HStack {
                        Text("⏳ You are #\(pos) on the Waitlist")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.purple)
                        Spacer()
                        Button {
                            let res = dataManager.leaveWaitlist(gameId: game.id)
                            alertMessage = res.message
                            showAlert = true
                        } label: {
                            Text("Leave Waitlist")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.red)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.red.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(8)
                    .background(Color.purple.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    if game.isPrivate {
                        HStack(spacing: 6) {
                            Text("🔒")
                            Text("Private Game • Invite Only")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background(Color(red: 0.12, green: 0.14, blue: 0.19))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        Button {
                            let res = dataManager.joinWaitlist(gameId: game.id)
                            alertMessage = res.message
                            showAlert = true
                        } label: {
                            HStack(spacing: 6) {
                                Text("⏳")
                                Text("Pool Full • Join Waitlist (\(game.waitlistPlayerIds.count) queued)")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundColor(Color.purple)
                            .frame(maxWidth: .infinity, minHeight: 36)
                            .background(Color.purple.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4]))
                                    .foregroundColor(Color.purple.opacity(0.5))
                            )
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
            
            // Queued players list
            if !game.waitlistPlayerIds.isEmpty {
                ForEach(Array(game.waitlistPlayerIds.enumerated()), id: \.offset) { idx, wId in
                    let wp = dataManager.player(for: wId)
                    let wpName = isMyGame ? (wp.nickname.isEmpty ? wp.name : "\(wp.name) (\(wp.nickname))") : "Player \(idx + 1)"
                    HStack {
                        Text("#\(idx + 1)")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.white)
                            .frame(width: 20, height: 20)
                            .background(Color.purple)
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text(wpName)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                            Text(wp.rating.rawValue)
                                .font(.system(size: 9))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        Spacer()
                        
                        if isHost {
                            Button {
                                let res = dataManager.promoteWaitlistPlayer(gameId: game.id, playerId: wId)
                                alertMessage = res.message
                                showAlert = true
                            } label: {
                                HStack(spacing: 3) {
                                    Image(systemName: "arrow.up.circle.fill")
                                    Text("Promote")
                                }
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green)
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.borderless)
                        }
                        
                        if let uid = currentUserId, uid == wId {
                            Button {
                                let res = dataManager.leaveWaitlist(gameId: game.id)
                                alertMessage = res.message
                                showAlert = true
                            } label: {
                                Text("Leave")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(red: 0.12, green: 0.14, blue: 0.19))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .padding(.top, 4)
    }

    private func matchesSection(game: SetGame) -> some View {
        let isExpanded = expandedMatches.contains(game.id)
        return VStack(spacing: 8) {
            Button {
                withAnimation {
                    if isExpanded {
                        expandedMatches.remove(game.id)
                    } else {
                        expandedMatches.insert(game.id)
                    }
                }
            } label: {
                HStack {
                    Text("🥎 MATCHES IN THIS GAME (\(game.subMatches.count))")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.white.opacity(0.9))
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.white.opacity(0.8))
                }
            }
            .buttonStyle(.plain)
            
            Button {
                withAnimation {
                    if isExpanded {
                        expandedMatches.remove(game.id)
                    } else {
                        expandedMatches.insert(game.id)
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Text("🏐")
                        .font(.system(size: 14))
                    Text("Match Schedule (\(game.subMatches.count))")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(red: 0.08, green: 0.10, blue: 0.14))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                if game.subMatches.isEmpty {
                    VStack(spacing: 8) {
                        Text("No match rotations generated yet.")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Button {
                            gameForRandomTeams = game
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "dice.fill")
                                    .font(.system(size: 12, weight: .bold))
                                Text("🎲 Generate Matches (\(game.allPlayerIds.count) Players)")
                                    .font(.system(size: 12, weight: .black))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 38)
                            .background(Color(red: 0.92, green: 0.35, blue: 0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.vertical, 6)
                } else {
                    VStack(spacing: 6) {
                        ForEach(Array(game.subMatches.enumerated()), id: \.element.id) { mIdx, sm in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("MATCH \(sm.matchNumber) • \(sm.courtNumber)")
                                        .font(.system(size: 10, weight: .black))
                                        .foregroundColor(Color(red: 0.49, green: 0.23, blue: 0.93))
                                    Spacer()
                                    if sm.isCompleted {
                                        Text("SCORED ✓")
                                            .font(.system(size: 9, weight: .black))
                                            .foregroundColor(.green)
                                    } else {
                                        Text("Scheduled")
                                            .font(.system(size: 9, weight: .medium))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                HStack {
                                    Text(resolveNames(sm.team1PlayerIds))
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    Spacer()
                                    Text("VS")
                                        .font(.system(size: 10, weight: .black))
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 6)
                                    Spacer()
                                    Text(resolveNames(sm.team2PlayerIds))
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                }
                                
                                if !sm.restingPlayerIds.isEmpty {
                                    Text("⏸ Resting: \(resolveNames(sm.restingPlayerIds))")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                                
                                if let s1 = sm.team1Score, let s2 = sm.team2Score {
                                    HStack {
                                        Text("Score: \(s1) – \(s2)")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.white)
                                        if sm.isCompleted, let win = sm.winningTeam {
                                            Text("(Team \(win) Won)")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.green)
                                        }
                                    }
                                    .padding(.top, 2)
                                }
                            }
                            .padding(8)
                            .background(Color(red: 0.08, green: 0.10, blue: 0.14))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 0.8)
                            )
                        }
                    }
                }
            }
        }
    }

    private func cardFooter(game: SetGame, isMyGame: Bool, isHost: Bool) -> some View {
        VStack(spacing: 12) {
            // Top Row of Footer: Time on left, ADMIN ACTIONS • SETTINGS ▾ on right
            HStack {
                HStack(spacing: 4) {
                    Text("🕒")
                        .font(.system(size: 12))
                    Text(game.formattedDate)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.65))
                }
                Spacer()
                
                Menu {
                    Button {
                        gameForRandomTeams = game
                    } label: {
                        Label("Generate Matches", systemImage: "dice")
                    }
                    Button {
                        qrGameForSheet = game
                    } label: {
                        Label("QR Code / Share", systemImage: "qrcode")
                    }
                    if isMyGame {
                        Button {
                            chatGameForSheet = game
                        } label: {
                            Label("Match Chat (\(game.messages.count))", systemImage: "message")
                        }
                    }
                    Button {
                        editGameForSheet = game
                    } label: {
                        Label("Edit Game", systemImage: "pencil")
                    }
                    if isHost || dataManager.currentUser?.isRoot == true {
                        Button(role: .destructive) {
                            gameToDelete = game
                            showDeleteAlert = true
                        } label: {
                            Label("Cancel Game", systemImage: "trash")
                        }
                    }
                } label: {
                    HStack(spacing: 3) {
                        Text("ADMIN ACTIONS • SETTINGS")
                            .font(.system(size: 10, weight: .heavy))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .bold))
                    }
                    .foregroundColor(Color.white.opacity(0.75))
                }
                .buttonStyle(.borderless)
            }
            
            // Bottom Row: Action Buttons
            HStack(spacing: 8) {
                // Button 1: QR Code
                Button {
                    qrGameForSheet = game
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: "iphone")
                            .font(.system(size: 16, weight: .bold))
                        Text("QR\nCode")
                            .font(.system(size: 10, weight: .bold))
                            .multilineTextAlignment(.center)
                            .lineSpacing(-2)
                    }
                    .frame(width: 54, height: 54)
                    .background(Color.white)
                    .foregroundColor(Color(red: 0.08, green: 0.09, blue: 0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.borderless)
                
                // Button 2: Chat
                Button {
                    chatGameForSheet = game
                } label: {
                    ZStack(alignment: .topTrailing) {
                        VStack(spacing: 2) {
                            Image(systemName: "message.fill")
                                .font(.system(size: 15, weight: .bold))
                            Text("Chat\n(\(game.messages.count))")
                                .font(.system(size: 10, weight: .bold))
                                .multilineTextAlignment(.center)
                                .lineSpacing(-2)
                        }
                        .frame(width: 54, height: 54)
                        .background(Color(red: 0.88, green: 0.95, blue: 0.99))
                        .foregroundColor(Color(red: 0.02, green: 0.45, blue: 0.75))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(red: 0.22, green: 0.74, blue: 0.97), lineWidth: 1.5)
                        )
                        
                        if game.messages.count > 0 {
                            Text("\(game.messages.count)")
                                .font(.system(size: 9, weight: .black))
                                .foregroundColor(.white)
                                .frame(width: 16, height: 16)
                                .background(Color(red: 0.02, green: 0.52, blue: 0.85))
                                .clipShape(Circle())
                                .offset(x: 4, y: -4)
                        }
                    }
                }
                .buttonStyle(.borderless)
                
                // Button 3: Leave Game (or Join)
                if isMyGame {
                    Button {
                        let res = dataManager.leaveGame(gameId: game.id)
                        alertMessage = res.message
                        showAlert = true
                    } label: {
                        VStack(spacing: 2) {
                            Text("Leave\nGame")
                                .font(.system(size: 11, weight: .heavy))
                                .multilineTextAlignment(.center)
                                .lineSpacing(-2)
                        }
                        .frame(width: 58, height: 54)
                        .background(Color(red: 1.0, green: 0.89, blue: 0.90))
                        .foregroundColor(Color(red: 0.60, green: 0.11, blue: 0.11))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(red: 0.99, green: 0.80, blue: 0.83), lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.borderless)
                } else if canUserJoin(game) {
                    Button {
                        let res = dataManager.joinGamePool(gameId: game.id)
                        alertMessage = res.message
                        showAlert = true
                    } label: {
                        VStack(spacing: 2) {
                            Text("Join\nGame")
                                .font(.system(size: 11, weight: .heavy))
                                .multilineTextAlignment(.center)
                                .lineSpacing(-2)
                        }
                        .frame(width: 58, height: 54)
                        .background(Color(red: 0.86, green: 0.97, blue: 0.89))
                        .foregroundColor(Color(red: 0.09, green: 0.48, blue: 0.22))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(red: 0.52, green: 0.92, blue: 0.65), lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.borderless)
                } else {
                    Spacer(minLength: 0)
                }
                
                Spacer()
                
                // Button 4: Edit
                Button {
                    editGameForSheet = game
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: "pencil")
                            .font(.system(size: 16, weight: .bold))
                        Text("Edit")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .frame(width: 54, height: 54)
                    .background(Color.white)
                    .foregroundColor(Color(red: 0.08, green: 0.09, blue: 0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.borderless)
                
                // Button 5: Cancel Game
                if isHost || dataManager.currentUser?.isRoot == true {
                    Button {
                        gameToDelete = game
                        showDeleteAlert = true
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .heavy))
                            Text("Cancel\nGame")
                                .font(.system(size: 9, weight: .heavy))
                                .multilineTextAlignment(.center)
                                .lineSpacing(-2)
                        }
                        .frame(width: 54, height: 54)
                        .background(Color(red: 1.0, green: 0.89, blue: 0.90))
                        .foregroundColor(Color(red: 0.70, green: 0.11, blue: 0.11))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(red: 0.99, green: 0.80, blue: 0.83), lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
    }

    private func gameRow(_ game: SetGame) -> some View {
        let currentUserId = dataManager.currentUser?.id
        let isMyGame: Bool
        let isHost: Bool
        if let uid = currentUserId {
            isMyGame = game.allPlayerIds.contains(uid) || game.hostPlayerId == uid
            isHost = (game.hostPlayerId != nil && game.hostPlayerId == uid) || (game.team1PlayerIds.first == uid)
        } else {
            isMyGame = false
            isHost = false
        }
        
        return VStack(alignment: .leading, spacing: 12) {
            cardHeader(game: game, isMyGame: isMyGame, isHost: isHost)
            cardMetadataLines(game: game)
            playersPoolBox(game: game, isMyGame: isMyGame, currentUserId: currentUserId)
            matchesSection(game: game)
            cardFooter(game: game, isMyGame: isMyGame, isHost: isHost)
        }
        .padding(16)
        .background(Color(red: 0.11, green: 0.13, blue: 0.17))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 10, y: 4)
    }
}
