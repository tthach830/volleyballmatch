import SwiftUI

public struct ConfirmedGamesView: View {
    @ObservedObject var dataManager: DataManager
    @State private var selectedFilter: GameFilter = .all
    @State private var showNotificationsSheet: Bool = false
    @State private var showCreateMatchSheet: Bool = false
    @State private var showRandomTeamsSheet: Bool = false
    @State private var qrGameForSheet: SetGame? = nil
    @State private var editGameForSheet: SetGame? = nil
    @State private var gameForRandomTeams: SetGame? = nil
    @State private var navigationPath = NavigationPath()
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var showDeleteAlert: Bool = false
    @State private var gameToDelete: SetGame? = nil
    @State private var expandedMatches: Set<UUID> = []
    @State private var playerToRemove: (gameId: UUID, player: Player)? = nil
    @State private var showRemovePlayerAlert: Bool = false
    
    public enum GameFilter: String, CaseIterable {
        case all = "📅 All Upcoming"
        case myGames = "🎮 My Games"
        case completed = "🕒 Past Games"
    }
    
    public init(dataManager: DataManager) {
        self.dataManager = dataManager
    }
    
    public var body: some View {
        NavigationStack(path: $navigationPath) {
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
            .background(Color(UIColor.systemGroupedBackground))
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
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                    .font(.system(size: 11, weight: .bold))
                                Text("New Game")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color(red: 0.49, green: 0.23, blue: 0.93)) // #7c3aed
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                        }
                        
                        Button {
                            showRandomTeamsSheet = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "dice.fill")
                                    .font(.system(size: 11, weight: .bold))
                                Text("Quick Play")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color(red: 0.92, green: 0.35, blue: 0.05)) // #ea580c
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
        let completed = dataManager.games.filter { $0.status == .completed }
        
        // Filter by user selection and sort by date and time
        switch selectedFilter {
        case .all:
            return upcoming.sorted { $0.scheduledDate < $1.scheduledDate }
        case .myGames:
            guard let currentUserId = currentUserId else { return [] }
            return dataManager.games
                .filter { $0.status != .canceled && ($0.allPlayerIds.contains(currentUserId) || $0.hostPlayerId == currentUserId) }
                .sorted { $0.scheduledDate < $1.scheduledDate }
        case .completed:
            return completed.sorted { $0.scheduledDate > $1.scheduledDate }
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

    private func playerPoolTile(pid: UUID, game: SetGame, isHost: Bool) -> some View {
        let p = dataManager.player(for: pid)
        let displayName = p.nickname.isEmpty ? p.name : p.nickname
        let ratingTier = p.rating
        let starStr = String(format: "%.1f", p.averageStarRating)
        
        return HStack(spacing: 8) {
            PlayerAvatarView(player: p, dimension: 32, showBadge: false)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(displayName)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(.label))
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text(ratingTier.rawValue)
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(ratingTier.badgeColor)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(ratingTier.badgeColor.opacity(0.18))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    
                    HStack(spacing: 1) {
                        Text("⭐")
                            .font(.system(size: 8))
                        Text(starStr)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(red: 0.7, green: 0.35, blue: 0.05))
                    }
                }
            }
            Spacer(minLength: 0)
            
            if isHost && pid != game.hostPlayerId {
                Button {
                    playerToRemove = (game.id, p)
                    showRemovePlayerAlert = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.red.opacity(0.85))
                }
                .buttonStyle(.borderless)
                .padding(.leading, 2)
            }
        }
        .padding(8)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.separator).opacity(0.4), lineWidth: 0.8)
        )
    }

    private func cardHeader(game: SetGame, isMyGame: Bool, isHost: Bool) -> some View {
        HStack(alignment: .center) {
            Spacer()
            Button {
                navigationPath.append(game.id)
            } label: {
                Text("GAME DETAILS")
                    .font(.system(size: 13, weight: .black))
                    .foregroundColor(Color(.label))
                    .tracking(0.5)
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .overlay(alignment: .trailing) {
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
                
                Button {
                    navigationPath.append(game.id)
                } label: {
                    Label("Match Chat (\(game.messages.count))", systemImage: "message")
                }
                
                if canUserJoin(game) {
                    Button {
                        let res = dataManager.joinGamePool(gameId: game.id)
                        alertMessage = res.message
                        showAlert = true
                    } label: {
                        Label("Join Game", systemImage: "plus.circle")
                    }
                } else if !isMyGame && game.spotsRemaining == 0 {
                    let isWaitlisted = dataManager.currentUser != nil && game.waitlistPlayerIds.contains(dataManager.currentUser!.id)
                    if isWaitlisted {
                        Button(role: .destructive) {
                            let res = dataManager.leaveWaitlist(gameId: game.id)
                            alertMessage = res.message
                            showAlert = true
                        } label: {
                            Label("Leave Waitlist", systemImage: "clock.badge.xmark")
                        }
                    } else {
                        Button {
                            let res = dataManager.joinWaitlist(gameId: game.id)
                            alertMessage = res.message
                            showAlert = true
                        } label: {
                            Label("Join Waitlist", systemImage: "clock.badge.plus")
                        }
                    }
                }
                
                if isMyGame {
                    Button(role: .destructive) {
                        let res = dataManager.leaveGame(gameId: game.id)
                        alertMessage = res.message
                        showAlert = true
                    } label: {
                        Label("Leave Game", systemImage: "rectangle.portrait.and.arrow.right")
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
                        Label("Cancel Game (Delete)", systemImage: "xmark.circle")
                    }
                }
            } label: {
                HStack(spacing: 3) {
                    Text("⚙️ ADMIN ACTIONS")
                        .font(.system(size: 10, weight: .bold))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8, weight: .bold))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.systemGray6))
                .foregroundColor(Color(.secondaryLabel))
                .clipShape(Capsule())
            }
            .buttonStyle(.borderless)
        }
        .padding(.top, 2)
    }

    private func cardMetadataLines(game: SetGame) -> some View {
        let formatLabel = game.maxPlayers == 2 ? "1v1 Singles" : game.maxPlayers == 6 ? "3v3 Triples" : "2v2 Doubles"
        let skillStr = (game.allowedRatings.count >= RatingTier.allCases.count || game.allowedRatings.isEmpty) ? "All Levels" : game.allowedRatings.map(\.rawValue).joined(separator: " / ")
        let statusText = game.status == .completed ? "Completed" : (game.status == .inProgress ? "Live" : "Open")
        
        let host = hostPlayer(for: game)
        let hostName: String
        let hostRating: String
        if let host = host {
            hostName = host.nickname.isEmpty ? host.name : host.nickname
            hostRating = String(format: "%.1f", host.averageStarRating)
        } else {
            hostName = "Host"
            hostRating = "5.0"
        }
        
        return VStack(alignment: .leading, spacing: 4) {
            // Line 1: SCHEDULE & COURT
            HStack(spacing: 5) {
                Text("📅")
                    .font(.system(size: 12))
                Text("SCHEDULE:")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(Color(.label))
                Text(game.formattedDate)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(.secondaryLabel))
                Text("•")
                    .foregroundColor(Color(.tertiaryLabel))
                Text("📍 \(game.courtLocation) \(formatCourt(game.courtNumber))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(.secondaryLabel))
                Spacer(minLength: 0)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            
            // Line 2: FORMAT, STATUS & SKILL
            HStack(spacing: 5) {
                Text("🏐")
                    .font(.system(size: 12))
                Text("FORMAT:")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(Color(.label))
                Text(formatLabel)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(.secondaryLabel))
                Text("•")
                    .foregroundColor(Color(.tertiaryLabel))
                
                Text(statusText)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(red: 0.08, green: 0.55, blue: 0.28))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                
                Text("•")
                    .foregroundColor(Color(.tertiaryLabel))
                Text("🏅")
                    .font(.system(size: 12))
                Text("SKILL:")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(Color(.label))
                Text(skillStr)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(.secondaryLabel))
                Spacer(minLength: 0)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            
            // Line 3: HOST, RATING & LEVEL LOCKED
            HStack(spacing: 5) {
                Text("👑")
                    .font(.system(size: 12))
                Text("HOST:")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(Color(.label))
                Text(hostName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(.secondaryLabel))
                Text("•")
                    .foregroundColor(Color(.tertiaryLabel))
                HStack(spacing: 2) {
                    Text("⭐")
                        .font(.system(size: 11))
                    Text(hostRating)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(red: 0.7, green: 0.35, blue: 0.05))
                }
                if game.isLevelLocked {
                    HStack(spacing: 3) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9))
                        Text("Level Locked")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.15))
                    .foregroundColor(.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                Spacer(minLength: 0)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            navigationPath.append(game.id)
        }
    }

    private func playersPoolBox(game: SetGame, isMyGame: Bool, currentUserId: UUID?) -> some View {
        let isHost = (game.hostPlayerId == currentUserId) || (dataManager.currentUser?.isRoot == true)
        return VStack(spacing: 8) {
            HStack {
                Text("👥 PLAYERS POOL (\(game.allPlayerIds.count)/\(game.maxPlayers) PLAYERS)")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(Color(.label))
                Spacer()
                if game.spotsRemaining == 0 {
                    Text("Pool Full ✓")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.green)
                } else {
                    Text("\(game.spotsRemaining) Open Spot\(game.spotsRemaining > 1 ? "s" : "")")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.orange)
                }
            }
            
            // 2-Column Grid
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                ForEach(Array(game.allPlayerIds.enumerated()), id: \.offset) { _, pid in
                    playerPoolTile(pid: pid, game: game, isHost: isHost)
                }
                
                if game.spotsRemaining > 0 && !isMyGame {
                    Button {
                        let res = dataManager.joinGamePool(gameId: game.id)
                        alertMessage = res.message
                        showAlert = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 13, weight: .bold))
                            Text("Join Player Pool")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(Color(red: 0.49, green: 0.23, blue: 0.93))
                        .frame(maxWidth: .infinity, minHeight: 46)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                                .foregroundColor(Color(red: 0.49, green: 0.23, blue: 0.93).opacity(0.6))
                        )
                    }
                    .buttonStyle(.borderless)
                }
            }
            
            // Waitlist Section (Visible whenever pool is full or waitlist has queued players)
            if game.spotsRemaining == 0 || !game.waitlistPlayerIds.isEmpty {
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
                                .background(Color.purple.opacity(0.08))
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
                    
                    // Queued players list or informative placeholder
                    if game.waitlistPlayerIds.isEmpty {
                        Text("Pool is full. Next players to sign up will queue here in order.")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 2)
                    } else {
                        ForEach(Array(game.waitlistPlayerIds.enumerated()), id: \.offset) { idx, wId in
                            let wp = dataManager.player(for: wId)
                            let wpName = wp.nickname.isEmpty ? wp.name : "\(wp.name) (\(wp.nickname))"
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
                                        .foregroundColor(Color(.label))
                                    Text(wp.rating.rawValue)
                                        .font(.system(size: 9))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                
                                let isHost = game.hostPlayerId == currentUserId || dataManager.currentUser?.isRoot == true
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
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(10)
        .background(Color(.systemGray6).opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func matchesSection(game: SetGame) -> some View {
        let isExpanded = expandedMatches.contains(game.id)
        let isCollapsed = !isExpanded
        return VStack(spacing: 6) {
            Button {
                if isExpanded {
                    expandedMatches.remove(game.id)
                } else {
                    expandedMatches.insert(game.id)
                }
            } label: {
                HStack {
                    Text("🥎 MATCHES IN THIS GAME (\(game.subMatches.count))")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(Color(.label))
                    Spacer()
                    Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(.label))
                }
            }
            .buttonStyle(.borderless)
            
            // Summary Row
            Button {
                if isExpanded {
                    expandedMatches.remove(game.id)
                } else {
                    expandedMatches.insert(game.id)
                }
            } label: {
                HStack {
                    HStack(spacing: 6) {
                        Text("🏐")
                        Text("Match Schedule (\(game.subMatches.count))")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(.label))
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        if !game.subMatches.isEmpty {
                            Text("🏐")
                            Text("🏐")
                        }
                        Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color(.systemGray6).opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.borderless)
            
            // Expanded sub-matches or Generate matches CTA
            if !isCollapsed {
                if game.subMatches.isEmpty {
                    VStack(spacing: 8) {
                        Text("No match rotations generated yet.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        
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
                                        .foregroundColor(Color(.label))
                                        .lineLimit(1)
                                    Spacer()
                                    Text("VS")
                                        .font(.system(size: 10, weight: .black))
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 6)
                                    Spacer()
                                    Text(resolveNames(sm.team2PlayerIds))
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(Color(.label))
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
                                            .foregroundColor(Color(.label))
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
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.separator).opacity(0.4), lineWidth: 0.8)
                            )
                        }
                        
                        Button {
                            gameForRandomTeams = game
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 11, weight: .bold))
                                Text("🎲 Regenerate / Adjust Matches")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundColor(Color(red: 0.92, green: 0.35, blue: 0.05))
                            .frame(maxWidth: .infinity, minHeight: 32)
                            .background(Color.orange.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.borderless)
                        .padding(.top, 2)
                    }
                }
            }
        }
    }

    private func cardFooter(game: SetGame, isMyGame: Bool, isHost: Bool) -> some View {
        VStack(spacing: 8) {
            Divider()
            
            // Top Row of Footer: Time on left, ADMIN ACTIONS • SETTINGS ▾ on right
            HStack {
                HStack(spacing: 4) {
                    Text("🕒")
                        .font(.system(size: 11))
                    Text(game.formattedDate)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
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
                    Button {
                        navigationPath.append(game.id)
                    } label: {
                        Label("Match Chat (\(game.messages.count))", systemImage: "message")
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
                            Label("Cancel Game (Delete)", systemImage: "xmark.circle")
                        }
                    }
                } label: {
                    HStack(spacing: 2) {
                        Text("ADMIN ACTIONS • SETTINGS")
                            .font(.system(size: 10, weight: .black))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .bold))
                    }
                    .foregroundColor(Color(.secondaryLabel))
                }
                .buttonStyle(.borderless)
            }
            
            // Bottom Row: Action Buttons
            HStack(spacing: 8) {
                // Left cluster: QR Code, Chat, Leave/Join Game
                Button {
                    qrGameForSheet = game
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: "qrcode")
                            .font(.system(size: 14, weight: .bold))
                        Text("QR\nCode")
                            .font(.system(size: 9, weight: .bold))
                            .multilineTextAlignment(.center)
                            .lineSpacing(-2)
                    }
                    .frame(width: 48, height: 46)
                    .background(Color(.systemBackground))
                    .foregroundColor(Color(.label))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.separator), lineWidth: 0.8)
                    )
                }
                .buttonStyle(.borderless)
                
                Button {
                    navigationPath.append(game.id)
                } label: {
                    ZStack(alignment: .topTrailing) {
                        VStack(spacing: 2) {
                            Image(systemName: "message.fill")
                                .font(.system(size: 14, weight: .bold))
                            Text("Chat\n(\(game.messages.count))")
                                .font(.system(size: 9, weight: .bold))
                                .multilineTextAlignment(.center)
                                .lineSpacing(-2)
                        }
                        .frame(width: 48, height: 46)
                        .background(Color(red: 0.94, green: 0.97, blue: 1.0))
                        .foregroundColor(Color(red: 0.01, green: 0.41, blue: 0.63))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(red: 0.73, green: 0.87, blue: 0.98), lineWidth: 0.8)
                        )
                        
                        if game.messages.count > 0 {
                            Text("\(game.messages.count)")
                                .font(.system(size: 8, weight: .black))
                                .foregroundColor(.white)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.red)
                                .clipShape(Capsule())
                                .offset(x: 4, y: -4)
                        }
                    }
                }
                .buttonStyle(.borderless)
                
                if isMyGame {
                    Button {
                        let res = dataManager.leaveGame(gameId: game.id)
                        alertMessage = res.message
                        showAlert = true
                    } label: {
                        VStack(spacing: 2) {
                            Text("Leave\nGame")
                                .font(.system(size: 10, weight: .black))
                                .multilineTextAlignment(.center)
                                .lineSpacing(-2)
                        }
                        .frame(width: 52, height: 46)
                        .background(Color(red: 0.99, green: 0.95, blue: 0.95))
                        .foregroundColor(Color(red: 0.73, green: 0.11, blue: 0.11))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(red: 0.99, green: 0.78, blue: 0.78), lineWidth: 0.8)
                        )
                    }
                    .buttonStyle(.borderless)
                } else if let uid = dataManager.currentUser?.id, game.waitlistPlayerIds.contains(uid) {
                    Button {
                        let res = dataManager.leaveWaitlist(gameId: game.id)
                        alertMessage = res.message
                        showAlert = true
                    } label: {
                        VStack(spacing: 2) {
                            Text("Leave\nWaitlist")
                                .font(.system(size: 9, weight: .black))
                                .multilineTextAlignment(.center)
                                .lineSpacing(-2)
                        }
                        .frame(width: 52, height: 46)
                        .background(Color.purple.opacity(0.1))
                        .foregroundColor(.purple)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.purple.opacity(0.3), lineWidth: 0.8)
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
                            Image(systemName: "figure.volleyball")
                                .font(.system(size: 13, weight: .bold))
                            Text("Join\nGame")
                                .font(.system(size: 9, weight: .black))
                                .multilineTextAlignment(.center)
                                .lineSpacing(-2)
                        }
                        .frame(width: 50, height: 46)
                        .background(Color(red: 0.94, green: 0.99, blue: 0.95))
                        .foregroundColor(Color(red: 0.09, green: 0.4, blue: 0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(red: 0.62, green: 0.93, blue: 0.71), lineWidth: 0.8)
                        )
                    }
                    .buttonStyle(.borderless)
                } else if game.spotsRemaining == 0 && !isMyGame {
                    Button {
                        let res = dataManager.joinWaitlist(gameId: game.id)
                        alertMessage = res.message
                        showAlert = true
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: "clock.badge.plus")
                                .font(.system(size: 13, weight: .bold))
                            Text("Join\nWaitlist")
                                .font(.system(size: 9, weight: .black))
                                .multilineTextAlignment(.center)
                                .lineSpacing(-2)
                        }
                        .frame(width: 52, height: 46)
                        .background(Color.purple.opacity(0.1))
                        .foregroundColor(.purple)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.purple.opacity(0.3), lineWidth: 0.8)
                        )
                    }
                    .buttonStyle(.borderless)
                }
                
                Spacer()
                
                // Right cluster: Edit, Delete Game (Root)
                Button {
                    editGameForSheet = game
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .bold))
                        Text("Edit")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .frame(width: 46, height: 46)
                    .background(Color(.systemBackground))
                    .foregroundColor(Color(.label))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.separator), lineWidth: 0.8)
                    )
                }
                .buttonStyle(.borderless)
                
                if (isHost && game.allPlayerIds.count <= 1) || dataManager.currentUser?.isRoot == true {
                    Button {
                        gameToDelete = game
                        showDeleteAlert = true
                    } label: {
                        VStack(spacing: 1) {
                            Image(systemName: "trash")
                                .font(.system(size: 12, weight: .bold))
                            Text("Delete\nGame\n(Root)")
                                .font(.system(size: 8, weight: .black))
                                .multilineTextAlignment(.center)
                                .lineSpacing(-3)
                        }
                        .frame(width: 52, height: 46)
                        .background(Color(red: 0.99, green: 0.95, blue: 0.95))
                        .foregroundColor(Color(red: 0.73, green: 0.11, blue: 0.11))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(red: 0.99, green: 0.78, blue: 0.78), lineWidth: 0.8)
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
        
        return VStack(alignment: .leading, spacing: 10) {
            cardHeader(game: game, isMyGame: isMyGame, isHost: isHost)
            cardMetadataLines(game: game)
            playersPoolBox(game: game, isMyGame: isMyGame, currentUserId: currentUserId)
            matchesSection(game: game)
            cardFooter(game: game, isMyGame: isMyGame, isHost: isHost)
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
    }
}
