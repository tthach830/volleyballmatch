import SwiftUI
import Combine

public class DataManager: ObservableObject {
    public static let shared = DataManager()
    
    @Published public var currentUser: Player?
    @Published public var players: [Player] = []
    @Published public var games: [SetGame] = []
    @Published public var availabilitySlots: [AvailabilitySlot] = []
    @Published public var pickupQueue: [Player] = []
    @Published public var notifications: [AppNotification] = []
    
    public init() {
        if !loadFromDisk() {
            loadMockCommunityData()
        }
        setupFirestoreSync()
    }
    
    public var unreadNotificationsCount: Int {
        notifications.filter { !$0.isRead }.count
    }
    
    public func markAllNotificationsRead() {
        for i in 0..<notifications.count {
            notifications[i].isRead = true
        }
    }
    
    public func postNotification(
        title: String,
        message: String,
        type: NotificationType,
        relatedGameId: UUID? = nil
    ) {
        let notif = AppNotification(
            title: title,
            message: message,
            type: type,
            relatedGameId: relatedGameId
        )
        notifications.insert(notif, at: 0)
        NotificationService.shared.sendSystemNotification(title: title, body: message)
        NotificationService.shared.triggerInAppToast(notif)
    }
    
    // MARK: - User Session & Sign Up / Login
    
    public static func normalizePhoneNumber(_ phone: String) -> String {
        phone.filter { $0.isNumber }
    }
    
    public func loginWithPhone(phoneNumber: String, password: String) -> (success: Bool, message: String) {
        let cleaned = DataManager.normalizePhoneNumber(phoneNumber)
        guard !cleaned.isEmpty else {
            return (false, "Please enter your phone number.")
        }
        guard !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return (false, "Please enter your password.")
        }
        
        if let player = players.first(where: {
            let pCleaned = DataManager.normalizePhoneNumber($0.phoneNumber)
            return (!pCleaned.isEmpty && pCleaned == cleaned) || $0.phoneNumber == phoneNumber
        }) {
            if !player.password.isEmpty && player.password != password {
                return (false, "Incorrect password. Please try again.")
            }
            currentUser = player
            saveToDisk()
            NotificationService.shared.requestPermission()
            return (true, "Welcome back, \(player.nickname.isEmpty ? player.name : player.nickname)!")
        } else {
            return (false, "No player found with this phone number. Please tap 'New Player' below to register!")
        }
    }
    
    public func signUp(
        phoneNumber: String = "",
        password: String = "",
        name: String,
        nickname: String,
        rating: RatingTier,
        homeBeach: String,
        avatarEmoji: String
    ) {
        let baseElo: Int
        switch rating {
        case .novice: baseElo = 1100
        case .intermediate: baseElo = 1350
        case .b: baseElo = 1550
        case .a: baseElo = 1800
        case .aa: baseElo = 2100
        case .open: baseElo = 2400
        }
        
        let newPlayer = Player(
            name: name,
            nickname: nickname.isEmpty ? name : nickname,
            avatarEmoji: avatarEmoji,
            rating: rating,
            eloRating: baseElo,
            homeBeach: homeBeach,
            phoneNumber: phoneNumber,
            password: password,
            wins: 0,
            losses: 0,
            streak: 0,
            pointsScored: 0,
            pointsAllowed: 0,
            uniquePartnerIds: [],
            uniqueOpponentIds: [],
            recentForm: [],
            bio: "Ready to bump, set, and spike on the sand!"
        )
        
        players.append(newPlayer)
        currentUser = newPlayer
        NotificationService.shared.requestPermission()
        
        // Auto-create initial availability slot for this new user for this weekend
        let cal = Calendar.current
        let nextSaturday = cal.nextDate(after: Date(), matching: DateComponents(weekday: 7), matchingPolicy: .nextTime) ?? Date()
        let start = cal.date(bySettingHour: 9, minute: 0, second: 0, of: nextSaturday) ?? Date()
        let end = cal.date(bySettingHour: 11, minute: 30, second: 0, of: nextSaturday) ?? Date()
        
        let initialSlot = AvailabilitySlot(
            playerId: newPlayer.id,
            date: nextSaturday,
            startTime: start,
            endTime: end,
            preferredBeach: homeBeach,
            acceptedTiers: [rating]
        )
        availabilitySlots.append(initialSlot)
        saveToDisk()
        FirestoreService.shared.savePlayer(newPlayer)
        FirestoreService.shared.saveAvailabilitySlot(initialSlot)
    }
    
    public func switchUser(to player: Player) {
        currentUser = player
        saveToDisk()
    }
    
    public func logOut() {
        currentUser = nil
        saveToDisk()
    }
    
    // MARK: - Matchmaking & Game Operations
    
    public func runAutoMatchmaking() -> Int {
        let newMatches = MatchmakingEngine.shared.findAutoMatches(
            slots: availabilitySlots,
            players: players
        )
        
        var addedCount = 0
        for match in newMatches {
            let game = SetGame(
                title: "\(match.averageTier.rawValue) Beach Doubles Set",
                targetRating: match.averageTier,
                format: .bestOfThree,
                status: .scheduled,
                scheduledDate: match.scheduledDate,
                courtLocation: match.courtName,
                courtNumber: "Court #\(Int.random(in: 1...8))",
                team1PlayerIds: match.team1.map { $0.id },
                team2PlayerIds: match.team2.map { $0.id },
                isAutoMatched: true,
                matchedOptionName: match.matchingMethod
            )
            games.insert(game, at: 0)
            addedCount += 1
            saveToDisk()
            FirestoreService.shared.saveGame(game)
            
            postNotification(
                title: "🏐 Set Game Confirmed!",
                message: "You've been paired for \(game.title) at \(game.courtLocation)!",
                type: .matchConfirmed,
                relatedGameId: game.id
            )
            
            // Mark slots as matched
            let matchedPlayerIds = Set(match.matchedPlayers.map { $0.id })
            for i in 0..<availabilitySlots.count {
                if matchedPlayerIds.contains(availabilitySlots[i].playerId) {
                    availabilitySlots[i].isMatched = true
                    FirestoreService.shared.saveAvailabilitySlot(availabilitySlots[i])
                }
            }
        }
        return addedCount
    }
    
    public func addAvailability(
        date: Date,
        startTime: Date,
        endTime: Date,
        beach: String,
        tiers: [RatingTier],
        allowPlusMinus: Bool
    ) {
        guard let user = currentUser else { return }
        let slot = AvailabilitySlot(
            playerId: user.id,
            date: date,
            startTime: startTime,
            endTime: endTime,
            preferredBeach: beach,
            acceptedTiers: tiers,
            allowPlusMinusOneTier: allowPlusMinus
        )
        availabilitySlots.append(slot)
        saveToDisk()
        FirestoreService.shared.saveAvailabilitySlot(slot)
    }
    
    public func joinPickupQueue() {
        guard let user = currentUser else { return }
        if !pickupQueue.contains(where: { $0.id == user.id }) {
            pickupQueue.append(user)
            
            // If 4 players in pickup queue, auto-lock into a game!
            if pickupQueue.count >= 4 {
                let four = Array(pickupQueue.prefix(4))
                pickupQueue.removeFirst(4)
                
                let sorted = four.sorted { $0.eloRating > $1.eloRating }
                let team1 = [sorted[0], sorted[3]]
                let team2 = [sorted[1], sorted[2]]
                
                let fastGame = SetGame(
                    title: "Fast Pickup 2v2",
                    targetRating: user.rating,
                    format: .bestOfThree,
                    status: .scheduled,
                    scheduledDate: Date().addingTimeInterval(3600 * 2),
                    courtLocation: user.homeBeach,
                    courtNumber: "Court #2",
                    team1PlayerIds: team1.map { $0.id },
                    team2PlayerIds: team2.map { $0.id },
                    isAutoMatched: true,
                    matchedOptionName: "Instant Pickup Lobby"
                )
                games.insert(fastGame, at: 0)
                saveToDisk()
                FirestoreService.shared.saveGame(fastGame)
                
                postNotification(
                    title: "⚡️ Pickup Lobby Full (4/4)!",
                    message: "Your fast pickup game at \(user.homeBeach) is locked and ready!",
                    type: .queueUpdate,
                    relatedGameId: fastGame.id
                )
            }
        }
    }
    
    public func leavePickupQueue() {
        guard let user = currentUser else { return }
        pickupQueue.removeAll(where: { $0.id == user.id })
    }
    
    @discardableResult
    public func joinOpenGame(gameId: UUID, teamNumber: Int) -> (success: Bool, message: String) {
        guard let user = currentUser,
              let index = games.firstIndex(where: { $0.id == gameId }) else {
            return (false, "Please log in to join this match.")
        }
        
        var game = games[index]
        if game.allPlayerIds.contains(user.id) {
            return (false, "You are already in this match!")
        }
        
        // Level Lock Check
        if game.isLevelLocked && !game.isPlayerTierAllowed(user.rating) {
            return (false, "Level Locked: This match is locked to \(game.allowedRatingsDescription) players only. Your current rating is \(user.rating.rawValue).")
        }
        
        let capacity = game.teamCapacity
        if teamNumber == 1 && game.team1PlayerIds.count < capacity {
            game.team1PlayerIds.append(user.id)
        } else if teamNumber == 2 && game.team2PlayerIds.count < capacity {
            game.team2PlayerIds.append(user.id)
        } else if game.team1PlayerIds.count < capacity {
            game.team1PlayerIds.append(user.id)
        } else if game.team2PlayerIds.count < capacity {
            game.team2PlayerIds.append(user.id)
        } else {
            return (false, "Sorry, this match is already full!")
        }
        
        games[index] = game
        saveToDisk()
        FirestoreService.shared.saveGame(game)
        return (true, "Successfully joined \(game.title)!")
    }
    
    @discardableResult
    public func joinGamePool(gameId: UUID) -> (success: Bool, message: String) {
        joinOpenGame(gameId: gameId, teamNumber: 1)
    }
    
    @discardableResult
    public func joinWaitlist(gameId: UUID) -> (success: Bool, message: String) {
        guard let user = currentUser,
              let index = games.firstIndex(where: { $0.id == gameId }) else {
            return (false, "Please log in to join the waitlist.")
        }
        
        var game = games[index]
        if game.allPlayerIds.contains(user.id) {
            return (false, "You are already an active player in this game!")
        }
        if game.waitlistPlayerIds.contains(user.id) {
            return (false, "You are already on the waitlist for this game.")
        }
        
        // Level Lock Check
        if game.isLevelLocked && !game.isPlayerTierAllowed(user.rating) {
            return (false, "Level Locked: This match is locked to \(game.allowedRatingsDescription) players only. Your current rating is \(user.rating.rawValue).")
        }
        
        game.waitlistPlayerIds.append(user.id)
        games[index] = game
        saveToDisk()
        FirestoreService.shared.saveGame(game)
        let pos = game.waitlistPlayerIds.count
        return (true, "Added to waitlist (#\(pos)) for \(game.title)!")
    }
    
    @discardableResult
    public func leaveWaitlist(gameId: UUID) -> (success: Bool, message: String) {
        guard let user = currentUser,
              let index = games.firstIndex(where: { $0.id == gameId }) else {
            return (false, "Game not found.")
        }
        
        var game = games[index]
        guard game.waitlistPlayerIds.contains(user.id) else {
            return (false, "You are not on the waitlist.")
        }
        
        game.waitlistPlayerIds.removeAll(where: { $0 == user.id })
        games[index] = game
        saveToDisk()
        FirestoreService.shared.saveGame(game)
        return (true, "Removed from waitlist.")
    }
    
    @discardableResult
    public func saveSubMatches(gameId: UUID, matches: [SubMatch]) -> Bool {
        guard let index = games.firstIndex(where: { $0.id == gameId }) else { return false }
        games[index].subMatches = matches
        saveToDisk()
        FirestoreService.shared.saveGame(games[index])
        return true
    }
    
    @discardableResult
    public func updateSubMatchScore(gameId: UUID, matchId: UUID, team1Score: Int, team2Score: Int) -> Bool {
        guard let gIdx = games.firstIndex(where: { $0.id == gameId }) else { return false }
        guard let mIdx = games[gIdx].subMatches.firstIndex(where: { $0.id == matchId }) else { return false }
        games[gIdx].subMatches[mIdx].team1Score = team1Score
        games[gIdx].subMatches[mIdx].team2Score = team2Score
        games[gIdx].subMatches[mIdx].isCompleted = true
        games[gIdx].subMatches[mIdx].winningTeam = team1Score > team2Score ? 1 : 2
        
        if !games[gIdx].subMatches.isEmpty && games[gIdx].subMatches.allSatisfy({ $0.isCompleted }) {
            games[gIdx].status = .completed
        }
        
        saveToDisk()
        FirestoreService.shared.saveGame(games[gIdx])
        return true
    }
    
    @discardableResult
    public func leaveGame(gameId: UUID) -> (success: Bool, message: String) {
        guard let user = currentUser,
              let index = games.firstIndex(where: { $0.id == gameId }) else {
            return (false, "Game not found.")
        }
        
        var game = games[index]
        
        // If user was on the waitlist instead of the active pool, just remove from waitlist
        if game.waitlistPlayerIds.contains(user.id) {
            return leaveWaitlist(gameId: gameId)
        }
        
        guard game.allPlayerIds.contains(user.id) else {
            return (false, "You are not registered in this match.")
        }
        
        game.team1PlayerIds.removeAll(where: { $0 == user.id })
        game.team2PlayerIds.removeAll(where: { $0 == user.id })
        
        // Auto-promote first waitlisted player into the open spot
        var promotedName: String? = nil
        if !game.waitlistPlayerIds.isEmpty && game.allPlayerIds.count < game.maxPlayers {
            let promotedId = game.waitlistPlayerIds.removeFirst()
            if game.team1PlayerIds.count <= game.team2PlayerIds.count {
                game.team1PlayerIds.append(promotedId)
            } else {
                game.team2PlayerIds.append(promotedId)
            }
            if let p = players.first(where: { $0.id == promotedId }) {
                promotedName = p.nickname.isEmpty ? p.name : p.nickname
            }
        }
        
        // If host leaves, reassign to another player if any remain
        if game.hostPlayerId == user.id {
            game.hostPlayerId = game.allPlayerIds.first
        }
        
        // Increment consecutive backouts & check flaker flag (3x in a row)
        var isFlakerNow = false
        if let pIdx = players.firstIndex(where: { $0.id == user.id }) {
            players[pIdx].consecutiveBackouts += 1
            isFlakerNow = players[pIdx].isFlaker
            currentUser = players[pIdx]
            FirestoreService.shared.savePlayer(players[pIdx])
        }
        
        games[index] = game
        saveToDisk()
        FirestoreService.shared.saveGame(game)
        
        if let promoted = promotedName {
            postNotification(
                title: "🎉 Waitlist Promotion",
                message: "\(promoted) was auto-promoted from the waitlist into \(game.title)!",
                type: .matchInvite,
                relatedGameId: game.id
            )
        }
        
        postNotification(
            title: isFlakerNow ? "⚠️ Flaker Penalty Applied (F)" : "⚠️ Player Backed Out",
            message: isFlakerNow ?
                "\(user.nickname.isEmpty ? user.name : user.nickname) backed out 3 times in a row: flagged as Flaker (F) and rating lowered by 1 point." :
                "\(user.nickname.isEmpty ? user.name : user.nickname) had to leave \(game.title). A spot is now open!",
            type: .matchInvite,
            relatedGameId: game.id
        )
        
        let msg = isFlakerNow ?
            "You have left the match. Notice: You backed out 3 times in a row. You received an 'F' flaker badge and your rating has been lowered by 1 point. Complete a match to restore it." :
            (promotedName != nil ?
                "You left the match. \(promotedName!) has been moved from the waitlist into your spot." :
                "You have left the match. Your spot has been reopened.")
        return (true, msg)
    }
    
    @discardableResult
    public func updateGamePreferences(
        gameId: UUID,
        title: String,
        targetRating: RatingTier,
        allowedRatings: [RatingTier]? = nil,
        format: GameFormat,
        maxPlayers: Int = 4,
        scheduledDate: Date,
        courtLocation: String,
        courtNumber: String,
        isLevelLocked: Bool,
        notes: String
    ) -> (success: Bool, message: String) {
        guard let user = currentUser,
              let index = games.firstIndex(where: { $0.id == gameId }) else {
            return (false, "Match not found.")
        }
        
        var game = games[index]
        let isParticipant = game.allPlayerIds.contains(user.id) || (game.hostPlayerId == user.id)
        guard isParticipant else {
            return (false, "Only players in this match can update match preferences.")
        }
        
        game.title = title
        if let allowed = allowedRatings, !allowed.isEmpty {
            game.allowedRatings = allowed
            game.targetRating = allowed.first ?? targetRating
        } else {
            game.targetRating = targetRating
            game.allowedRatings = [targetRating]
        }
        game.format = format
        game.maxPlayers = max(2, maxPlayers)
        game.scheduledDate = scheduledDate
        game.courtLocation = courtLocation
        game.courtNumber = courtNumber
        game.isLevelLocked = isLevelLocked
        game.notes = notes
        
        games[index] = game
        saveToDisk()
        FirestoreService.shared.saveGame(game)
        return (true, "Match preferences updated successfully!")
    }
    
    @discardableResult
    public func deleteGame(gameId: UUID) -> (success: Bool, message: String) {
        guard let user = currentUser,
              let index = games.firstIndex(where: { $0.id == gameId }) else {
            return (false, "Game not found.")
        }
        
        let game = games[index]
        if !user.isRoot {
            let isHost = (game.hostPlayerId == user.id) || (game.team1PlayerIds.first == user.id)
            guard isHost else {
                return (false, "Only the game host or Root user can delete this game.")
            }
            
            let otherPlayers = game.allPlayerIds.filter { $0 != user.id }
            guard otherPlayers.isEmpty else {
                return (false, "Cannot delete game while other players are joined. Players must back out first.")
            }
        }
        
        games.remove(at: index)
        saveToDisk()
        FirestoreService.shared.deleteGame(id: gameId, rawId: game.rawId)
        return (true, "Game deleted.")
    }
    
    @discardableResult
    public func deleteAllGames() -> (success: Bool, count: Int) {
        guard let user = currentUser, user.isRoot else {
            return (false, 0)
        }
        let count = games.count
        let allGames = games
        games.removeAll()
        saveToDisk()
        for g in allGames {
            FirestoreService.shared.deleteGame(id: g.id, rawId: g.rawId)
        }
        return (true, count)
    }
    
    public func updateCurrentUserProfile(
        name: String,
        nickname: String,
        avatarEmoji: String,
        rating: RatingTier,
        homeBeach: String,
        phoneNumber: String,
        bio: String
    ) {
        guard var user = currentUser else { return }
        user.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        user.nickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        user.avatarEmoji = avatarEmoji
        user.rating = rating
        user.homeBeach = homeBeach.trimmingCharacters(in: .whitespacesAndNewlines)
        user.phoneNumber = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        user.bio = bio.trimmingCharacters(in: .whitespacesAndNewlines)
        
        currentUser = user
        if let idx = players.firstIndex(where: { $0.id == user.id }) {
            players[idx] = user
        } else {
            players.append(user)
        }
        saveToDisk()
        FirestoreService.shared.savePlayer(user)
    }
    
    public func player(for id: UUID) -> Player {
        if let found = players.first(where: { $0.id == id }) {
            return found
        }
        return Player(
            id: id,
            name: "Beach Player",
            nickname: "Player",
            avatarEmoji: "🏐",
            rating: .b,
            eloRating: 1500,
            homeBeach: "Main Beach"
        )
    }
    
    @discardableResult
    public func sendMatchMessage(gameId: UUID, text: String) -> (success: Bool, message: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return (false, "Message cannot be empty.")
        }
        guard let user = currentUser,
              let index = games.firstIndex(where: { $0.id == gameId }) else {
            return (false, "Match not found.")
        }
        
        let senderName = user.nickname.isEmpty ? user.name : user.nickname
        let newMsg = GameChatMessage(
            senderId: user.id,
            senderName: senderName,
            text: trimmed,
            date: Date()
        )
        
        games[index].messages.append(newMsg)
        saveToDisk()
        FirestoreService.shared.saveGame(games[index])
        
        // Notify other players in this match
        let game = games[index]
        let otherPlayerIds = game.allPlayerIds.filter { $0 != user.id }
        if !otherPlayerIds.isEmpty {
            postNotification(
                title: "Match Chat: \(game.title)",
                message: "\(senderName): \"\(trimmed)\"",
                type: .matchInvite,
                relatedGameId: game.id
            )
        }
        
        return (true, "Message sent!")
    }
    
    @discardableResult
    public func createMatch(
        title: String,
        targetRating: RatingTier,
        allowedRatings: [RatingTier] = [],
        format: GameFormat = .bestOfThree,
        courtLocation: String = "Main Beach",
        courtNumber: String = "Court #1",
        scheduledDate: Date,
        isLevelLocked: Bool = true,
        maxPlayers: Int = 4,
        notes: String = ""
    ) -> SetGame {
        let hostId = currentUser?.id ?? UUID()
        let effectiveAllowed = allowedRatings.isEmpty ? [targetRating] : allowedRatings
        let primaryRating = effectiveAllowed.first ?? targetRating
        let defaultTitle = effectiveAllowed.count > 1 ? "\(effectiveAllowed.map { $0.rawValue }.joined(separator: "/")) Match" : "\(primaryRating.rawValue) Match"
        let newGame = SetGame(
            title: title.isEmpty ? defaultTitle : title,
            targetRating: primaryRating,
            allowedRatings: effectiveAllowed,
            format: format,
            status: .scheduled,
            scheduledDate: scheduledDate,
            courtLocation: courtLocation,
            courtNumber: courtNumber,
            maxPlayers: maxPlayers,
            team1PlayerIds: currentUser != nil ? [hostId] : [],
            team2PlayerIds: [],
            isAutoMatched: false,
            matchedOptionName: "Community Open Match",
            notes: notes,
            hostPlayerId: hostId,
            isLevelLocked: isLevelLocked
        )
        
        games.insert(newGame, at: 0)
        saveToDisk()
        FirestoreService.shared.saveGame(newGame)
        
        postNotification(
            title: "🏐 New Match Scheduled",
            message: "\(newGame.title) was scheduled at \(newGame.courtLocation). Join now!",
            type: .matchConfirmed,
            relatedGameId: newGame.id
        )
        return newGame
    }
    
    @discardableResult
    public func ratePlayer(gameId: UUID, targetPlayerId: UUID, stars: Int) -> (success: Bool, message: String) {
        guard let user = currentUser,
              let gIndex = games.firstIndex(where: { $0.id == gameId }) else {
            return (false, "Match not found.")
        }
        guard stars >= 1 && stars <= 5 else {
            return (false, "Rating must be between 1 and 5 stars.")
        }
        
        var game = games[gIndex]
        if game.submittedRatings[user.id] == nil {
            game.submittedRatings[user.id] = [:]
        }
        game.submittedRatings[user.id]?[targetPlayerId] = stars
        games[gIndex] = game
        
        if let pIndex = players.firstIndex(where: { $0.id == targetPlayerId }) {
            var player = players[pIndex]
            player.starRatingSum += stars
            player.starRatingCount += 1
            players[pIndex] = player
            if currentUser?.id == targetPlayerId {
                currentUser = player
            }
            FirestoreService.shared.savePlayer(player)
        }
        
        saveToDisk()
        FirestoreService.shared.saveGame(game)
        return (true, "Rating of \(stars) ⭐ submitted!")
    }
    
    public func recordScore(gameId: UUID, winningTeam: Int, setScores: [SetScore]) {
        guard let index = games.firstIndex(where: { $0.id == gameId }) else { return }
        var game = games[index]
        
        StatsManager.shared.applyMatchResult(
            game: &game,
            winningTeam: winningTeam,
            setScores: setScores,
            players: &players
        )
        
        let winnerName = winningTeam == 1 ? "Team 1" : "Team 2"
        postNotification(
            title: "🏆 Match Complete & Scores Recorded",
            message: "\(winnerName) won \(game.title)! Leaderboards & records updated. Match completed.",
            type: .scoreLogged,
            relatedGameId: game.id
        )
        
        // Refresh currentUser instance
        if let user = currentUser, let updatedUser = players.first(where: { $0.id == user.id }) {
            currentUser = updatedUser
        }
        
        // Automatically delete the match and all its messages when completed
        games.remove(at: index)
        saveToDisk()
        FirestoreService.shared.deleteGame(id: gameId)
        
        for pid in game.allPlayerIds {
            if let pIdx = players.firstIndex(where: { $0.id == pid }) {
                players[pIdx].consecutiveBackouts = 0 // Clear flaker backout streak upon match completion
                if currentUser?.id == pid {
                    currentUser = players[pIdx]
                }
                FirestoreService.shared.savePlayer(players[pIdx])
            }
        }
    }
    
    private func setupFirestoreSync() {
        FirestoreService.shared.startListening(
            onPlayersUpdate: { [weak self] remotePlayers in
                guard let self = self else { return }
                self.players = remotePlayers
                if let current = self.currentUser, let updated = remotePlayers.first(where: { $0.id == current.id }) {
                    self.currentUser = updated
                }
                self.saveToDisk()
            },
            onGamesUpdate: { [weak self] remoteGames in
                guard let self = self else { return }
                self.games = remoteGames.filter { $0.status != .completed }
                self.saveToDisk()
            },
            onSlotsUpdate: { [weak self] remoteSlots in
                guard let self = self else { return }
                self.availabilitySlots = remoteSlots
                self.saveToDisk()
            }
        )
        
        FirestoreService.shared.seedInitialCommunityIfEmpty(
            initialPlayers: self.players,
            initialGames: self.games,
            initialSlots: self.availabilitySlots
        )
    }
    
    // MARK: - Mock Initial Community Data
    
    private func loadMockCommunityData() {
        let p1 = Player(
            name: "Kai Rodriguez",
            nickname: "The Jet",
            avatarEmoji: "🦈",
            rating: .aa,
            eloRating: 2240,
            homeBeach: "Main Beach",
            phoneNumber: "8315550101",
            password: "volleyball123",
            starRatingSum: 24,
            starRatingCount: 5,
            wins: 38,
            losses: 7,
            streak: 6,
            pointsScored: 940,
            pointsAllowed: 610,
            recentForm: [true, true, true, true, true],
            bio: "Tournament AA player. Left-side powerhouse, cut-shot specialist at Main Beach."
        )
        
        let p2 = Player(
            name: "Taylor Jenkins",
            nickname: "The Mayor",
            avatarEmoji: "slug",
            rating: .a,
            eloRating: 1980,
            homeBeach: "Main Beach",
            phoneNumber: "8315550102",
            password: "volleyball123",
            starRatingSum: 40,
            starRatingCount: 8,
            wins: 45,
            losses: 22,
            streak: 2,
            pointsScored: 1420,
            pointsAllowed: 1210,
            recentForm: [true, false, true, true, false],
            bio: "Proud Banana Slug! Love setting up sets for everyone at Main Beach."
        )
        
        let p3 = Player(
            name: "Maya Lin",
            nickname: "SpikeQueen",
            avatarEmoji: "🐋",
            rating: .aa,
            eloRating: 2190,
            homeBeach: "Harbor",
            phoneNumber: "8315550103",
            password: "volleyball123",
            starRatingSum: 34,
            starRatingCount: 7,
            wins: 29,
            losses: 9,
            streak: 3,
            pointsScored: 790,
            pointsAllowed: 580,
            recentForm: [true, true, false, true, true],
            bio: "Harbor regular. Former D1 outdoor. Jump serve & aggressive transition digs."
        )
        
        let p4 = Player(
            name: "Carlos Mendez",
            nickname: "El Muro",
            avatarEmoji: "🦦",
            rating: .a,
            eloRating: 1890,
            homeBeach: "4th Street",
            phoneNumber: "8315550104",
            password: "volleyball123",
            starRatingSum: 28,
            starRatingCount: 6,
            wins: 24,
            losses: 14,
            streak: -1,
            pointsScored: 820,
            pointsAllowed: 760,
            recentForm: [false, true, true, false, false],
            bio: "6'4 blocker at 4th Street. Reading tendencies and setting up solid beach traps."
        )
        
        let p5 = Player(
            name: "Chloe Dupont",
            nickname: "Sunny",
            avatarEmoji: "slug",
            rating: .b,
            eloRating: 1640,
            homeBeach: "Main Beach",
            phoneNumber: "8315550105",
            password: "volleyball123",
            starRatingSum: 29,
            starRatingCount: 6,
            wins: 19,
            losses: 15,
            streak: 2,
            pointsScored: 680,
            pointsAllowed: 660,
            recentForm: [true, true, false, true, false],
            bio: "Passionate B player working on handset clean releases and roll shots."
        )
        
        let p6 = Player(
            name: "Lucas Vance",
            nickname: "Ace",
            avatarEmoji: "🦈",
            rating: .b,
            eloRating: 1580,
            homeBeach: "Harbor",
            phoneNumber: "8315550106",
            password: "volleyball123",
            starRatingSum: 23,
            starRatingCount: 5,
            wins: 16,
            losses: 18,
            streak: 1,
            pointsScored: 620,
            pointsAllowed: 640,
            recentForm: [true, false, false, true, false],
            bio: "Consistent platform passer, loves sunset rallies at the Harbor."
        )
        
        let p7 = Player(
            name: "Samira Patel",
            nickname: "Sam",
            avatarEmoji: "🦦",
            rating: .intermediate,
            eloRating: 1410,
            homeBeach: "4th Street",
            phoneNumber: "8315550107",
            password: "volleyball123",
            starRatingSum: 24,
            starRatingCount: 5,
            wins: 12,
            losses: 16,
            streak: -2,
            pointsScored: 510,
            pointsAllowed: 570,
            recentForm: [false, false, true, false, true],
            bio: "Intermediate doubles at 4th Street. Always down for weekend games!"
        )
        
        let p8 = Player(
            name: "Jordan Bell",
            nickname: "Rookie",
            avatarEmoji: "🐋",
            rating: .novice,
            eloRating: 1180,
            homeBeach: "Main Beach",
            phoneNumber: "8315550108",
            password: "volleyball123",
            starRatingSum: 15,
            starRatingCount: 3,
            wins: 6,
            losses: 14,
            streak: 1,
            pointsScored: 340,
            pointsAllowed: 420,
            recentForm: [true, false, false, false, true],
            bio: "Started playing this summer at Main Beach! Improving every weekend."
        )
        
        // Seed unique partners & opponents for the "Popular Kids" network
        var allInitPlayers = [p1, p2, p3, p4, p5, p6, p7, p8]
        
        // Taylor (p2) is the ultimate "Popular Kid / Connector" who plays with everyone!
        allInitPlayers[1].uniquePartnerIds = [p1.id, p3.id, p4.id, p5.id, p6.id, p7.id, p8.id, UUID(), UUID(), UUID(), UUID(), UUID(), UUID(), UUID(), UUID()]
        allInitPlayers[1].uniqueOpponentIds = [p1.id, p3.id, p4.id, p5.id, p6.id, p7.id, p8.id, UUID(), UUID(), UUID(), UUID(), UUID(), UUID(), UUID()]
        
        // Chloe (p5) is also a strong social connector
        allInitPlayers[4].uniquePartnerIds = [p2.id, p6.id, p7.id, p8.id, UUID(), UUID(), UUID(), UUID(), UUID()]
        allInitPlayers[4].uniqueOpponentIds = [p1.id, p2.id, p3.id, p4.id, p6.id, p7.id, UUID(), UUID(), UUID()]
        
        // Kai (p1) is competitive leader
        allInitPlayers[0].uniquePartnerIds = [p3.id, p4.id, p2.id, UUID(), UUID()]
        allInitPlayers[0].uniqueOpponentIds = [p2.id, p3.id, p4.id, p5.id, UUID(), UUID(), UUID()]
        
        // Maya (p3)
        allInitPlayers[2].uniquePartnerIds = [p1.id, p2.id, UUID(), UUID(), UUID()]
        allInitPlayers[2].uniqueOpponentIds = [p1.id, p4.id, p2.id, UUID(), UUID(), UUID()]
        
        self.players = allInitPlayers
        
        // Do not auto-login by default; prompt for phone number login or sign up
        self.currentUser = nil
        
        // Seed historical and upcoming games
        let cal = Calendar.current
        let today = Date()
        
        // Match 1: AA Level-Locked Match (Main Beach)
        let matchAA = SetGame(
            title: "Saturday Morning AA Doubles",
            targetRating: .aa,
            format: .bestOfThree,
            status: .scheduled,
            scheduledDate: cal.date(byAdding: .day, value: 1, to: today) ?? today,
            courtLocation: "Main Beach",
            courtNumber: "Court #1",
            team1PlayerIds: [p1.id],
            team2PlayerIds: [p3.id],
            notes: "High intensity tournament practice. Bring official balls!",
            hostPlayerId: p1.id,
            isLevelLocked: true
        )
        
        // Match 2: A Level-Locked Match (4th Street)
        let matchA = SetGame(
            title: "A Level Sunset Clash",
            targetRating: .a,
            format: .bestOfThree,
            status: .scheduled,
            scheduledDate: cal.date(byAdding: .day, value: 2, to: today) ?? today,
            courtLocation: "4th Street",
            courtNumber: "Court #2",
            team1PlayerIds: [p4.id],
            team2PlayerIds: [p2.id],
            notes: "Aggressive side-out rallies and cut-shot drills.",
            hostPlayerId: p4.id,
            isLevelLocked: true
        )
        
        // Match 3: B Level-Locked Match (Harbor)
        let matchB = SetGame(
            title: "Harbor B Doubles (Need 1)",
            targetRating: .b,
            format: .bestOfThree,
            status: .scheduled,
            scheduledDate: cal.date(byAdding: .day, value: 1, to: today) ?? today,
            courtLocation: "Harbor",
            courtNumber: "Court #1",
            team1PlayerIds: [p5.id, p6.id],
            team2PlayerIds: [p7.id],
            notes: "Looking for 1 more solid B player for 3 sets to 21.",
            hostPlayerId: p5.id,
            isLevelLocked: true
        )
        
        // Match 4: Intermediate Level-Locked Match (Seabright Beach)
        let matchIntermediate = SetGame(
            title: "Sunday Intermediate Fun Sets",
            targetRating: .intermediate,
            format: .singleSet21,
            status: .scheduled,
            scheduledDate: cal.date(byAdding: .day, value: 3, to: today) ?? today,
            courtLocation: "Seabright Beach",
            courtNumber: "Court #1",
            team1PlayerIds: [p7.id],
            team2PlayerIds: [p8.id],
            notes: "Friendly pickup doubles, learning handsets and defense.",
            hostPlayerId: p7.id,
            isLevelLocked: true
        )
        
        self.games = [matchAA, matchA, matchB, matchIntermediate]
        
        // Seed some availability slots for other players to test matching
        let tomorrow9am = cal.date(bySettingHour: 9, minute: 0, second: 0, of: cal.date(byAdding: .day, value: 1, to: today)!)!
        let tomorrow11am = cal.date(bySettingHour: 11, minute: 30, second: 0, of: cal.date(byAdding: .day, value: 1, to: today)!)!
        
        self.availabilitySlots = [
            AvailabilitySlot(playerId: p1.id, date: tomorrow9am, startTime: tomorrow9am, endTime: tomorrow11am, preferredBeach: "Main Beach", acceptedTiers: [.a, .aa]),
            AvailabilitySlot(playerId: p3.id, date: tomorrow9am, startTime: tomorrow9am, endTime: tomorrow11am, preferredBeach: "Main Beach", acceptedTiers: [.a, .aa]),
            AvailabilitySlot(playerId: p4.id, date: tomorrow9am, startTime: tomorrow9am, endTime: tomorrow11am, preferredBeach: "Main Beach", acceptedTiers: [.a, .aa]),
            AvailabilitySlot(playerId: p2.id, date: tomorrow9am, startTime: tomorrow9am, endTime: tomorrow11am, preferredBeach: "Main Beach", acceptedTiers: [.b, .a, .aa])
        ]
        
        // Seed initial notifications to demonstrate the notification center
        self.notifications = [
            AppNotification(
                title: "🏐 Set Game Confirmed!",
                message: "You've been paired for Saturday Morning AA Doubles at Main Beach Court #2!",
                type: .matchConfirmed,
                date: Date().addingTimeInterval(-3600),
                isRead: false
            ),
            AppNotification(
                title: "👑 Popular Kids Network Alert",
                message: "You connected with 22 different players! You're currently ranked #1 Social Catalyst.",
                type: .communityBadge,
                date: Date().addingTimeInterval(-7200),
                isRead: true
            )
        ]
        
        saveToDisk()
    }
    
    // MARK: - Local Device Persistence
    
    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private var playersFileURL: URL { documentsDirectory.appendingPathComponent("setgames_players.json") }
    private var gamesFileURL: URL { documentsDirectory.appendingPathComponent("setgames_games.json") }
    private var slotsFileURL: URL { documentsDirectory.appendingPathComponent("setgames_slots.json") }
    private var userSessionKey: String { "setgames_current_user_id" }
    
    public func saveToDisk() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        if let data = try? encoder.encode(players) {
            try? data.write(to: playersFileURL, options: .atomic)
        }
        if let data = try? encoder.encode(games) {
            try? data.write(to: gamesFileURL, options: .atomic)
        }
        if let data = try? encoder.encode(availabilitySlots) {
            try? data.write(to: slotsFileURL, options: .atomic)
        }
        if let user = currentUser {
            UserDefaults.standard.set(user.id.uuidString, forKey: userSessionKey)
        } else {
            UserDefaults.standard.removeObject(forKey: userSessionKey)
        }
    }
    
    private func loadFromDisk() -> Bool {
        let decoder = JSONDecoder()
        guard let pData = try? Data(contentsOf: playersFileURL),
              let loadedPlayers = try? decoder.decode([Player].self, from: pData),
              !loadedPlayers.isEmpty else {
            return false
        }
        
        self.players = loadedPlayers
        
        if let gData = try? Data(contentsOf: gamesFileURL),
           let loadedGames = try? decoder.decode([SetGame].self, from: gData) {
            self.games = loadedGames.filter { $0.status != .completed }
        }
        
        if let sData = try? Data(contentsOf: slotsFileURL),
           let loadedSlots = try? decoder.decode([AvailabilitySlot].self, from: sData) {
            self.availabilitySlots = loadedSlots
        }
        
        if let savedUserIdString = UserDefaults.standard.string(forKey: userSessionKey),
           let savedUUID = UUID(uuidString: savedUserIdString) {
            self.currentUser = self.players.first(where: { $0.id == savedUUID })
        } else {
            self.currentUser = nil
        }
        
        return true
    }
}
