import SwiftUI

public struct GameDetailView: View {
    @ObservedObject var dataManager: DataManager
    @ObservedObject private var weatherService = WeatherService.shared
    let gameId: UUID
    
    @Environment(\.dismiss) private var dismiss
    @State private var showEditSheet: Bool = false
    @State private var showRandomTeamsSheet: Bool = false
    @State private var showLeaveConfirmAlert: Bool = false
    @State private var showDeleteConfirmAlert: Bool = false
    @State private var chatInputText: String = ""
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false
    @State private var selectedSubMatchForScore: SubMatch? = nil
    @State private var showQRCodeSheet: Bool = false
    @State private var isMatchesCollapsed: Bool = true
    @State private var isPoolCollapsed: Bool = false
    @State private var isChatCollapsed: Bool = false
    @State private var playerToRemove: Player? = nil
    @State private var showRemovePlayerConfirmation: Bool = false
    
    public init(dataManager: DataManager, gameId: UUID) {
        self.dataManager = dataManager
        self.gameId = gameId
    }
    
    private var game: SetGame? {
        dataManager.games.first(where: { $0.id == gameId })
    }
    
    private var isHost: Bool {
        guard let g = game, let user = dataManager.currentUser else { return false }
        if let hid = g.hostPlayerId {
            return hid == user.id
        }
        return g.team1PlayerIds.first == user.id
    }
    
    private var isUserInMatch: Bool {
        guard let g = game, let user = dataManager.currentUser else { return false }
        return g.allPlayerIds.contains(user.id) || g.hostPlayerId == user.id
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
    
    public var body: some View {
        Group {
            if let game = game {
                ScrollView {
                    VStack(spacing: 18) {
                        // Header Card
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .center) {
                                if game.allowedRatings.count >= RatingTier.allCases.count {
                                    HStack(spacing: 4) {
                                        Image(systemName: "globe")
                                            .font(.system(size: 11, weight: .bold))
                                        Text("All Levels")
                                            .font(.system(size: 12, weight: .bold))
                                    }
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.12))
                                    .foregroundColor(.blue)
                                    .clipShape(Capsule())
                                } else if game.allowedRatings.count > 1 {
                                    HStack(spacing: 4) {
                                        ForEach(game.allowedRatings, id: \.self) { r in
                                            Text(r.rawValue)
                                                .font(.system(size: 11, weight: .bold))
                                                .padding(.horizontal, 7)
                                                .padding(.vertical, 3)
                                                .background(r.badgeColor.opacity(0.18))
                                                .foregroundColor(r.badgeColor)
                                                .clipShape(Capsule())
                                        }
                                    }
                                } else {
                                    RatingBadge(rating: game.targetRating, size: .regular)
                                }
                                
                                Spacer()
                                
                                Text(game.status.rawValue.uppercased())
                                    .font(.system(size: 11, weight: .black))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(game.status == .completed ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                                    .foregroundColor(game.status == .completed ? .green : .orange)
                                    .clipShape(Capsule())
                            }
                            
                            if game.isPrivate || game.isLevelLocked {
                                HStack(spacing: 6) {
                                    if game.isPrivate {
                                        HStack(spacing: 4) {
                                            Image(systemName: "lock.shield.fill")
                                                .font(.system(size: 9))
                                            Text("Private Game")
                                                .font(.system(size: 11, weight: .bold))
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.purple.opacity(0.15))
                                        .foregroundColor(.purple)
                                        .clipShape(Capsule())
                                    }
                                    if game.isLevelLocked {
                                        HStack(spacing: 5) {
                                            Image(systemName: "lock.fill")
                                                .font(.system(size: 9))
                                            Text("Level Locked • \(game.allowedRatingsDescription) only")
                                                .font(.system(size: 11, weight: .bold))
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.orange.opacity(0.15))
                                        .foregroundColor(.orange)
                                        .clipShape(Capsule())
                                    }
                                }
                            }
                            
                            Text(game.title)
                                .font(.system(size: 22, weight: .bold))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack(spacing: 14) {
                                Label(game.formattedDate, systemImage: "calendar")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Label("\(game.courtLocation) • \(game.courtNumber)", systemImage: "mappin.and.ellipse")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                            
                            if let host = hostPlayer(for: game) {
                                HStack(spacing: 6) {
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(.yellow)
                                    Text("Host: \(host.nickname.isEmpty ? host.name : host.nickname)")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.secondary)
                                    
                                    HStack(spacing: 2) {
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 9))
                                            .foregroundColor(.yellow)
                                        Text(host.formattedStarRating)
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.primary)
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(UIColor.tertiarySystemGroupedBackground))
                                    .clipShape(Capsule())
                                }
                            }
                            
                            if !game.notes.isEmpty {
                                Text(game.notes)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .padding(.top, 2)
                            }
                        }
                        .padding(18)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                        
                        // Score Summary Card (if completed)
                        if game.status == .completed {
                            VStack(spacing: 10) {
                                Text("FINAL MATCH SCORE")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 20) {
                                    VStack {
                                        Text("Team 1")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.orange)
                                        Text("\(game.team1SetsWon) Sets")
                                            .font(.system(size: 18, weight: .black))
                                    }
                                    
                                    Text("–")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.secondary)
                                    
                                    VStack {
                                        Text("Team 2")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.blue)
                                        Text("\(game.team2SetsWon) Sets")
                                            .font(.system(size: 18, weight: .black))
                                    }
                                }
                                
                                Text("Sets: \(game.scoreSummary)")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity)
                            .background(Color.green.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal)
                        }
                        
                        // Beach Volleyball Weather & Playing Conditions Card
                        weatherForecastCard(game: game)
                        
                        // Unified Players Pool
                        VStack(alignment: .leading, spacing: 12) {
                            Button {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    isPoolCollapsed.toggle()
                                }
                            } label: {
                                HStack {
                                    HStack(spacing: 6) {
                                        Image(systemName: isPoolCollapsed ? "chevron.right" : "chevron.down")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.secondary)
                                        Text("👥")
                                            .font(.system(size: 12))
                                        Text("PLAYER POOL (\(game.allPlayerIds.count) PLAYERS)")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    if game.isFull {
                                        Text("Pool Full ✓")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.green)
                                    } else {
                                        Text("\(game.spotsRemaining) Spot\(game.spotsRemaining > 1 ? "s" : "") Open")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.orange)
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal)
                            
                            if !isPoolCollapsed {
                                if game.allPlayerIds.count > 4 {
                                    VStack(spacing: 8) {
                                        ForEach(Array(game.allPlayerIds.enumerated()), id: \.offset) { index, pid in
                                            playerCard(dataManager.player(for: pid), game: game, playerIndex: index + 1)
                                        }
                                        
                                        if game.spotsRemaining > 0 && !isUserInMatch {
                                            if !game.isPrivate {
                                                Button {
                                                    let res = dataManager.joinGamePool(gameId: game.id)
                                                    if !res.success {
                                                        alertTitle = "Cannot Join Pool"
                                                        alertMessage = res.message
                                                        showAlert = true
                                                    }
                                                } label: {
                                                    HStack(spacing: 6) {
                                                        Image(systemName: game.isLevelLocked ? "lock.circle.dotted" : "person.badge.plus")
                                                        Text(game.isLevelLocked ? "Join (\(game.allowedRatingsDescription))" : "+ Join Player Pool")
                                                    }
                                                    .font(.system(size: 13, weight: .bold))
                                                    .foregroundColor(.orange)
                                                    .frame(maxWidth: .infinity)
                                                    .padding(12)
                                                    .background(Color.orange.opacity(0.08))
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                                                            .foregroundColor(.orange.opacity(0.5))
                                                    )
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                } else {
                                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                        ForEach(Array(game.allPlayerIds.enumerated()), id: \.offset) { index, pid in
                                            playerCard(dataManager.player(for: pid), game: game, playerIndex: index + 1)
                                        }
                                        
                                        if game.spotsRemaining > 0 && !isUserInMatch {
                                            if game.isPrivate {
                                                VStack(spacing: 4) {
                                                    Image(systemName: "lock.shield")
                                                        .font(.system(size: 18))
                                                        .foregroundColor(.secondary)
                                                    Text("Private Game • Invite Only")
                                                        .font(.system(size: 11, weight: .bold))
                                                        .foregroundColor(.secondary)
                                                        .lineLimit(1)
                                                }
                                                .padding(12)
                                                .frame(maxWidth: .infinity)
                                                .background(Color(UIColor.systemGray6))
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                            } else {
                                                Button {
                                                    let res = dataManager.joinGamePool(gameId: game.id)
                                                    if !res.success {
                                                        alertTitle = "Cannot Join Pool"
                                                        alertMessage = res.message
                                                        showAlert = true
                                                    }
                                                } label: {
                                                    VStack(spacing: 4) {
                                                        Image(systemName: game.isLevelLocked ? "lock.circle.dotted" : "person.badge.plus")
                                                            .font(.system(size: 18))
                                                            .foregroundColor(.orange)
                                                        Text(game.isLevelLocked ? "Join (\(game.allowedRatingsDescription))" : "+ Join Player Pool")
                                                            .font(.system(size: 11, weight: .bold))
                                                            .foregroundColor(.orange)
                                                            .lineLimit(1)
                                                    }
                                                    .padding(12)
                                                    .frame(maxWidth: .infinity)
                                                    .background(Color.orange.opacity(0.08))
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                                                            .foregroundColor(.orange.opacity(0.5))
                                                    )
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            
                            // Waitlist Section
                            waitlistSection(game: game)
                        }
                        
                        // Matches in this Game
                        VStack(alignment: .leading, spacing: 12) {
                            Button {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    isMatchesCollapsed.toggle()
                                }
                            } label: {
                                HStack {
                                    HStack(spacing: 6) {
                                        Image(systemName: "circle.grid.2x2.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.orange)
                                        Text("MATCHES IN THIS GAME")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.secondary)
                                        if !game.subMatches.isEmpty {
                                            Text("(\(game.subMatches.count))")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(.purple)
                                        }
                                    }
                                    Spacer()
                                    
                                    // Prominent, interactive Collapse/Expand capsule button
                                    HStack(spacing: 4) {
                                        Text(isMatchesCollapsed ? "Expand" : "Collapse")
                                            .font(.system(size: 11, weight: .bold))
                                        Image(systemName: isMatchesCollapsed ? "chevron.down" : "chevron.up")
                                            .font(.system(size: 10, weight: .bold))
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.purple.opacity(0.15))
                                    .foregroundColor(.purple)
                                    .clipShape(Capsule())
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal)
                            
                            if isMatchesCollapsed {
                                // Informative summary card showing matches are collapsed, tap to expand
                                Button {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        isMatchesCollapsed = false
                                    }
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "circle.grid.2x2.fill")
                                            .font(.system(size: 13))
                                            .foregroundColor(.purple)
                                        Text(game.subMatches.isEmpty ? "Matches section collapsed" : "\(game.subMatches.count) match\(game.subMatches.count > 1 ? "es" : "") hidden")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.primary)
                                        Spacer()
                                        HStack(spacing: 4) {
                                            Text("Tap to Expand")
                                                .font(.system(size: 11, weight: .bold))
                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 10, weight: .bold))
                                        }
                                        .foregroundColor(.purple)
                                    }
                                    .padding(14)
                                    .frame(maxWidth: .infinity)
                                    .background(Color(UIColor.secondarySystemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(Color.purple.opacity(0.25), lineWidth: 1)
                                    )
                                    .padding(.horizontal)
                                }
                                .buttonStyle(.plain)
                            } else {
                                if game.subMatches.isEmpty {
                                    VStack(spacing: 12) {
                                        Image(systemName: "dice.fill")
                                            .font(.system(size: 34))
                                            .foregroundColor(.purple)
                                        Text("No Matches Generated Yet")
                                            .font(.system(size: 15, weight: .bold))
                                        Text("Generate fair 2v2 doubles or King of the Court tournament matches for the \(game.allPlayerIds.count) players in this game's pool.")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal)
                                        
                                        Button {
                                            showRandomTeamsSheet = true
                                        } label: {
                                            HStack {
                                                Image(systemName: "dice.fill")
                                                Text("🎲 Random Generate Matches")
                                                    .fontWeight(.bold)
                                            }
                                            .padding(.horizontal, 18)
                                            .padding(.vertical, 10)
                                            .background(Color.purple)
                                            .foregroundColor(.white)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(20)
                                    .background(Color(UIColor.secondarySystemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .padding(.horizontal)
                                } else {
                                    VStack(spacing: 10) {
                                        ForEach(game.subMatches) { subM in
                                            subMatchCard(subM, game: game)
                                        }
                                        
                                        if isUserInMatch && game.status != .completed {
                                            Button {
                                                showRandomTeamsSheet = true
                                            } label: {
                                                HStack {
                                                    Image(systemName: "arrow.clockwise")
                                                    Text("Regenerate Matches")
                                                }
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(.purple)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 10)
                                                .background(Color.purple.opacity(0.1))
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        // Match Chat & Quick ETA Statuses (only shown if user is in the game)
                        if isUserInMatch {
                            matchChatSection(game: game)
                        }
                        
                        // Back Out / Leave Match Button (if user is registered in upcoming game)
                        if isUserInMatch && game.status != .completed {
                            Button(role: .destructive) {
                                showLeaveConfirmAlert = true
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.uturn.backward.circle.fill")
                                    Text("Leave Match / Back Out")
                                }
                                .font(.system(size: 14, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.red.opacity(0.1))
                                .foregroundColor(.red)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .padding(.horizontal)
                            .alert("Leave Match?", isPresented: $showLeaveConfirmAlert) {
                                Button("Cancel", role: .cancel) {}
                                Button("Leave Match", role: .destructive) {
                                    let res = dataManager.leaveGame(gameId: game.id)
                                    if !res.success {
                                        alertTitle = "Notice"
                                        alertMessage = res.message
                                        showAlert = true
                                    }
                                }
                            } message: {
                                Text("Are you sure you want to back out? Your spot will be reopened for other \(game.allowedRatingsDescription) beach players.")
                            }
                        }
                        
                        // Post-Match Peer Ratings (1 to 5 Stars)
                        if game.status == .completed && isUserInMatch {
                            peerRatingSection(game: game)
                        }
                        // QR Code Share Button (available for everyone to invite players!)
                        Button {
                            showQRCodeSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "qrcode")
                                Text("📱 Share / Show QR Code")
                            }
                            .font(.system(size: 15, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue.opacity(0.12))
                            .foregroundColor(.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)
                        
                        // Match Controls, Random Teams & Score Recording
                        VStack(spacing: 12) {
                            if isUserInMatch && game.status != .completed {
                                Button {
                                    showEditSheet = true
                                } label: {
                                    HStack {
                                        Image(systemName: "slider.horizontal.3")
                                        Text("Edit Match Preferences")
                                    }
                                    .font(.system(size: 15, weight: .bold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.orange.opacity(0.12))
                                    .foregroundColor(.orange)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                
                                Button {
                                    showRandomTeamsSheet = true
                                } label: {
                                    HStack {
                                        Image(systemName: "dice.fill")
                                        Text("🎲 Random Team Rotations")
                                    }
                                    .font(.system(size: 15, weight: .bold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.purple.opacity(0.12))
                                    .foregroundColor(.purple)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }

                                
                                if canHostCancelMatch(game: game) || (dataManager.currentUser?.isRoot == true) {
                                    if game.spotsRemaining == 0 {
                                        Button {
                                            let res = dataManager.addSpotToGame(gameId: game.id)
                                            alertTitle = "Game Capacity"
                                            alertMessage = res.message
                                            showAlert = true
                                        } label: {
                                            HStack {
                                                Image(systemName: "plus.circle.fill")
                                                Text("+ Add Spot to Full Game")
                                            }
                                            .font(.system(size: 15, weight: .bold))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(Color.blue.opacity(0.12))
                                            .foregroundColor(.blue)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                        }
                                    }
                                    
                                    Button(role: .destructive) {
                                        showDeleteConfirmAlert = true
                                    } label: {
                                        HStack {
                                            Image(systemName: "xmark.circle.fill")
                                            Text(dataManager.currentUser?.isRoot == true ? "🗑️ Delete Game (Root)" : "Cancel Game (Delete)")
                                        }
                                        .font(.system(size: 15, weight: .bold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color.red.opacity(0.12))
                                        .foregroundColor(.red)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                    .alert(dataManager.currentUser?.isRoot == true ? "Delete Game (Root)?" : "Cancel & Delete Game?", isPresented: $showDeleteConfirmAlert) {
                                        Button("Keep Game", role: .cancel) {}
                                        Button("Cancel Game", role: .destructive) {
                                            let res = dataManager.deleteGame(gameId: game.id)
                                            if res.success {
                                                dismiss()
                                            } else {
                                                alertTitle = "Notice"
                                                alertMessage = res.message
                                                showAlert = true
                                            }
                                        }
                                    } message: {
                                        Text(dataManager.currentUser?.isRoot == true ? "As Root Admin, deleting this game will remove it permanently from the schedule and database." : "As the match host, cancelling this game will delete it from the schedule and notify all participants.")
                                    }
                                }
                            } else if !isUserInMatch && game.status != .completed {
                                HStack(spacing: 6) {
                                    Image(systemName: "info.circle")
                                        .foregroundColor(.secondary)
                                    Text("Match participants can edit preferences and record final scores.")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.top, 4)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 6)
                    }
                    .padding(.bottom, 30)
                }

                .sheet(isPresented: $showEditSheet) {
                    EditMatchSheet(dataManager: dataManager, game: game)
                }
                .sheet(isPresented: $showRandomTeamsSheet) {
                    let matchPlayers = game.allPlayerIds.map { pid in
                        dataManager.player(for: pid)
                    }
                    RandomTeamGeneratorSheet(dataManager: dataManager, initialGameId: game.id, initialPlayers: matchPlayers, initialBeach: game.courtLocation, initialCourtNumber: game.courtNumber, initialFormat: game.format)
                }
                .sheet(item: $selectedSubMatchForScore) { subM in
                    RecordSubMatchScoreSheet(dataManager: dataManager, gameId: game.id, subMatch: subM)
                }
                .sheet(isPresented: $showQRCodeSheet) {
                    GameQRCodeSheet(game: game)
                }
            } else {
                Text("Game not found.")
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Game Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showQRCodeSheet = true
                } label: {
                    Image(systemName: "qrcode")
                        .font(.system(size: 16, weight: .bold))
                }
            }
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .alert("Remove Player from Match?", isPresented: $showRemovePlayerConfirmation) {
            Button("Cancel", role: .cancel) { playerToRemove = nil }
            Button("Remove", role: .destructive) {
                if let target = playerToRemove, let g = game {
                    let res = dataManager.removePlayerFromPool(gameId: g.id, playerId: target.id)
                    alertTitle = res.success ? "Player Removed" : "Error"
                    alertMessage = res.message
                    showAlert = true
                    playerToRemove = nil
                }
            }
        } message: {
            if let target = playerToRemove {
                Text("Are you sure you want to remove \(target.nickname.isEmpty ? target.name : target.nickname) from the player pool? If players are on the waitlist, the next player will be auto-promoted.")
            }
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private func waitlistSection(game: SetGame) -> some View {
        if game.isFull || game.spotsRemaining == 0 || !game.waitlistPlayerIds.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "clock.badge.checkmark.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.purple)
                    Text("WAITING (\(game.waitlistPlayerIds.count) QUEUED)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.purple)
                    Spacer()
                    Text("Auto-promotes or host/admin can add")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
                
                // Join / Leave controls if viewer is not an active player in match
                if !isUserInMatch {
                    if let user = dataManager.currentUser, game.isPlayerWaitlisted(user.id) {
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.purple)
                            Text("You are #\(game.waitlistPosition(for: user.id) ?? 1) on Waiting list")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.purple)
                            Spacer()
                            Button(role: .destructive) {
                                let res = dataManager.leaveWaitlist(gameId: game.id)
                                if !res.success {
                                    alertTitle = "Waiting"
                                    alertMessage = res.message
                                    showAlert = true
                                }
                            } label: {
                                Text("Leave Waiting")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.red.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(12)
                        .background(Color.purple.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.purple.opacity(0.3), lineWidth: 1)
                            )
                        } else if game.isFull || game.spotsRemaining == 0 {
                            if game.isPrivate {
                                HStack(spacing: 6) {
                                    Image(systemName: "lock.shield")
                                        .font(.system(size: 14, weight: .bold))
                                    Text("Private Game • Invite Only")
                                        .font(.system(size: 12, weight: .bold))
                                }
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Color(UIColor.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            } else {
                                Button {
                                    let res = dataManager.joinWaitlist(gameId: game.id)
                                    if !res.success {
                                        alertTitle = "Cannot Join Waiting"
                                        alertMessage = res.message
                                        showAlert = true
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "clock.badge.plus")
                                            .font(.system(size: 14, weight: .bold))
                                        Text("Pool Full • Join Waiting (\(game.waitlistPlayerIds.count) queued)")
                                            .font(.system(size: 12, weight: .bold))
                                    }
                                    .foregroundColor(.purple)
                                    .frame(maxWidth: .infinity)
                                    .padding(12)
                                    .background(Color.purple.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                                            .foregroundColor(.purple.opacity(0.5))
                                    )
                                }
                            }
                        }
                    }
                
                // Queued players list or informative placeholder
                if game.waitlistPlayerIds.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "hourglass")
                            .font(.system(size: 13))
                            .foregroundColor(.purple)
                        Text("No players currently on the waitlist. Next signups will appear here in queue order.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.purple.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    ForEach(Array(game.waitlistPlayerIds.enumerated()), id: \.offset) { index, pId in
                        waitlistRow(index: index, playerId: pId, gameId: game.id)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func waitlistRow(index: Int, playerId: UUID, gameId: UUID) -> some View {
        let p = dataManager.player(for: playerId)
        let isMe = dataManager.currentUser?.id == p.id
        let displayName = isUserInMatch ? (p.nickname.isEmpty ? p.name : p.nickname) : "Player \(index + 1)"
        return HStack(spacing: 12) {
            Text("#\(index + 1)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.purple)
                .clipShape(Circle())
            
            if isUserInMatch {
                PlayerAvatarView(player: p, dimension: 36)
            } else {
                ZStack {
                    Circle()
                        .fill(Color(UIColor.systemGray5))
                        .frame(width: 36, height: 36)
                    CourtAvatarIconView(avatarKey: "🏐", size: 24)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(displayName)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.primary)
                Text("Rating: \(p.rating.rawValue)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            let isHost = (game?.hostPlayerId == dataManager.currentUser?.id) || (dataManager.currentUser?.isRoot == true)
            if isHost {
                Button {
                    let res = dataManager.promoteWaitlistPlayer(gameId: gameId, playerId: playerId)
                    alertTitle = "Added to Game"
                    alertMessage = res.message
                    showAlert = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "person.badge.plus")
                        Text("Add to Game")
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.green)
                    .clipShape(Capsule())
                }
            }
            
            if isMe {
                Button(role: .destructive) {
                    dataManager.leaveWaitlist(gameId: gameId)
                } label: {
                    Text("Leave")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.red)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func canHostCancelMatch(game: SetGame) -> Bool {
        guard let user = dataManager.currentUser else { return false }
        if user.isRoot { return true }
        let userId = user.id
        let isHost = (game.hostPlayerId == userId) || (game.team1PlayerIds.first == userId)
        return isHost
    }
    
    private func playerCard(_ p: Player, game: SetGame, playerIndex: Int) -> some View {
        let isMatchHost = (game.hostPlayerId == dataManager.currentUser?.id) || (dataManager.currentUser?.isRoot == true)
        let displayName = isUserInMatch ? (p.nickname.isEmpty ? p.name : p.nickname) : "Player \(playerIndex)"
        return HStack(spacing: 8) {
            if game.allPlayerIds.count > 4 {
                Text("#\(playerIndex)")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(Color(red: 0.17, green: 0.43, blue: 0.48))
                    .frame(width: 24, height: 24)
                    .background(Color(red: 0.17, green: 0.43, blue: 0.48).opacity(0.15))
                    .clipShape(Circle())
            }
            
            if isUserInMatch {
                PlayerAvatarView(player: p, dimension: 36, showBadge: false)
            } else {
                ZStack {
                    Circle()
                        .fill(Color(UIColor.systemGray5))
                        .frame(width: 36, height: 36)
                    CourtAvatarIconView(avatarKey: "🏐", size: 24)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(displayName)
                        .font(.system(size: 13, weight: .bold))
                        .lineLimit(1)
                    
                    if p.id == game.hostPlayerId {
                        Text("HOST")
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.orange.opacity(0.18))
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                }
                
                HStack(spacing: 4) {
                    RatingBadge(rating: p.rating, size: .small)
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.yellow)
                        Text(p.formattedStarRating)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }
            }
            Spacer(minLength: 0)
            
            if isMatchHost && p.id != game.hostPlayerId {
                Button {
                    playerToRemove = p
                    showRemovePlayerConfirmation = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.red.opacity(0.85))
                }
                .buttonStyle(.borderless)
                .padding(.leading, 2)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private func emptySpotCard(teamNumber: Int, game: SetGame) -> some View {
        if game.isPrivate && !isUserInMatch {
            VStack(spacing: 4) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
                Text("Private Game")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(Color(UIColor.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        } else {
            Button {
                let res = dataManager.joinOpenGame(gameId: game.id, teamNumber: teamNumber)
                if !res.success {
                    alertTitle = "Cannot Join Match"
                    alertMessage = res.message
                    showAlert = true
                }
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: game.isLevelLocked ? "lock.circle.dotted" : "plus.circle.dashed")
                        .font(.system(size: 18))
                        .foregroundColor(.orange)
                    Text(game.isLevelLocked ? "Join (\(game.allowedRatingsDescription))" : "Open Spot")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.orange)
                        .lineLimit(1)
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(Color.orange.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                        .foregroundColor(.orange.opacity(0.5))
                )
            }
        }
    }
    
    private func peerRatingSection(game: SetGame) -> some View {
        let currentUserId = dataManager.currentUser?.id ?? UUID()
        let peers = (game.team1PlayerIds + game.team2PlayerIds).filter { $0 != currentUserId }
        let peerPlayers = peers.compactMap { pid in dataManager.players.first(where: { $0.id == pid }) }
        
        return VStack(alignment: .leading, spacing: 10) {
            Text("RATE PLAYERS (1-5 STARS)")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            VStack(spacing: 8) {
                ForEach(peerPlayers) { peer in
                    let submittedStar = game.submittedRatings[currentUserId]?[peer.id] ?? 0
                    
                    HStack {
                        PlayerAvatarView(player: peer, dimension: 32, showBadge: false)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(peer.nickname.isEmpty ? peer.name : peer.nickname)
                                .font(.system(size: 13, weight: .bold))
                            Text("Current: ⭐ \(peer.formattedStarRating)")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // 5 Interactive Stars
                        HStack(spacing: 4) {
                            ForEach(1...5, id: \.self) { star in
                                Button {
                                    dataManager.ratePlayer(gameId: game.id, targetPlayerId: peer.id, stars: star)
                                } label: {
                                    Image(systemName: star <= submittedStar ? "star.fill" : "star")
                                        .font(.system(size: 16))
                                        .foregroundColor(star <= submittedStar ? .yellow : .gray.opacity(0.5))
                                }
                            }
                        }
                    }
                    .padding(12)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Match Chat Section
    
    private func matchChatSection(game: SetGame) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .foregroundColor(.orange)
                    Text("CHAT")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    if !game.messages.isEmpty {
                        Text("(\(game.messages.count))")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
                
                // Interactive Collapse/Expand capsule button
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isChatCollapsed.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(isChatCollapsed ? "Expand" : "Collapse")
                            .font(.system(size: 11, weight: .bold))
                        Image(systemName: isChatCollapsed ? "chevron.down" : "chevron.up")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.orange.opacity(0.12))
                    .foregroundColor(.orange)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            
            if isChatCollapsed {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isChatCollapsed = false
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.orange)
                        Text(game.messages.isEmpty ? "Chat collapsed" : "\(game.messages.count) message\(game.messages.count > 1 ? "s" : "") hidden")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.primary)
                        Spacer()
                        HStack(spacing: 4) {
                            Text("Tap to Expand")
                                .font(.system(size: 11, weight: .bold))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(.orange)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            } else {
                // Quick Pre-text Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        quickChip(title: "🏃‍♂️ omw", text: "omw", gameId: game.id)
                        quickChip(title: "⏳ 5 min late", text: "5 min late", gameId: game.id)
                        quickChip(title: "⏰ 10 min late", text: "10 min late", gameId: game.id)
                        quickChip(title: "🏐 Got a court", text: "Got a court", gameId: game.id)
                    }
                    .padding(.vertical, 2)
                }
                
                // Messages Feed
                VStack(spacing: 8) {
                    if game.messages.isEmpty {
                        Text("No messages yet. Tap a quick status above or type a message below.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 12)
                    } else {
                        ForEach(game.messages) { msg in
                            let isMe = msg.senderId == dataManager.currentUser?.id
                            HStack {
                                if isMe { Spacer(minLength: 40) }
                                VStack(alignment: isMe ? .trailing : .leading, spacing: 2) {
                                    if !isMe {
                                        Text(msg.senderName)
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.secondary)
                                    }
                                    Text(msg.text)
                                        .font(.system(size: 13))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(isMe ? Color.orange : Color(UIColor.secondarySystemGroupedBackground))
                                        .foregroundColor(isMe ? .white : .primary)
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                    Text(msg.formattedTime)
                                        .font(.system(size: 9))
                                        .foregroundColor(.secondary)
                                }
                                if !isMe { Spacer(minLength: 40) }
                            }
                        }
                    }
                }
                .padding(10)
                .background(Color(UIColor.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                
                // Message Input
                if dataManager.currentUser != nil {
                    HStack(spacing: 8) {
                        TextField("Message match players...", text: $chatInputText)
                            .textFieldStyle(.roundedBorder)
                        
                        Button {
                            let text = chatInputText
                            chatInputText = ""
                            dataManager.sendMatchMessage(gameId: game.id, text: text)
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 26))
                                .foregroundColor(chatInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .secondary : .orange)
                        }
                        .disabled(chatInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                } else {
                    Text("Log in to send messages in match chat.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
    
    private func quickChip(title: String, text: String, gameId: UUID) -> some View {
        Button {
            dataManager.sendMatchMessage(gameId: gameId, text: text)
        } label: {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.12))
                .foregroundColor(.orange)
                .clipShape(Capsule())
        }
    }
    
    private func team1Players(for game: SetGame) -> [Player] {
        game.team1PlayerIds.map { pid in
            dataManager.player(for: pid)
        }
    }
    
    private func team2Players(for game: SetGame) -> [Player] {
        game.team2PlayerIds.map { pid in
            dataManager.player(for: pid)
        }
    }
    
    private func subMatchCard(_ match: SubMatch, game: SetGame) -> some View {
        let t1Players = match.team1PlayerIds.map { dataManager.player(for: $0) }
        let t2Players = match.team2PlayerIds.map { dataManager.player(for: $0) }
        let resting = match.restingPlayerIds.map { dataManager.player(for: $0) }
        
        let t1Names = t1Players.map { p in
            if !isUserInMatch {
                let idx = (game.allPlayerIds.firstIndex(of: p.id) ?? 0) + 1
                return "Player \(idx)"
            }
            return p.nickname.isEmpty ? p.name : p.nickname
        }.joined(separator: " & ")
        let t2Names = t2Players.map { p in
            if !isUserInMatch {
                let idx = (game.allPlayerIds.firstIndex(of: p.id) ?? 0) + 1
                return "Player \(idx)"
            }
            return p.nickname.isEmpty ? p.name : p.nickname
        }.joined(separator: " & ")
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("MATCH \(match.matchNumber)")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.orange)
                Text("•")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Text(match.courtNumber)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                if match.isCompleted {
                    Text("SCORED ✓")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.green)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Team 1")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(red: 0.98, green: 0.45, blue: 0.45).opacity(0.8))
                    Text(t1Names.isEmpty ? "Team 1" : t1Names)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(red: 0.98, green: 0.45, blue: 0.45))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("VS")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Team 2")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(red: 0.38, green: 0.75, blue: 0.98).opacity(0.8))
                    Text(t2Names.isEmpty ? "Team 2" : t2Names)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(red: 0.38, green: 0.75, blue: 0.98))
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            
            if !resting.isEmpty {
                let restingNames = resting.map { p in
                    if !isUserInMatch {
                        let idx = (game.allPlayerIds.firstIndex(of: p.id) ?? 0) + 1
                        return "Player \(idx)"
                    }
                    return p.nickname.isEmpty ? p.name : p.nickname
                }.joined(separator: ", ")
                Text("⏸ Resting: \(restingNames)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            HStack {
                if let s1 = match.team1Score, let s2 = match.team2Score {
                    HStack(spacing: 6) {
                        Text("\(s1) – \(s2)")
                            .font(.system(size: 15, weight: .black))
                        if match.winningTeam == 1 {
                            Text("(T1 Won)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.green)
                        } else if match.winningTeam == 2 {
                            Text("(T2 Won)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.green)
                        }
                    }
                } else {
                    Text("Scheduled • Unplayed")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    selectedSubMatchForScore = match
                } label: {
                    Text(match.isCompleted ? "Edit Score" : "Record Score")
                        .font(.system(size: 11, weight: .bold))
                }
                .buttonStyle(.bordered)
                .tint(.orange)
            }
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func weatherForecastCard(game: SetGame) -> some View {
        let forecast = weatherService.cachedForecast(for: game.courtLocation, on: game.scheduledDate)
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sun.max.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 15))
                    Text("BEACH VOLLEYBALL CONDITIONS")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                if let w = forecast {
                    Text("\(w.tempF)°F • \(w.conditionText)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                } else {
                    Text("Checking forecast...")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            
            if let w = forecast {
                HStack(spacing: 10) {
                    // Temperature Column
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TEMP")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                        HStack(spacing: 4) {
                            Text(w.conditionEmoji)
                                .font(.system(size: 16))
                            Text("\(w.tempF)°F")
                                .font(.system(size: 17, weight: .heavy))
                        }
                        Text(w.conditionText)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color(UIColor.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    // UV Index Column
                    VStack(alignment: .leading, spacing: 4) {
                        Text("UV INDEX")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                        HStack(spacing: 3) {
                            Text("☀️")
                                .font(.system(size: 14))
                            Text("\(Int(w.uvIndex.rounded()))")
                                .font(.system(size: 17, weight: .heavy))
                                .foregroundColor(w.uvColor)
                            Text("(\(w.uvCategory))")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(w.uvColor)
                                .lineLimit(1)
                        }
                        Text(w.uvCategory == "Low" ? "Low risk" : "Sunscreen advised")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color(UIColor.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    // Wind Column
                    VStack(alignment: .leading, spacing: 4) {
                        Text("WIND")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                        HStack(spacing: 4) {
                            Text("💨")
                                .font(.system(size: 14))
                            Text("\(w.windMph) mph")
                                .font(.system(size: 16, weight: .heavy))
                        }
                        Text(w.windCategory)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.blue)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color(UIColor.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                // Playability Guidance Footer
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top, spacing: 5) {
                        Image(systemName: "wind")
                            .font(.system(size: 10))
                            .foregroundColor(.blue)
                            .padding(.top, 2)
                        Text(w.windAdvice)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    HStack(alignment: .top, spacing: 5) {
                        Image(systemName: "sun.min.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                            .padding(.top, 2)
                        Text(w.uvSunscreenAdvice)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.top, 2)
            } else {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Fetching Open-Meteo forecast for \(game.courtLocation)...")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 6)
            }
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .onAppear {
            weatherService.loadForecast(for: game.courtLocation, on: game.scheduledDate)
        }
    }
}

public struct RecordSubMatchScoreSheet: View {
    @ObservedObject var dataManager: DataManager
    let gameId: UUID
    let subMatch: SubMatch
    @Environment(\.dismiss) private var dismiss
    
    @State private var team1Score: String
    @State private var team2Score: String
    
    public init(dataManager: DataManager, gameId: UUID, subMatch: SubMatch) {
        self.dataManager = dataManager
        self.gameId = gameId
        self.subMatch = subMatch
        _team1Score = State(initialValue: subMatch.team1Score != nil ? "\(subMatch.team1Score!)" : "21")
        _team2Score = State(initialValue: subMatch.team2Score != nil ? "\(subMatch.team2Score!)" : "18")
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section("Match Information") {
                    HStack {
                        Text("Match \(subMatch.matchNumber)")
                            .font(.headline)
                        Spacer()
                        Text(subMatch.courtNumber)
                            .font(.subheadline.bold())
                            .foregroundColor(.orange)
                    }
                }
                
                Section("Set Scores") {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Team 1")
                                .font(.caption.bold())
                                .foregroundColor(.orange)
                            ForEach(subMatch.team1PlayerIds.map { dataManager.player(for: $0) }) { p in
                                Text(p.name).font(.subheadline)
                            }
                            TextField("Points", text: $team1Score)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                        }
                        
                        Spacer()
                        Text("VS").font(.caption.bold()).foregroundColor(.secondary)
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Team 2")
                                .font(.caption.bold())
                                .foregroundColor(.blue)
                            ForEach(subMatch.team2PlayerIds.map { dataManager.player(for: $0) }) { p in
                                Text(p.name).font(.subheadline)
                            }
                            TextField("Points", text: $team2Score)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section {
                    Button("Save Match Score") {
                        if let s1 = Int(team1Score), let s2 = Int(team2Score) {
                            dataManager.updateSubMatchScore(gameId: gameId, matchId: subMatch.id, team1Score: s1, team2Score: s2)
                            dismiss()
                        }
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.green)
                }
            }
            .navigationTitle("Score Match \(subMatch.matchNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Match Chat Sheet
public struct MatchChatSheet: View {
    @ObservedObject var dataManager: DataManager
    let game: SetGame
    @Environment(\.dismiss) private var dismiss
    @State private var chatInputText: String = ""
    
    private var currentGame: SetGame {
        dataManager.games.first(where: { $0.id == game.id }) ?? game
    }
    
    private var isUserInMatch: Bool {
        guard let user = dataManager.currentUser else { return false }
        return currentGame.allPlayerIds.contains(user.id) || currentGame.hostPlayerId == user.id
    }
    
    public init(dataManager: DataManager, game: SetGame) {
        self.dataManager = dataManager
        self.game = game
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header Info Bar
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(currentGame.title)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        HStack(spacing: 6) {
                            Text("📍 \(currentGame.courtLocation) • \(currentGame.courtNumber)")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            Text("•")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            Text(currentGame.formattedDate)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(UIColor.secondarySystemBackground))
                
                Divider()
                
                if !isUserInMatch {
                    VStack(spacing: 12) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.secondary.opacity(0.7))
                            .padding(.top, 40)
                        Text("Chat Restricted")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.primary)
                        Text("Only confirmed players in this match can view and send chat messages.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Quick Status / ETA Chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            quickChip(title: "🏃‍♂️ omw", text: "omw")
                            quickChip(title: "⏳ 5 min late", text: "5 min late")
                            quickChip(title: "⏰ 10 min late", text: "10 min late")
                            quickChip(title: "🏐 Got a court", text: "Got a court")
                            quickChip(title: "👋 Ready to play!", text: "Ready to play!")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    .background(Color(UIColor.systemBackground))
                    
                    Divider()
                
                // Messages Scroll List
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if currentGame.messages.isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: "bubble.left.and.bubble.right")
                                        .font(.system(size: 36))
                                        .foregroundColor(.secondary.opacity(0.6))
                                        .padding(.top, 40)
                                    Text("No messages yet")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.secondary)
                                    Text("Tap a quick ETA chip above or send a message below to coordinate with players.")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 32)
                                }
                            } else {
                                ForEach(currentGame.messages) { msg in
                                    let isMe = msg.senderId == dataManager.currentUser?.id
                                    HStack(alignment: .bottom, spacing: 8) {
                                        if isMe { Spacer(minLength: 40) }
                                        
                                        if !isMe {
                                            let sender = dataManager.player(for: msg.senderId)
                                            PlayerAvatarView(player: sender, dimension: 28, showBadge: false)
                                        }
                                        
                                        VStack(alignment: isMe ? .trailing : .leading, spacing: 2) {
                                            if !isMe {
                                                Text(msg.senderName)
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundColor(.secondary)
                                                    .padding(.horizontal, 4)
                                            }
                                            
                                            Text(msg.text)
                                                .font(.system(size: 14))
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 9)
                                                .background(isMe ? Color.orange : Color(UIColor.secondarySystemBackground))
                                                .foregroundColor(isMe ? .white : Color(.label))
                                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                            
                                            Text(msg.formattedTime)
                                                .font(.system(size: 9))
                                                .foregroundColor(.secondary)
                                                .padding(.horizontal, 4)
                                        }
                                        .id(msg.id)
                                        
                                        if !isMe { Spacer(minLength: 40) }
                                    }
                                }
                            }
                        }
                        .padding(16)
                    }
                    .onChange(of: currentGame.messages.count) { _, _ in
                        if let lastMsg = currentGame.messages.last {
                            withAnimation(.easeOut(duration: 0.25)) {
                                proxy.scrollTo(lastMsg.id, anchor: .bottom)
                            }
                        }
                    }
                    .onAppear {
                        if let lastMsg = currentGame.messages.last {
                            proxy.scrollTo(lastMsg.id, anchor: .bottom)
                        }
                    }
                }
                
                Divider()
                
                // Bottom Input Bar
                HStack(spacing: 10) {
                    if dataManager.currentUser != nil {
                        TextField("Type a message or ETA...", text: $chatInputText)
                            .font(.system(size: 14))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color(UIColor.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .submitLabel(.send)
                            .onSubmit {
                                sendMessage()
                            }
                        
                        Button {
                            sendMessage()
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(chatInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .secondary : .orange)
                        }
                        .disabled(chatInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    } else {
                        Text("Please log in to send messages in match chat.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(UIColor.systemBackground))
                }
            }
            .navigationTitle("Match Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                }
            }
        }
    }
    
    private func quickChip(title: String, text: String) -> some View {
        Button {
            dataManager.sendMatchMessage(gameId: currentGame.id, text: text)
        } label: {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.12))
                .foregroundColor(.orange)
                .clipShape(Capsule())
        }
    }
    
    private func sendMessage() {
        let text = chatInputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        chatInputText = ""
        dataManager.sendMatchMessage(gameId: currentGame.id, text: text)
    }
}
