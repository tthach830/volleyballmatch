import SwiftUI
import Combine

public class DataManager: ObservableObject {
    public static let shared = DataManager()
    
    @Published public var currentUser: Player? {
        didSet {
            if currentUser != nil {
                NotificationService.shared.requestPermission()
                syncMatchReminders()
            }
        }
    }
    @Published public var players: [Player] = []
    @Published public var games: [SetGame] = []
    @Published public var tournaments: [Tournament] = []
    @Published public var availabilitySlots: [AvailabilitySlot] = []
    @Published public var pickupQueue: [Player] = []
    @Published public var beachPickupQueues: [String: [Player]] = ["Main Beach": [], "Harbor Beach": []]
    @Published public var notifications: [AppNotification] = []
    @Published public var isDemoModeEnabled: Bool = false
    private var hasCompletedInitialGamesSync: Bool = false
    private var recentlyDeletedSlotIds = Set<String>()
    
    public init() {
        self.isDemoModeEnabled = UserDefaults.standard.bool(forKey: "isDemoModeEnabled")
        if !loadFromDisk() {
            loadMockCommunityData()
        }
        if currentUser?.isRoot != true {
            self.isDemoModeEnabled = false
            UserDefaults.standard.set(false, forKey: "isDemoModeEnabled")
        }
        setupFirestoreSync()
        
        if currentUser != nil {
            NotificationService.shared.requestPermission()
            if let token = NotificationService.shared.apnsDeviceToken {
                updateDeviceToken(token)
            }
            syncMatchReminders()
        }
    }
    
    public var unreadNotificationsCount: Int {
        notifications.filter { !$0.isRead }.count
    }
    
    public func markAllNotificationsRead() {
        for i in 0..<notifications.count {
            notifications[i].isRead = true
        }
    }
    
    // MARK: - Upcoming Match Reminders (30 Minutes Before Game)
    
    public func syncMatchReminders() {
        guard let user = currentUser else { return }
        let now = Date()
        let myUpcomingGames = games.filter { game in
            game.status != .completed &&
            game.status != .canceled &&
            (game.allPlayerIds.contains(user.id) || game.hostPlayerId == user.id)
        }
        
        for game in myUpcomingGames {
            // Check if 30-minute reminder trigger is in the future
            if game.scheduledDate.addingTimeInterval(-1800) > now {
                NotificationService.shared.scheduleMatchReminder(
                    gameId: game.id,
                    gameTitle: game.title,
                    courtLocation: game.courtLocation,
                    courtNumber: game.courtNumber,
                    scheduledDate: game.scheduledDate,
                    minutesBefore: 30
                )
            }
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
        // Foreground in-app notification: trigger custom SwiftUI toast
        NotificationService.shared.triggerInAppToast(notif)
        // Trigger system notification banner with sound on device
        NotificationService.shared.sendSystemNotification(title: title, body: message)
    }
    
    // MARK: - User Session & Sign Up / Login
    
    public func updateDeviceToken(_ token: String) {
        guard let current = currentUser else { return }
        if current.deviceToken != token {
            if let idx = players.firstIndex(where: { $0.id == current.id }) {
                players[idx].deviceToken = token
                currentUser = players[idx]
            }
            saveToDisk()
            FirestoreService.shared.saveDeviceToken(playerId: current.id, token: token)
        }
    }
    
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
            if !player.isRoot {
                isDemoModeEnabled = false
                UserDefaults.standard.set(false, forKey: "isDemoModeEnabled")
            }
            saveToDisk()
            NotificationService.shared.requestPermission()
            if let token = NotificationService.shared.apnsDeviceToken {
                updateDeviceToken(token)
            }
            return (true, "Welcome back, \(player.displayName)!")
        } else {
            return (false, "No player found with this phone number. Please tap 'New Player' below to register!")
        }
    }
    
    @discardableResult
    public func signUp(
        phoneNumber: String = "",
        password: String = "",
        name: String,
        nickname: String,
        gender: String = "Male",
        rating: RatingTier,
        homeBeach: String,
        avatarEmoji: String
    ) -> (success: Bool, message: String) {
        let cleaned = DataManager.normalizePhoneNumber(phoneNumber)
        if !cleaned.isEmpty {
            if let _ = players.first(where: {
                let pCleaned = DataManager.normalizePhoneNumber($0.phoneNumber)
                return !pCleaned.isEmpty && pCleaned == cleaned
            }) {
                return (false, "This phone number is already registered. Only one account per phone number is allowed. Please log in instead.")
            }
        }
        
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
            gender: gender,
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
            bio: "Ready to bump, set, and spike on the sand!",
            deviceToken: NotificationService.shared.apnsDeviceToken
        )
        
        players.append(newPlayer)
        currentUser = newPlayer
        isDemoModeEnabled = false
        UserDefaults.standard.set(false, forKey: "isDemoModeEnabled")
        saveToDisk()
        FirestoreService.shared.savePlayer(newPlayer)
        NotificationService.shared.requestPermission()
        if let token = NotificationService.shared.apnsDeviceToken {
            updateDeviceToken(token)
        }
        
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
        
        return (true, "Welcome to Volleyball Match, \(newPlayer.name)!")
    }
    
    public func setDemoModeEnabled(_ enabled: Bool) {
        guard currentUser?.isRoot == true else { return }
        isDemoModeEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "isDemoModeEnabled")
    }
    
    public func switchUser(to player: Player) {
        guard isDemoModeEnabled || currentUser?.isRoot == true else { return }
        currentUser = player
        saveToDisk()
    }
    
    public func logOut() {
        currentUser = nil
        isDemoModeEnabled = false
        UserDefaults.standard.set(false, forKey: "isDemoModeEnabled")
        saveToDisk()
    }
    
    @discardableResult
    public func deleteCurrentUser() -> Bool {
        guard let user = currentUser else { return false }
        let userId = user.id
        
        // 1. Remove player from all games and waitlists, auto-promoting waitlisted players if space opens
        for i in 0..<games.count {
            var g = games[i]
            var changed = false
            
            if g.waitlistPlayerIds.contains(userId) {
                g.waitlistPlayerIds.removeAll(where: { $0 == userId })
                changed = true
            }
            
            let wasInTeam1 = g.team1PlayerIds.contains(userId)
            let wasInTeam2 = g.team2PlayerIds.contains(userId)
            if wasInTeam1 || wasInTeam2 {
                g.team1PlayerIds.removeAll(where: { $0 == userId })
                g.team2PlayerIds.removeAll(where: { $0 == userId })
                changed = true
                
                // Auto-promote first eligible waitlisted player if available
                if !g.waitlistPlayerIds.isEmpty && g.allPlayerIds.count < g.maxPlayers {
                    _ = autoPromoteNextEligibleWaitlistedPlayer(for: &g)
                }
            }
            
            if g.hostPlayerId == userId {
                g.hostPlayerId = g.allPlayerIds.first
                changed = true
            }
            
            if changed {
                games[i] = g
                FirestoreService.shared.saveGame(g)
            }
        }
        
        // 2. Remove availability slots
        availabilitySlots.removeAll(where: { $0.playerId == userId })
        
        // 3. Remove from pickup queue if present
        pickupQueue.removeAll(where: { $0.id == userId })
        
        // 4. Remove player from players list
        players.removeAll(where: { $0.id == userId })
        
        // 5. Delete player from Firestore
        FirestoreService.shared.deletePlayer(id: userId)
        
        // 6. Clear session and save disk
        currentUser = nil
        isDemoModeEnabled = false
        UserDefaults.standard.set(false, forKey: "isDemoModeEnabled")
        saveToDisk()
        
        return true
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
        
        if addedCount > 0 {
            syncMatchReminders()
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
            rawPlayerId: user.id.uuidString,
            date: date,
            startTime: startTime,
            endTime: endTime,
            preferredBeach: beach,
            acceptedTiers: tiers,
            allowPlusMinusOneTier: allowPlusMinus
        )
        availabilitySlots.insert(slot, at: 0)
        saveToDisk()
        FirestoreService.shared.saveAvailabilitySlot(slot)
    }
    
    public func deleteAvailabilitySlot(id: UUID, rawId: String? = nil) {
        guard let user = currentUser else { return }
        guard let slot = availabilitySlots.first(where: {
            $0.id == id || (rawId != nil && ($0.rawId == rawId || $0.id.uuidString == rawId))
        }) else { return }
        guard user.isRoot || slot.playerId == user.id || (slot.rawPlayerId != nil && slot.rawPlayerId == user.id.uuidString) else {
            print("Unauthorized deletion attempt for availability slot \(id)")
            return
        }
        let targetDocId = slot.rawId ?? rawId ?? slot.id.uuidString
        recentlyDeletedSlotIds.insert(slot.id.uuidString)
        recentlyDeletedSlotIds.insert(targetDocId)
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            self?.recentlyDeletedSlotIds.remove(slot.id.uuidString)
            self?.recentlyDeletedSlotIds.remove(targetDocId)
        }
        availabilitySlots.removeAll(where: {
            $0.id == slot.id || ($0.rawId != nil && $0.rawId == slot.rawId)
        })
        saveToDisk()
        FirestoreService.shared.deleteAvailabilitySlot(id: slot.id, rawId: targetDocId)
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
                    matchedOptionName: "Quick-Play Lobby"
                )
                games.insert(fastGame, at: 0)
                saveToDisk()
                FirestoreService.shared.saveGame(fastGame)
                syncMatchReminders()
                
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
    
    public func pickupQueue(for beach: String) -> [Player] {
        return beachPickupQueues[beach] ?? []
    }
    
    @discardableResult
    public func joinBeachPickupQueue(beach: String, player: Player? = nil) -> SetGame? {
        let playerToAdd = player ?? currentUser
        guard let p = playerToAdd else { return nil }
        
        var queue = beachPickupQueues[beach] ?? []
        if !queue.contains(where: { $0.id == p.id }) {
            queue.append(p)
            beachPickupQueues[beach] = queue
            
            // When 4 players join, auto-lock into a confirmed game!
            if queue.count >= 4 {
                let four = Array(queue.prefix(4))
                beachPickupQueues[beach] = Array(queue.dropFirst(4))
                
                let sorted = four.sorted { $0.eloRating > $1.eloRating }
                let team1 = [sorted[0], sorted[3]]
                let team2 = [sorted[1], sorted[2]]
                
                let fastGame = SetGame(
                    title: "Instant Pickup 2v2",
                    targetRating: p.rating,
                    format: .bestOfThree,
                    status: .scheduled,
                    scheduledDate: Date().addingTimeInterval(1800),
                    courtLocation: beach,
                    courtNumber: "Court #1",
                    team1PlayerIds: team1.map { $0.id },
                    team2PlayerIds: team2.map { $0.id },
                    isAutoMatched: true,
                    matchedOptionName: "Quick-Play Lobby"
                )
                games.insert(fastGame, at: 0)
                saveToDisk()
                FirestoreService.shared.saveGame(fastGame)
                syncMatchReminders()
                
                postNotification(
                    title: "⚡️ Pickup Lobby Full (4/4)!",
                    message: "Your instant pickup game at \(beach) is locked and ready!",
                    type: .queueUpdate,
                    relatedGameId: fastGame.id
                )
                return fastGame
            }
        }
        return nil
    }
    
    public func leaveBeachPickupQueue(beach: String, playerId: UUID? = nil) {
        let targetId = playerId ?? currentUser?.id
        guard let uid = targetId else { return }
        var queue = beachPickupQueues[beach] ?? []
        queue.removeAll(where: { $0.id == uid })
        beachPickupQueues[beach] = queue
    }
    
    @discardableResult
    public func fillBeachPickupQueue(beach: String) -> SetGame? {
        guard currentUser?.isRoot == true else { return nil }
        var queue = beachPickupQueues[beach] ?? []
        if let user = currentUser, !queue.contains(where: { $0.id == user.id }) {
            queue.append(user)
        }
        let availablePlayers = players.filter { p in
            !queue.contains(where: { $0.id == p.id })
        }
        for p in availablePlayers {
            if queue.count >= 4 { break }
            queue.append(p)
        }
        beachPickupQueues[beach] = queue
        
        if queue.count >= 4 {
            let four = Array(queue.prefix(4))
            beachPickupQueues[beach] = Array(queue.dropFirst(4))
            let sorted = four.sorted { $0.eloRating > $1.eloRating }
            let team1 = [sorted[0], sorted[3]]
            let team2 = [sorted[1], sorted[2]]
            let fastGame = SetGame(
                title: "Instant Pickup 2v2",
                targetRating: currentUser?.rating ?? .b,
                format: .bestOfThree,
                status: .scheduled,
                scheduledDate: Date().addingTimeInterval(1800),
                courtLocation: beach,
                courtNumber: "Court #1",
                team1PlayerIds: team1.map { $0.id },
                team2PlayerIds: team2.map { $0.id },
                isAutoMatched: true,
                matchedOptionName: "Quick-Play Lobby"
            )
            games.insert(fastGame, at: 0)
            saveToDisk()
            FirestoreService.shared.saveGame(fastGame)
            syncMatchReminders()
            postNotification(
                title: "⚡️ Pickup Lobby Full (4/4)!",
                message: "Your instant pickup game at \(beach) is locked and ready!",
                type: .queueUpdate,
                relatedGameId: fastGame.id
            )
            return fastGame
        }
        return nil
    }
    
    @discardableResult
    private func autoPromoteNextEligibleWaitlistedPlayer(for game: inout SetGame) -> Player? {
        guard !game.waitlistPlayerIds.isEmpty && game.allPlayerIds.count < game.maxPlayers else {
            return nil
        }
        
        let allActive = game.allPlayerIds.compactMap { pid in players.first(where: { $0.id == pid }) }
        let currentMales = allActive.filter { $0.gender.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "male" }.count
        let currentFemales = allActive.filter { $0.gender.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "female" }.count
        
        var foundIndex: Int? = nil
        for (wIdx, wId) in game.waitlistPlayerIds.enumerated() {
            guard let wp = players.first(where: { $0.id == wId }) else { continue }
            let wGender = wp.gender.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            
            switch game.genderCategory {
            case .coed:
                if wGender == "male" && currentMales < 2 {
                    foundIndex = wIdx
                } else if wGender == "female" && currentFemales < 2 {
                    foundIndex = wIdx
                }
            case .female:
                if wGender == "female" {
                    foundIndex = wIdx
                }
            case .male:
                if wGender == "male" {
                    foundIndex = wIdx
                }
            case .open:
                foundIndex = wIdx
            }
            if foundIndex != nil { break }
        }
        
        guard let idxToPromote = foundIndex else {
            return nil
        }
        
        let promotedId = game.waitlistPlayerIds.remove(at: idxToPromote)
        if game.team1PlayerIds.count <= game.team2PlayerIds.count {
            game.team1PlayerIds.append(promotedId)
        } else {
            game.team2PlayerIds.append(promotedId)
        }
        
        let promotedPlayer = players.first(where: { $0.id == promotedId })
        if let p = promotedPlayer {
            let title = "🎉 You're in!"
            let body = "A spot opened up in '\(game.title)' and you were promoted from the waitlist!"
            let gameId = game.id
            if let token = p.deviceToken, !token.isEmpty {
                NotificationService.shared.sendDirectRemotePush(
                    to: token,
                    title: title,
                    body: body,
                    gameId: gameId
                )
            } else {
                FirestoreService.shared.fetchDeviceToken(for: promotedId) { token in
                    if let token = token, !token.isEmpty {
                        NotificationService.shared.sendDirectRemotePush(
                            to: token,
                            title: title,
                            body: body,
                            gameId: gameId
                        )
                    }
                }
            }
        }
        
        return promotedPlayer
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
        
        if game.allPlayerIds.count >= game.maxPlayers {
            return (false, "Sorry, this match is already full!")
        }
        
        // Private Game Check
        if game.isPrivate && !user.isRoot && game.hostPlayerId != user.id {
            return (false, "Private Game: This match is private and invite-only.")
        }
        
        // Level Lock Check
        if game.isLevelLocked && !game.isPlayerTierAllowed(user.rating) {
            return (false, "Level Locked: This match is locked to \(game.allowedRatingsDescription) players only. Your current rating is \(user.rating.rawValue).")
        }
        
        // Gender Category Check
        let genderCheck = game.canPlayerJoinGenderCategory(user, allPlayers: players)
        if !genderCheck.allowed {
            return (false, genderCheck.message ?? "You cannot join this match due to division restrictions.")
        }
        
        let maxTeamSize = (game.maxPlayers + 1) / 2
        if teamNumber == 1 && game.team1PlayerIds.count < maxTeamSize {
            game.team1PlayerIds.append(user.id)
        } else if teamNumber == 2 && game.team2PlayerIds.count < maxTeamSize {
            game.team2PlayerIds.append(user.id)
        } else if game.team1PlayerIds.count <= game.team2PlayerIds.count {
            game.team1PlayerIds.append(user.id)
        } else {
            game.team2PlayerIds.append(user.id)
        }
        
        games[index] = game
        saveToDisk()
        FirestoreService.shared.saveGame(game)
        syncMatchReminders()
        return (true, "Successfully joined \(game.title)!")
    }
    
    @discardableResult
    public func joinGamePool(gameId: UUID) -> (success: Bool, message: String) {
        guard let user = currentUser,
              let index = games.firstIndex(where: { $0.id == gameId }) else {
            return (false, "Please log in to join this match.")
        }
        
        var game = games[index]
        if game.allPlayerIds.contains(user.id) {
            return (false, "You are already in this match!")
        }
        
        if game.allPlayerIds.count >= game.maxPlayers {
            return (false, "Sorry, this match is already full!")
        }
        
        // Private Game Check
        if game.isPrivate && !user.isRoot && game.hostPlayerId != user.id {
            return (false, "Private Game: This match is private and invite-only.")
        }
        
        // Level Lock Check
        if game.isLevelLocked && !game.isPlayerTierAllowed(user.rating) {
            return (false, "Level Locked: This match is locked to \(game.allowedRatingsDescription) players only. Your current rating is \(user.rating.rawValue).")
        }
        
        // Gender Category Check
        let genderCheck = game.canPlayerJoinGenderCategory(user, allPlayers: players)
        if !genderCheck.allowed {
            return (false, genderCheck.message ?? "You cannot join this match due to division restrictions.")
        }
        
        if game.team1PlayerIds.count <= game.team2PlayerIds.count {
            game.team1PlayerIds.append(user.id)
        } else {
            game.team2PlayerIds.append(user.id)
        }
        
        games[index] = game
        saveToDisk()
        FirestoreService.shared.saveGame(game)
        syncMatchReminders()
        return (true, "Successfully joined \(game.title)!")
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
        
        // Private Game Check
        if game.isPrivate && !user.isRoot && game.hostPlayerId != user.id {
            return (false, "Private Game: This match is private and invite-only.")
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
    public func promoteWaitlistPlayer(gameId: UUID, playerId: UUID) -> (success: Bool, message: String) {
        guard let user = currentUser,
              let index = games.firstIndex(where: { $0.id == gameId }) else {
            return (false, "Match not found.")
        }
        
        var game = games[index]
        let isHost = (game.hostPlayerId == user.id) || (game.team1PlayerIds.first == user.id) || user.isRoot
        guard isHost else {
            return (false, "Only the match host or admin can add players from waiting.")
        }
        
        guard game.waitlistPlayerIds.contains(playerId) else {
            return (false, "Player is no longer waiting.")
        }
        
        let wp = player(for: playerId)
        let genderCheck = game.canPlayerJoinGenderCategory(wp, allPlayers: players)
        if !genderCheck.allowed {
            return (false, genderCheck.message ?? "Player cannot join due to division restrictions.")
        }
        
        // Remove from waitlist
        game.waitlistPlayerIds.removeAll(where: { $0 == playerId })
        
        // Expand capacity if pool was at max
        if game.allPlayerIds.count >= game.maxPlayers {
            game.maxPlayers = game.allPlayerIds.count + 1
        }
        
        // Add to team with fewer players
        if game.team1PlayerIds.count <= game.team2PlayerIds.count {
            game.team1PlayerIds.append(playerId)
        } else {
            game.team2PlayerIds.append(playerId)
        }
        
        games[index] = game
        saveToDisk()
        FirestoreService.shared.saveGame(game)
        
        let promoted = player(for: playerId)
        let promotedName = promoted.displayName
        
        postNotification(
            title: "🎉 Added from Waiting",
            message: "\(promotedName) was added into \(game.title) by the host!",
            type: .matchInvite,
            relatedGameId: game.id
        )
        
        // Dispatch Apple APNs remote push notification
        if let token = promoted.deviceToken, !token.isEmpty {
            NotificationService.shared.sendDirectRemotePush(
                to: token,
                title: "🏐 Added to Game!",
                body: "🎉 The host promoted you into '\(game.title)'!",
                gameId: game.id
            )
        }
        
        return (true, "Successfully added \(promotedName) into the match!")
    }

    @discardableResult
    public func addSpotToGame(gameId: UUID) -> (success: Bool, message: String) {
        guard let user = currentUser,
              let index = games.firstIndex(where: { $0.id == gameId }) else {
            return (false, "Match not found.")
        }
        
        var game = games[index]
        let isHost = (game.hostPlayerId == user.id) || (game.team1PlayerIds.first == user.id) || user.isRoot
        guard isHost else {
            return (false, "Only the match host or admin can add spots to this game.")
        }
        
        game.maxPlayers += 1
        games[index] = game
        saveToDisk()
        FirestoreService.shared.saveGame(game)
        return (true, "Added 1 open spot to \(game.title)!")
    }

    @discardableResult
    public func addPlayerToGame(gameId: UUID, playerId: UUID, teamNumber: Int? = nil) -> (success: Bool, message: String) {
        guard let user = currentUser,
              let index = games.firstIndex(where: { $0.id == gameId }) else {
            return (false, "Match not found.")
        }
        
        var game = games[index]
        let isHost = (game.hostPlayerId == user.id) || (game.team1PlayerIds.first == user.id) || user.isRoot
        guard isHost else {
            return (false, "Only the match host or admin can add players.")
        }
        
        if game.allPlayerIds.contains(playerId) {
            return (false, "Player is already in this game.")
        }
        
        let p = player(for: playerId)
        let genderCheck = game.canPlayerJoinGenderCategory(p, allPlayers: players)
        if !genderCheck.allowed {
            return (false, genderCheck.message ?? "Player cannot join due to division restrictions.")
        }
        
        game.waitlistPlayerIds.removeAll(where: { $0 == playerId })
        
        if game.allPlayerIds.count >= game.maxPlayers {
            game.maxPlayers = game.allPlayerIds.count + 1
        }
        
        if let teamNumber = teamNumber {
            if teamNumber == 1 {
                game.team1PlayerIds.append(playerId)
            } else {
                game.team2PlayerIds.append(playerId)
            }
        } else {
            if game.team1PlayerIds.count <= game.team2PlayerIds.count {
                game.team1PlayerIds.append(playerId)
            } else {
                game.team2PlayerIds.append(playerId)
            }
        }
        
        games[index] = game
        saveToDisk()
        FirestoreService.shared.saveGame(game)
        let pName = p.displayName
        
        if let token = p.deviceToken, !token.isEmpty {
            NotificationService.shared.sendDirectRemotePush(
                to: token,
                title: "🏐 Volleyball Match Alert",
                body: "🎉 The host added you into '\(game.title)'!",
                gameId: game.id
            )
        }
        
        return (true, "Added \(pName) to the game!")
    }
    
    @discardableResult
    public func removePlayerFromPool(gameId: UUID, playerId: UUID) -> (success: Bool, message: String) {
        guard let user = currentUser,
              let index = games.firstIndex(where: { $0.id == gameId }) else {
            return (false, "Match not found.")
        }
        
        var game = games[index]
        let isHost = (game.hostPlayerId == user.id) || user.isRoot
        guard isHost else {
            return (false, "Only the match host or admin can remove players from the pool.")
        }
        
        guard user.isRoot ? (playerId != user.id) : (playerId != game.hostPlayerId) else {
            return (false, "Hosts cannot remove themselves from the pool.")
        }
        
        let wasInTeam1 = game.team1PlayerIds.contains(playerId)
        let wasInTeam2 = game.team2PlayerIds.contains(playerId)
        let wasInWaitlist = game.waitlistPlayerIds.contains(playerId)
        
        guard wasInTeam1 || wasInTeam2 || wasInWaitlist else {
            return (false, "Player is not in this match.")
        }
        
        if wasInWaitlist {
            game.waitlistPlayerIds.removeAll(where: { $0 == playerId })
            games[index] = game
            saveToDisk()
            FirestoreService.shared.saveGame(game)
            let removed = player(for: playerId)
            let removedName = removed.displayName
            return (true, "Removed \(removedName) from waitlist.")
        }
        
        game.team1PlayerIds.removeAll(where: { $0 == playerId })
        game.team2PlayerIds.removeAll(where: { $0 == playerId })
        
        // Auto-promote first eligible waitlisted player into the open spot
        var promotedName: String? = nil
        if let promoted = autoPromoteNextEligibleWaitlistedPlayer(for: &game) {
            promotedName = promoted.displayName
        }
        
        games[index] = game
        saveToDisk()
        FirestoreService.shared.saveGame(game)
        
        let removed = player(for: playerId)
        let removedName = removed.displayName
        
        postNotification(
            title: "Match Update",
            message: "\(removedName) was removed from \(game.title) by the host.",
            type: .matchInvite,
            relatedGameId: game.id
        )
        
        if let token = removed.deviceToken, !token.isEmpty {
            NotificationService.shared.sendDirectRemotePush(
                to: token,
                title: "Volleyball Match Alert",
                body: "You were removed from '\(game.title)' by the host.",
                gameId: game.id
            )
        } else {
            FirestoreService.shared.fetchDeviceToken(for: playerId) { token in
                if let token = token, !token.isEmpty {
                    NotificationService.shared.sendDirectRemotePush(
                        to: token,
                        title: "Volleyball Match Alert",
                        body: "You were removed from '\(game.title)' by the host.",
                        gameId: game.id
                    )
                }
            }
        }
        
        if let promoted = promotedName {
            postNotification(
                title: "🎉 Waitlist Promotion",
                message: "\(promoted) was auto-promoted from the waitlist into \(game.title)!",
                type: .matchInvite,
                relatedGameId: game.id
            )
            return (true, "Removed \(removedName). \(promoted) was auto-promoted from the waitlist!")
        }
        
        return (true, "Removed \(removedName) from the match.")
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
    public func addSubMatch(gameId: UUID) -> (success: Bool, message: String) {
        guard let gIdx = games.firstIndex(where: { $0.id == gameId }) else {
            return (false, "Game not found.")
        }
        let allPids = games[gIdx].allPlayerIds
        guard allPids.count >= 4 else {
            return (false, "Need at least 4 players in the game to add a match.")
        }
        
        var playCounts: [UUID: Int] = [:]
        var partnerHistory: [UUID: Set<UUID>] = [:]
        for pid in allPids {
            playCounts[pid] = 0
            partnerHistory[pid] = []
        }
        for m in games[gIdx].subMatches {
            for pid in (m.team1PlayerIds + m.team2PlayerIds) {
                playCounts[pid, default: 0] += 1
            }
            if m.team1PlayerIds.count >= 2 {
                partnerHistory[m.team1PlayerIds[0]]?.insert(m.team1PlayerIds[1])
                partnerHistory[m.team1PlayerIds[1]]?.insert(m.team1PlayerIds[0])
            }
            if m.team2PlayerIds.count >= 2 {
                partnerHistory[m.team2PlayerIds[0]]?.insert(m.team2PlayerIds[1])
                partnerHistory[m.team2PlayerIds[1]]?.insert(m.team2PlayerIds[0])
            }
        }
        
        let sorted = allPids.shuffled().sorted { (playCounts[$0] ?? 0) < (playCounts[$1] ?? 0) }
        let picked = Array(sorted.prefix(4))
        let resting = Array(sorted.dropFirst(4))
        
        let splits: [(([UUID], [UUID]))] = [
            ([picked[0], picked[1]], [picked[2], picked[3]]),
            ([picked[0], picked[2]], [picked[1], picked[3]]),
            ([picked[0], picked[3]], [picked[1], picked[2]])
        ]
        
        let bestSplit = splits.min { s1, s2 in
            let r1 = (partnerHistory[s1.0[0]]?.contains(s1.0[1]) == true ? 1 : 0) +
                     (partnerHistory[s1.1[0]]?.contains(s1.1[1]) == true ? 1 : 0)
            let r2 = (partnerHistory[s2.0[0]]?.contains(s2.0[1]) == true ? 1 : 0) +
                     (partnerHistory[s2.1[0]]?.contains(s2.1[1]) == true ? 1 : 0)
            return r1 < r2
        } ?? splits[0]
        
        var t1 = bestSplit.0
        var t2 = bestSplit.1
        if Bool.random() {
            let temp = t1
            t1 = t2
            t2 = temp
        }
        
        let matchNum = games[gIdx].subMatches.count + 1
        let newMatch = SubMatch(
            id: UUID(),
            matchNumber: matchNum,
            courtNumber: games[gIdx].courtNumber.isEmpty ? "Court #1" : games[gIdx].courtNumber,
            setNumber: matchNum,
            team1PlayerIds: t1,
            team2PlayerIds: t2,
            restingPlayerIds: resting
        )
        
        games[gIdx].subMatches.append(newMatch)
        saveToDisk()
        FirestoreService.shared.saveGame(games[gIdx])
        return (true, "Added Match #\(matchNum)")
    }

    @discardableResult
    public func deleteSubMatch(gameId: UUID, matchId: UUID) -> (success: Bool, message: String) {
        guard let gIdx = games.firstIndex(where: { $0.id == gameId }) else {
            return (false, "Game not found.")
        }
        guard let mIdx = games[gIdx].subMatches.firstIndex(where: { $0.id == matchId }) else {
            return (false, "Match not found.")
        }
        games[gIdx].subMatches.remove(at: mIdx)
        for i in 0..<games[gIdx].subMatches.count {
            games[gIdx].subMatches[i].matchNumber = i + 1
            games[gIdx].subMatches[i].setNumber = i + 1
        }
        saveToDisk()
        FirestoreService.shared.saveGame(games[gIdx])
        return (true, "Removed match.")
    }
    
    @discardableResult
    public func updateSubMatchScore(gameId: UUID, matchId: UUID, team1Score: Int, team2Score: Int) -> Bool {
        guard let gIdx = games.firstIndex(where: { $0.id == gameId }) else { return false }
        guard let mIdx = games[gIdx].subMatches.firstIndex(where: { $0.id == matchId }) else { return false }
        games[gIdx].subMatches[mIdx].team1Score = team1Score
        games[gIdx].subMatches[mIdx].team2Score = team2Score
        games[gIdx].subMatches[mIdx].isCompleted = true
        games[gIdx].subMatches[mIdx].winningTeam = team1Score > team2Score ? 1 : 2
        
        // Award career stats (wins/losses/Elo/points) to participating players
        StatsManager.shared.applySubMatchResult(subMatch: &games[gIdx].subMatches[mIdx], players: &players)
        
        if !games[gIdx].subMatches.isEmpty && games[gIdx].subMatches.allSatisfy({ $0.isCompleted }) {
            games[gIdx].status = .completed
        }
        
        // Refresh currentUser
        if let user = currentUser, let updatedUser = players.first(where: { $0.id == user.id }) {
            currentUser = updatedUser
        }
        
        saveToDisk()
        FirestoreService.shared.saveGame(games[gIdx])
        
        // Save affected players to Firestore
        let affectedIds = Set(games[gIdx].subMatches[mIdx].team1PlayerIds + games[gIdx].subMatches[mIdx].team2PlayerIds)
        for pid in affectedIds {
            if let p = players.first(where: { $0.id == pid }) {
                FirestoreService.shared.savePlayer(p)
            }
        }
        
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
        
        // Auto-promote first eligible waitlisted player into the open spot
        var promotedName: String? = nil
        if let promoted = autoPromoteNextEligibleWaitlistedPlayer(for: &game) {
            promotedName = promoted.displayName
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
        NotificationService.shared.cancelMatchReminder(gameId: gameId)
        syncMatchReminders()
        
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
                "\(user.displayName) backed out 3 times in a row: flagged as Flaker (F) and rating lowered by 1 point." :
                "\(user.displayName) had to leave \(game.title). A spot is now open!",
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
        genderCategory: GameGenderCategory? = nil,
        format: GameFormat,
        maxPlayers: Int = 4,
        scheduledDate: Date,
        courtLocation: String,
        courtNumber: String,
        isLevelLocked: Bool,
        notes: String,
        isPrivate: Bool = false
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
        if let g = genderCategory {
            game.genderCategory = g
        }
        game.format = format
        game.maxPlayers = max(2, maxPlayers)
        game.scheduledDate = scheduledDate
        game.courtLocation = courtLocation
        game.courtNumber = courtNumber
        game.isLevelLocked = isLevelLocked
        game.notes = notes
        game.isPrivate = isPrivate
        
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
                return (false, "Only the game host or Root user can cancel and delete this game.")
            }
        }
        
        // Notify other players that the match was cancelled (deduplicated by physical device token)
        let otherPlayerIds = Set(game.allPlayerIds + game.waitlistPlayerIds).subtracting([user.id])
        var cancelTokens = Set<String>()
        var missingCancelTokenPids = [UUID]()
        for pid in otherPlayerIds {
            let p = player(for: pid)
            if let token = p.deviceToken, !token.isEmpty {
                if token != user.deviceToken {
                    cancelTokens.insert(token)
                }
            } else {
                missingCancelTokenPids.append(pid)
            }
        }
        for token in cancelTokens {
            NotificationService.shared.sendDirectRemotePush(
                to: token,
                title: "Volleyball Match Alert",
                body: "The host cancelled '\(game.title)'.",
                gameId: game.id
            )
        }
        for pid in missingCancelTokenPids {
            FirestoreService.shared.fetchDeviceToken(for: pid) { token in
                if let token = token, !token.isEmpty, token != user.deviceToken {
                    NotificationService.shared.sendDirectRemotePush(
                        to: token,
                        title: "Volleyball Match Alert",
                        body: "The host cancelled '\(game.title)'.",
                        gameId: game.id
                    )
                }
            }
        }
        
        games.remove(at: index)
        saveToDisk()
        FirestoreService.shared.deleteGame(id: gameId, rawId: game.rawId)
        NotificationService.shared.cancelMatchReminder(gameId: gameId)
        syncMatchReminders()
        return (true, "Match cancelled and deleted.")
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
        gender: String? = nil,
        avatarEmoji: String,
        rating: RatingTier,
        homeBeach: String,
        phoneNumber: String,
        bio: String,
        isStatsHidden: Bool? = nil
    ) {
        guard var user = currentUser else { return }
        user.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        user.nickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        if let g = gender, !g.isEmpty {
            user.gender = g
        }
        user.avatarEmoji = avatarEmoji
        user.rating = rating
        user.homeBeach = homeBeach.trimmingCharacters(in: .whitespacesAndNewlines)
        user.phoneNumber = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        user.bio = bio.trimmingCharacters(in: .whitespacesAndNewlines)
        if let hidden = isStatsHidden {
            user.isStatsHidden = hidden
        }
        
        currentUser = user
        if let idx = players.firstIndex(where: { $0.id == user.id }) {
            players[idx] = user
        } else {
            players.append(user)
        }
        saveToDisk()
        FirestoreService.shared.savePlayer(user)
    }
    
    public func setStatsHidden(_ hidden: Bool) {
        guard var user = currentUser else { return }
        user.isStatsHidden = hidden
        currentUser = user
        if let idx = players.firstIndex(where: { $0.id == user.id }) {
            players[idx] = user
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
        
        let senderName = user.displayName
        let newMsg = GameChatMessage(
            senderId: user.id,
            senderName: senderName,
            text: trimmed,
            date: Date(),
            origin: "ios"
        )
        
        games[index].messages.append(newMsg)
        saveToDisk()
        FirestoreService.shared.saveGame(games[index])
        
        // Dispatch direct APNs remote push notifications to all match participants ($0 Serverless)
        let game = games[index]
        var recipientIds = Set(game.allPlayerIds + game.waitlistPlayerIds)
        if let host = game.hostPlayerId {
            recipientIds.insert(host)
        }
        recipientIds.remove(user.id)
        
        let gameTitle = game.title
        var tokensToSend = Set<String>()
        var missingTokenRecipientIds = [UUID]()
        
        for recipientId in recipientIds {
            if let recipient = players.first(where: { $0.id == recipientId }),
               let token = recipient.deviceToken,
               !token.isEmpty {
                if token != user.deviceToken {
                    tokensToSend.insert(token)
                }
            } else {
                missingTokenRecipientIds.append(recipientId)
            }
        }
        
        for token in tokensToSend {
            NotificationService.shared.sendDirectRemotePush(
                to: token,
                title: "💬 \(senderName) (\(gameTitle))",
                body: trimmed,
                gameId: gameId
            )
        }
        
        for recipientId in missingTokenRecipientIds {
            FirestoreService.shared.fetchDeviceToken(for: recipientId) { token in
                if let token = token, !token.isEmpty, token != user.deviceToken {
                    NotificationService.shared.sendDirectRemotePush(
                        to: token,
                        title: "💬 \(senderName) (\(gameTitle))",
                        body: trimmed,
                        gameId: gameId
                    )
                }
            }
        }
        
        return (true, "Message sent!")
    }
    
    @discardableResult
    public func createMatch(
        title: String,
        targetRating: RatingTier,
        allowedRatings: [RatingTier] = [],
        genderCategory: GameGenderCategory = .coed,
        format: GameFormat = .bestOfThree,
        courtLocation: String = "Main Beach",
        courtNumber: String = "Court #1",
        scheduledDate: Date,
        isLevelLocked: Bool = true,
        maxPlayers: Int = 4,
        notes: String = "",
        isPrivate: Bool = false
    ) -> SetGame {
        let hostId = currentUser?.id ?? UUID()
        let effectiveAllowed = allowedRatings.isEmpty ? [targetRating] : allowedRatings
        let primaryRating = effectiveAllowed.first ?? targetRating
        let defaultTitle = effectiveAllowed.count > 1 ? "\(effectiveAllowed.map { $0.rawValue }.joined(separator: "/")) Match" : "\(primaryRating.rawValue) Match"
        let newGame = SetGame(
            title: title.isEmpty ? defaultTitle : title,
            targetRating: primaryRating,
            allowedRatings: effectiveAllowed,
            genderCategory: genderCategory,
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
            isLevelLocked: isLevelLocked,
            isPrivate: isPrivate
        )
        
        games.insert(newGame, at: 0)
        saveToDisk()
        FirestoreService.shared.saveGame(newGame)
        syncMatchReminders()
        
        postNotification(
            title: "🏐 New Game Scheduled",
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
        NotificationService.shared.cancelMatchReminder(gameId: gameId)
        syncMatchReminders()
        
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
                
                // Real-time chat notification: check for new messages in games the current user is in
                if let currentUser = self.currentUser {
                    for remoteGame in remoteGames {
                        let isUserInGame = remoteGame.allPlayerIds.contains(currentUser.id) ||
                                           remoteGame.team1PlayerIds.contains(currentUser.id) ||
                                           remoteGame.team2PlayerIds.contains(currentUser.id) ||
                                           remoteGame.waitlistPlayerIds.contains(currentUser.id) ||
                                           remoteGame.hostPlayerId == currentUser.id
                        guard isUserInGame else { continue }
                        
                        let oldGame = self.games.first(where: { $0.id == remoteGame.id })
                        let oldMsgIds = Set((oldGame?.messages ?? []).map { $0.id })
                        
                        let newMessages = remoteGame.messages.filter { msg in
                            msg.senderId != currentUser.id && !oldMsgIds.contains(msg.id)
                        }
                        
                        if self.hasCompletedInitialGamesSync {
                            for newMsg in newMessages {
                                self.postNotification(
                                    title: "💬 \(newMsg.senderName) (\(remoteGame.title))",
                                    message: "\"\(newMsg.text)\"",
                                    type: .matchChat,
                                    relatedGameId: remoteGame.id
                                )
                            }
                        }
                    }
                }
                
                self.hasCompletedInitialGamesSync = true
                self.games = remoteGames.filter { $0.status != .canceled }
                self.saveToDisk()
                self.syncMatchReminders()
            },
            onSlotsUpdate: { [weak self] remoteSlots in
                guard let self = self else { return }
                var merged = remoteSlots.filter { remote in
                    !self.recentlyDeletedSlotIds.contains(remote.id.uuidString) &&
                    !(remote.rawId != nil && self.recentlyDeletedSlotIds.contains(remote.rawId!))
                }
                for local in self.availabilitySlots {
                    let alreadyPresent = merged.contains { r in
                        r.id == local.id || (r.rawId != nil && local.rawId != nil && r.rawId == local.rawId)
                    }
                    if !alreadyPresent && !self.recentlyDeletedSlotIds.contains(local.id.uuidString) && !(local.rawId != nil && self.recentlyDeletedSlotIds.contains(local.rawId!)) {
                        merged.append(local)
                    }
                }
                self.availabilitySlots = merged
                self.saveToDisk()
            },
            onTournamentsUpdate: { [weak self] remoteTournaments in
                guard let self = self else { return }
                self.tournaments = self.deduplicateTournaments(remoteTournaments)
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
    private var tournamentsFileURL: URL { documentsDirectory.appendingPathComponent("setgames_tournaments.json") }
    private var userSessionKey: String { "setgames_current_user_id" }
    
    // MARK: - Tournament Deduplication
    
    public func deduplicateTournaments(_ list: [Tournament]) -> [Tournament] {
        var result: [Tournament] = []
        let calendar = Calendar.current
        
        for t in list {
            let tId = t.id.uuidString
            let tRaw = (t.rawId ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let tTitle = t.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            
            let existingIdx = result.firstIndex { e in
                let eId = e.id.uuidString
                let eRaw = (e.rawId ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                let eTitle = e.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                
                // 1. Direct ID match
                if eId == tId { return true }
                // 2. Direct rawId match
                if !tRaw.isEmpty && !eRaw.isEmpty && tRaw == eRaw { return true }
                // 3. Cross ID match
                if !tRaw.isEmpty && tRaw == eId { return true }
                if !eRaw.isEmpty && eRaw == tId { return true }
                // 4. Same title and same calendar day
                if !tTitle.isEmpty && !eTitle.isEmpty && tTitle == eTitle && calendar.isDate(e.date, inSameDayAs: t.date) {
                    return true
                }
                return false
            }
            
            if let idx = existingIdx {
                var existing = result[idx]
                
                // Merge registered teams without duplicate players
                for tm in t.teams {
                    let alreadyHas = existing.teams.contains { m in
                        m.id == tm.id || (m.player1Id == tm.player1Id && m.division == tm.division)
                    }
                    if !alreadyHas {
                        existing.teams.append(tm)
                    }
                }
                
                // Merge free agents without duplicates
                for fa in t.freeAgents {
                    let alreadyHas = existing.freeAgents.contains { m in
                        m.id == fa.id || (m.playerId == fa.playerId && m.division == fa.division)
                    }
                    if !alreadyHas {
                        existing.freeAgents.append(fa)
                    }
                }
                
                // Keep matches if existing has none
                if existing.matches.isEmpty && !t.matches.isEmpty {
                    existing.matches = t.matches
                }
                
                // Preserve fuller notes / host / rawId
                if existing.notes.isEmpty && !t.notes.isEmpty {
                    existing.notes = t.notes
                }
                if existing.hostPlayerId == nil && t.hostPlayerId != nil {
                    existing.hostPlayerId = t.hostPlayerId
                }
                if existing.rawId == nil && t.rawId != nil {
                    existing.rawId = t.rawId
                }
                
                result[idx] = existing
            } else {
                result.append(t)
            }
        }
        
        return result
    }
    
    // MARK: - Tournament Management API
    
    public func createTournament(
        title: String,
        date: Date,
        location: String,
        courts: [String],
        allowedDivisions: [TournamentDivisionCategory],
        maxTeamsPerDivision: Int = 8,
        notes: String,
        teamFormat: TournamentTeamFormat = .doubles2v2,
        coHostPlayerIds: [UUID] = []
    ) {
        let t = Tournament(
            id: UUID(),
            rawId: UUID().uuidString,
            title: title,
            hostPlayerId: currentUser?.id,
            coHostPlayerIds: coHostPlayerIds,
            date: date,
            location: location,
            courts: courts,
            allowedDivisions: allowedDivisions,
            maxTeamsPerDivision: maxTeamsPerDivision,
            teams: [],
            freeAgents: [],
            matches: [],
            status: "registration_open",
            notes: notes,
            createdAt: Date(),
            teamFormat: teamFormat
        )
        tournaments.insert(t, at: 0)
        saveToDisk()
        FirestoreService.shared.saveTournament(t)
        postNotification(
            title: "🏆 New Tournament Hosted",
            message: "\(title) is open for sign-ups at \(location)!",
            type: .tournament
        )
    }
    
    public func registerTeamForTournament(
        tournamentId: UUID,
        teamName: String,
        player1Id: UUID,
        player2Id: UUID?,
        player3Id: UUID? = nil,
        player4Id: UUID? = nil,
        division: TournamentDivisionCategory
    ) {
        guard let idx = tournaments.firstIndex(where: { $0.id == tournamentId }) else { return }
        // Remove any prior team or free-agent registration for player1
        tournaments[idx].teams.removeAll { $0.containsPlayer(player1Id) }
        tournaments[idx].freeAgents.removeAll { $0.playerId == player1Id }
        // Remove prior registrations for player3 and player4 if provided
        if let p3 = player3Id {
            tournaments[idx].teams.removeAll { $0.containsPlayer(p3) }
            tournaments[idx].freeAgents.removeAll { $0.playerId == p3 }
        }
        if let p4 = player4Id {
            tournaments[idx].teams.removeAll { $0.containsPlayer(p4) }
            tournaments[idx].freeAgents.removeAll { $0.playerId == p4 }
        }
        
        let newTeam = TournamentTeam(
            id: UUID(),
            teamName: teamName.isEmpty ? "Team \(players.first(where: { $0.id == player1Id })?.name ?? "Beach")" : teamName,
            player1Id: player1Id,
            player2Id: player2Id,
            player3Id: player3Id,
            player4Id: player4Id,
            seed: tournaments[idx].teams(for: division).count + 1,
            division: division
        )
        tournaments[idx].teams.append(newTeam)
        saveToDisk()
        FirestoreService.shared.saveTournament(tournaments[idx])
        
        postNotification(
            title: "✅ Registered for Tournament",
            message: "You're registered for \(division.displayName) in \(tournaments[idx].title)!",
            type: .tournament
        )
    }
    
    public func addDemoTeams(
        tournamentId: UUID,
        division: TournamentDivisionCategory
    ) {
        guard let idx = tournaments.firstIndex(where: { $0.id == tournamentId }) else { return }
        let currentCount = tournaments[idx].teams(for: division).count
        let demoNames = ["Sandstorm", "Spike Force", "Net Ninjas", "Ace Bandits"]
        
        for (i, name) in demoNames.enumerated() {
            let p1 = players.indices.contains(i * 2) ? players[i * 2].id : UUID()
            let p2 = players.indices.contains(i * 2 + 1) ? players[i * 2 + 1].id : UUID()
            let team = TournamentTeam(
                id: UUID(),
                teamName: name,
                player1Id: p1,
                player2Id: p2,
                seed: currentCount + i + 1,
                division: division
            )
            tournaments[idx].teams.append(team)
        }
        saveToDisk()
        FirestoreService.shared.saveTournament(tournaments[idx])
    }
    
    public func registerFreeAgentForTournament(
        tournamentId: UUID,
        playerId: UUID,
        division: TournamentDivisionCategory,
        notes: String = ""
    ) {
        guard let idx = tournaments.firstIndex(where: { $0.id == tournamentId }) else { return }
        tournaments[idx].teams.removeAll { $0.containsPlayer(playerId) }
        tournaments[idx].freeAgents.removeAll { $0.playerId == playerId }
        
        let fa = TournamentFreeAgent(
            id: UUID(),
            playerId: playerId,
            division: division,
            notes: notes
        )
        tournaments[idx].freeAgents.append(fa)
        saveToDisk()
        FirestoreService.shared.saveTournament(tournaments[idx])
        
        postNotification(
            title: "🏐 Free Agent Pool Joined",
            message: "You're in the free agent list for \(division.displayName)!",
            type: .tournament
        )
    }
    
    public func leaveTournament(tournamentId: UUID, playerId: UUID) {
        guard let idx = tournaments.firstIndex(where: { $0.id == tournamentId }) else { return }
        tournaments[idx].teams.removeAll { $0.containsPlayer(playerId) }
        tournaments[idx].freeAgents.removeAll { $0.playerId == playerId }
        saveToDisk()
        FirestoreService.shared.saveTournament(tournaments[idx])
    }
    
    public func updateTournamentMatchScore(
        tournamentId: UUID,
        matchId: UUID,
        team1Score: Int,
        team2Score: Int,
        winningTeamId: UUID?
    ) {
        guard let tIdx = tournaments.firstIndex(where: { $0.id == tournamentId }) else { return }
        guard let mIdx = tournaments[tIdx].matches.firstIndex(where: { $0.id == matchId }) else { return }
        
        tournaments[tIdx].matches[mIdx].team1Score = team1Score
        tournaments[tIdx].matches[mIdx].team2Score = team2Score
        tournaments[tIdx].matches[mIdx].winningTeamId = winningTeamId
        tournaments[tIdx].matches[mIdx].isCompleted = true
        
        saveToDisk()
        FirestoreService.shared.saveTournament(tournaments[tIdx])
    }
    
    // MARK: - Tournament Pool Play & Bracket Logic
    @discardableResult
    public func generatePoolPlay(
        tournamentId: UUID,
        division: TournamentDivisionCategory
    ) -> (success: Bool, message: String) {
        guard let tIdx = tournaments.firstIndex(where: { $0.id == tournamentId }) else {
            return (false, "Tournament not found.")
        }
        
        var divTeams = tournaments[tIdx].teams.filter { $0.division == division }
        guard divTeams.count >= 4 else {
            return (false, "At least 4 teams are required to generate pool play.")
        }
        
        // 1. Calculate average team Elo rating
        func teamElo(_ team: TournamentTeam) -> Double {
            let pIds = team.allPlayerIds
            let teamPlayers = players.filter { pIds.contains($0.id) }
            if teamPlayers.isEmpty { return 1500.0 }
            let total = teamPlayers.reduce(0) { $0 + $1.eloRating }
            return Double(total) / Double(teamPlayers.count)
        }
        
        // 2. Sort teams by Elo descending
        divTeams.sort { teamElo($0) > teamElo($1) }
        
        // Assign overall seed
        for i in 0..<divTeams.count {
            divTeams[i].seed = i + 1
        }
        
        // 3. Snake Seeding into Pools A & B
        let poolNames = ["Pool A", "Pool B"]
        let poolCount = 2
        var pools: [String: [TournamentTeam]] = ["Pool A": [], "Pool B": []]
        
        for (i, team) in divTeams.enumerated() {
            let round = i / poolCount
            let pos = i % poolCount
            let poolIndex = (round % 2 == 0) ? pos : (poolCount - 1 - pos)
            let pName = poolNames[poolIndex]
            var t = team
            t.poolName = pName
            t.poolSeed = (pools[pName]?.count ?? 0) + 1
            pools[pName]?.append(t)
        }
        
        // Update teams back into tournament
        for (poolName, pTeams) in pools {
            for team in pTeams {
                if let teamIdx = tournaments[tIdx].teams.firstIndex(where: { $0.id == team.id }) {
                    tournaments[tIdx].teams[teamIdx].seed = team.seed
                    tournaments[tIdx].teams[teamIdx].poolName = poolName
                    tournaments[tIdx].teams[teamIdx].poolSeed = team.poolSeed
                }
            }
        }
        
        // 4. Remove previous pool matches for this division
        tournaments[tIdx].matches.removeAll { $0.division == division && $0.stage == "pool" }
        
        // 5. Generate Round-Robin Matches for each pool
        let courts = tournaments[tIdx].courts.isEmpty ? ["Court #1", "Court #2"] : tournaments[tIdx].courts
        var generatedMatches: [TournamentMatch] = []
        var matchNum = 1
        
        for poolName in poolNames {
            guard let pTeams = pools[poolName], pTeams.count >= 2 else { continue }
            
            let pairings: [(r: Int, i1: Int, i2: Int)] = [
                (1, 0, min(3, pTeams.count - 1)),
                (1, min(1, pTeams.count - 1), min(2, pTeams.count - 1)),
                (2, 0, min(2, pTeams.count - 1)),
                (2, min(1, pTeams.count - 1), min(3, pTeams.count - 1)),
                (3, 0, min(1, pTeams.count - 1)),
                (3, min(2, pTeams.count - 1), min(3, pTeams.count - 1))
            ]
            
            var seenPairs = Set<String>()
            for p in pairings {
                let t1 = pTeams[p.i1]
                let t2 = pTeams[p.i2]
                guard t1.id != t2.id else { continue }
                let key = [t1.id.uuidString, t2.id.uuidString].sorted().joined(separator: "-")
                if seenPairs.contains(key) { continue }
                seenPairs.insert(key)
                
                let court = courts[(matchNum - 1) % courts.count]
                let match = TournamentMatch(
                    id: UUID(),
                    roundNumber: p.r,
                    matchNumber: matchNum,
                    division: division,
                    courtNumber: court,
                    team1Id: t1.id,
                    team2Id: t2.id,
                    poolName: poolName,
                    stage: "pool"
                )
                generatedMatches.append(match)
                matchNum += 1
            }
        }
        
        tournaments[tIdx].matches.append(contentsOf: generatedMatches)
        tournaments[tIdx].status = "in_progress"
        
        saveToDisk()
        FirestoreService.shared.saveTournament(tournaments[tIdx])
        
        postNotification(
            title: "🏐 Pool Play Generated!",
            message: "Pool A & Pool B matches are scheduled for \(division.displayName)!",
            type: .tournament
        )
        
        return (true, "Successfully generated \(generatedMatches.count) pool matches across Pools A & B.")
    }
    
    @discardableResult
    public func generatePlayoffBracket(
        tournamentId: UUID,
        division: TournamentDivisionCategory
    ) -> (success: Bool, message: String) {
        guard let tIdx = tournaments.firstIndex(where: { $0.id == tournamentId }) else {
            return (false, "Tournament not found.")
        }
        
        let t = tournaments[tIdx]
        let poolAStandings = t.poolStandings(for: division, poolName: "Pool A")
        let poolBStandings = t.poolStandings(for: division, poolName: "Pool B")
        let totalTeams = poolAStandings.count + poolBStandings.count
        
        guard totalTeams >= 4 else {
            return (false, "Need at least 4 teams with standings to create playoffs.")
        }
        
        // Remove existing playoff matches
        tournaments[tIdx].matches.removeAll { $0.division == division && $0.stage != "pool" }
        
        let courts = t.courts.isEmpty ? ["Court #1", "Court #2"] : t.courts
        let finalId = UUID()
        let thirdPlaceId = UUID()
        let semi1Id = UUID()
        let semi2Id = UUID()
        
        var newMatches: [TournamentMatch] = []
        var matchNumber = (tournaments[tIdx].matches.filter { $0.division == division }.map { $0.matchNumber }.max() ?? 0) + 1
        
        // Every team goes to playoff!
        // If either pool has > 2 teams (6 or 8 teams total), generate single-elimination Quarterfinals
        let hasQuarterfinals = poolAStandings.count > 2 || poolBStandings.count > 2
        
        if hasQuarterfinals {
            // QUARTERFINALS (Single Elimination)
            // Cross-pool pairings:
            // Match 1: A1 vs B4 (or bye if no B4) -> Winner to Semi 1 Slot 1
            // Match 2: B2 vs A3 (or bye if no A3) -> Winner to Semi 1 Slot 2
            // Match 3: B1 vs A4 (or bye if no A4) -> Winner to Semi 2 Slot 1
            // Match 4: A2 vs B3 (or bye if no B3) -> Winner to Semi 2 Slot 2
            let a1 = poolAStandings.indices.contains(0) ? poolAStandings[0].team : nil
            let a2 = poolAStandings.indices.contains(1) ? poolAStandings[1].team : nil
            let a3 = poolAStandings.indices.contains(2) ? poolAStandings[2].team : nil
            let a4 = poolAStandings.indices.contains(3) ? poolAStandings[3].team : nil
            
            let b1 = poolBStandings.indices.contains(0) ? poolBStandings[0].team : nil
            let b2 = poolBStandings.indices.contains(1) ? poolBStandings[1].team : nil
            let b3 = poolBStandings.indices.contains(2) ? poolBStandings[2].team : nil
            let b4 = poolBStandings.indices.contains(3) ? poolBStandings[3].team : nil
            
            var semi1Slot1TeamId: UUID? = nil
            var semi1Slot2TeamId: UUID? = nil
            var semi2Slot1TeamId: UUID? = nil
            var semi2Slot2TeamId: UUID? = nil
            
            // QF 1: A1 vs B4
            if let a1 = a1, let b4 = b4 {
                newMatches.append(TournamentMatch(
                    id: UUID(),
                    roundNumber: 2,
                    matchNumber: matchNumber,
                    division: division,
                    courtNumber: courts[0],
                    team1Id: a1.id,
                    team2Id: b4.id,
                    stage: "quarterfinal",
                    bracketRound: 1,
                    nextMatchId: semi1Id,
                    nextMatchSlot: 1
                ))
                matchNumber += 1
            } else if let a1 = a1 {
                semi1Slot1TeamId = a1.id
            }
            
            // QF 2: B2 vs A3
            if let b2 = b2, let a3 = a3 {
                newMatches.append(TournamentMatch(
                    id: UUID(),
                    roundNumber: 2,
                    matchNumber: matchNumber,
                    division: division,
                    courtNumber: courts[courts.count > 1 ? 1 : 0],
                    team1Id: b2.id,
                    team2Id: a3.id,
                    stage: "quarterfinal",
                    bracketRound: 1,
                    nextMatchId: semi1Id,
                    nextMatchSlot: 2
                ))
                matchNumber += 1
            } else if let b2 = b2 {
                semi1Slot2TeamId = b2.id
            }
            
            // QF 3: B1 vs A4
            if let b1 = b1, let a4 = a4 {
                newMatches.append(TournamentMatch(
                    id: UUID(),
                    roundNumber: 2,
                    matchNumber: matchNumber,
                    division: division,
                    courtNumber: courts[0],
                    team1Id: b1.id,
                    team2Id: a4.id,
                    stage: "quarterfinal",
                    bracketRound: 1,
                    nextMatchId: semi2Id,
                    nextMatchSlot: 1
                ))
                matchNumber += 1
            } else if let b1 = b1 {
                semi2Slot1TeamId = b1.id
            }
            
            // QF 4: A2 vs B3
            if let a2 = a2, let b3 = b3 {
                newMatches.append(TournamentMatch(
                    id: UUID(),
                    roundNumber: 2,
                    matchNumber: matchNumber,
                    division: division,
                    courtNumber: courts[courts.count > 1 ? 1 : 0],
                    team1Id: a2.id,
                    team2Id: b3.id,
                    stage: "quarterfinal",
                    bracketRound: 1,
                    nextMatchId: semi2Id,
                    nextMatchSlot: 2
                ))
                matchNumber += 1
            } else if let a2 = a2 {
                semi2Slot2TeamId = a2.id
            }
            
            // SEMIFINALS
            newMatches.append(TournamentMatch(
                id: semi1Id,
                roundNumber: 3,
                matchNumber: matchNumber,
                division: division,
                courtNumber: courts[0],
                team1Id: semi1Slot1TeamId,
                team2Id: semi1Slot2TeamId,
                stage: "semifinal",
                bracketRound: 2,
                nextMatchId: finalId,
                nextMatchSlot: 1
            ))
            matchNumber += 1
            
            newMatches.append(TournamentMatch(
                id: semi2Id,
                roundNumber: 3,
                matchNumber: matchNumber,
                division: division,
                courtNumber: courts[courts.count > 1 ? 1 : 0],
                team1Id: semi2Slot1TeamId,
                team2Id: semi2Slot2TeamId,
                stage: "semifinal",
                bracketRound: 2,
                nextMatchId: finalId,
                nextMatchSlot: 2
            ))
            matchNumber += 1
        } else {
            // 4 Teams: All 4 teams advance directly to Semifinals (A1 vs B2, B1 vs A2)
            let a1 = poolAStandings.indices.contains(0) ? poolAStandings[0].team : nil
            let a2 = poolAStandings.indices.contains(1) ? poolAStandings[1].team : nil
            let b1 = poolBStandings.indices.contains(0) ? poolBStandings[0].team : nil
            let b2 = poolBStandings.indices.contains(1) ? poolBStandings[1].team : nil
            
            newMatches.append(TournamentMatch(
                id: semi1Id,
                roundNumber: 2,
                matchNumber: matchNumber,
                division: division,
                courtNumber: courts[0],
                team1Id: a1?.id,
                team2Id: b2?.id,
                stage: "semifinal",
                bracketRound: 1,
                nextMatchId: finalId,
                nextMatchSlot: 1
            ))
            matchNumber += 1
            
            newMatches.append(TournamentMatch(
                id: semi2Id,
                roundNumber: 2,
                matchNumber: matchNumber,
                division: division,
                courtNumber: courts[courts.count > 1 ? 1 : 0],
                team1Id: b1?.id,
                team2Id: a2?.id,
                stage: "semifinal",
                bracketRound: 1,
                nextMatchId: finalId,
                nextMatchSlot: 2
            ))
            matchNumber += 1
        }
        
        // Championship Final: Winner Semi 1 vs Winner Semi 2
        newMatches.append(TournamentMatch(
            id: finalId,
            roundNumber: hasQuarterfinals ? 4 : 3,
            matchNumber: matchNumber,
            division: division,
            courtNumber: courts[0],
            stage: "final",
            bracketRound: hasQuarterfinals ? 3 : 2
        ))
        matchNumber += 1
        
        // 3rd Place Consolation: Loser Semi 1 vs Loser Semi 2
        newMatches.append(TournamentMatch(
            id: thirdPlaceId,
            roundNumber: hasQuarterfinals ? 4 : 3,
            matchNumber: matchNumber,
            division: division,
            courtNumber: courts[courts.count > 1 ? 1 : 0],
            stage: "third_place",
            bracketRound: hasQuarterfinals ? 3 : 2
        ))
        
        tournaments[tIdx].matches.append(contentsOf: newMatches)
        
        saveToDisk()
        FirestoreService.shared.saveTournament(tournaments[tIdx])
        
        postNotification(
            title: "🏆 Single Elimination Playoff Live!",
            message: "All teams have advanced to the single-elimination playoff bracket for \(division.displayName)!",
            type: .tournament
        )
        
        return (true, "Playoff bracket generated! All teams advanced to single-elimination.")
    }
    
    @discardableResult
    public func submitTournamentMatchScore(
        tournamentId: UUID,
        matchId: UUID,
        team1Score: Int,
        team2Score: Int
    ) -> (success: Bool, message: String) {
        guard let tIdx = tournaments.firstIndex(where: { $0.id == tournamentId }) else {
            return (false, "Tournament not found.")
        }
        guard let mIdx = tournaments[tIdx].matches.firstIndex(where: { $0.id == matchId }) else {
            return (false, "Match not found.")
        }
        
        let match = tournaments[tIdx].matches[mIdx]
        guard let t1Id = match.team1Id, let t2Id = match.team2Id else {
            return (false, "Match teams are not yet determined.")
        }
        guard team1Score != team2Score else {
            return (false, "Matches cannot end in a tie.")
        }
        
        let winningTeamId = team1Score > team2Score ? t1Id : t2Id
        let losingTeamId = team1Score > team2Score ? t2Id : t1Id
        
        tournaments[tIdx].matches[mIdx].team1Score = team1Score
        tournaments[tIdx].matches[mIdx].team2Score = team2Score
        tournaments[tIdx].matches[mIdx].winningTeamId = winningTeamId
        tournaments[tIdx].matches[mIdx].isCompleted = true
        
        // Automated Bracket Advancement
        if let nextId = match.nextMatchId,
           let nextSlot = match.nextMatchSlot,
           let nextIdx = tournaments[tIdx].matches.firstIndex(where: { $0.id == nextId }) {
            if nextSlot == 1 {
                tournaments[tIdx].matches[nextIdx].team1Id = winningTeamId
            } else if nextSlot == 2 {
                tournaments[tIdx].matches[nextIdx].team2Id = winningTeamId
            }
        }
        
        // If semifinal, also place loser into 3rd place match if present
        if match.stage == "semifinal" || match.stage == "semi" {
            if let bronzeIdx = tournaments[tIdx].matches.firstIndex(where: { $0.division == match.division && $0.stage == "third_place" }) {
                if tournaments[tIdx].matches[bronzeIdx].team1Id == nil {
                    tournaments[tIdx].matches[bronzeIdx].team1Id = losingTeamId
                } else if tournaments[tIdx].matches[bronzeIdx].team2Id == nil {
                    tournaments[tIdx].matches[bronzeIdx].team2Id = losingTeamId
                }
            }
        }
        
        let team1 = tournaments[tIdx].teams.first(where: { $0.id == t1Id })
        let team2 = tournaments[tIdx].teams.first(where: { $0.id == t2Id })
        let winnerName = (winningTeamId == t1Id ? team1?.teamName : team2?.teamName) ?? "Winner"
        let loserName = (winningTeamId == t1Id ? team2?.teamName : team1?.teamName) ?? "Opponent"
        
        saveToDisk()
        FirestoreService.shared.saveTournament(tournaments[tIdx])
        
        postNotification(
            title: "🏐 Match Score Reported",
            message: "\(winnerName) defeated \(loserName) (\(max(team1Score, team2Score))-\(min(team1Score, team2Score))) on \(match.courtNumber)",
            type: .scoreLogged
        )
        
        return (true, "Score submitted successfully!")
    }
    
    public func updateTournament(
        id: UUID,
        title: String,
        date: Date,
        location: String,
        courts: [String],
        allowedDivisions: [TournamentDivisionCategory],
        maxTeamsPerDivision: Int,
        notes: String,
        teamFormat: TournamentTeamFormat,
        coHostPlayerIds: [UUID]? = nil
    ) -> (success: Bool, message: String) {
        guard let user = currentUser,
              let idx = tournaments.firstIndex(where: { $0.id == id }) else {
            return (false, "Tournament not found.")
        }
        let isHost = tournaments[idx].isHostOrCoHost(user.id) || user.isRoot
        guard isHost else {
            return (false, "Only the tournament host, co-host, or admin can edit this tournament.")
        }
        tournaments[idx].title = title
        tournaments[idx].date = date
        tournaments[idx].location = location
        tournaments[idx].courts = courts
        tournaments[idx].allowedDivisions = allowedDivisions
        tournaments[idx].maxTeamsPerDivision = maxTeamsPerDivision
        tournaments[idx].notes = notes
        tournaments[idx].teamFormat = teamFormat
        if let coHosts = coHostPlayerIds {
            tournaments[idx].coHostPlayerIds = coHosts
        }
        saveToDisk()
        FirestoreService.shared.saveTournament(tournaments[idx])
        return (true, "Tournament updated successfully.")
    }
    
    @discardableResult
    public func addCoHost(tournamentId: UUID, playerId: UUID) -> (success: Bool, message: String) {
        guard let user = currentUser,
              let idx = tournaments.firstIndex(where: { $0.id == tournamentId }) else {
            return (false, "Tournament not found.")
        }
        let canManage = (tournaments[idx].hostPlayerId == user.id) || user.isRoot
        guard canManage else {
            return (false, "Only the primary host or admin can add co-hosts.")
        }
        guard playerId != tournaments[idx].hostPlayerId else {
            return (false, "Player is already the tournament host.")
        }
        if !tournaments[idx].coHostPlayerIds.contains(playerId) {
            tournaments[idx].coHostPlayerIds.append(playerId)
            saveToDisk()
            FirestoreService.shared.saveTournament(tournaments[idx])
        }
        return (true, "Co-host added successfully.")
    }
    
    @discardableResult
    public func removeCoHost(tournamentId: UUID, playerId: UUID) -> (success: Bool, message: String) {
        guard let user = currentUser,
              let idx = tournaments.firstIndex(where: { $0.id == tournamentId }) else {
            return (false, "Tournament not found.")
        }
        let canManage = (tournaments[idx].hostPlayerId == user.id) || user.isRoot
        guard canManage else {
            return (false, "Only the primary host or admin can remove co-hosts.")
        }
        tournaments[idx].coHostPlayerIds.removeAll { $0 == playerId }
        saveToDisk()
        FirestoreService.shared.saveTournament(tournaments[idx])
        return (true, "Co-host removed successfully.")
    }
    
    @discardableResult
    public func deleteTournament(id: UUID) -> (success: Bool, message: String) {
        guard let user = currentUser,
              let t = tournaments.first(where: { $0.id == id }) else {
            return (false, "Tournament not found.")
        }
        let isHost = (t.hostPlayerId == user.id) || user.isRoot
        guard isHost else {
            return (false, "Only the tournament host or admin can delete this tournament.")
        }
        tournaments.removeAll { $0.id == id }
        saveToDisk()
        FirestoreService.shared.deleteTournament(id: id, rawId: t.rawId)
        return (true, "Tournament deleted successfully.")
    }
    
    public func saveToDisk() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        if let data = try? encoder.encode(players) {
            try? data.write(to: playersFileURL, options: .atomic)
        }
        if let data = try? encoder.encode(games) {
            try? data.write(to: gamesFileURL, options: .atomic)
        }
        if let data = try? encoder.encode(tournaments) {
            try? data.write(to: tournamentsFileURL, options: .atomic)
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
        decoder.dateDecodingStrategy = .iso8601
        guard let pData = try? Data(contentsOf: playersFileURL),
              let loadedPlayers = try? decoder.decode([Player].self, from: pData),
              !loadedPlayers.isEmpty else {
            return false
        }
        
        self.players = loadedPlayers
        
        if let gData = try? Data(contentsOf: gamesFileURL),
           let loadedGames = try? decoder.decode([SetGame].self, from: gData) {
            self.games = loadedGames.filter { $0.status != .canceled }
        }
        
        if let tData = try? Data(contentsOf: tournamentsFileURL),
           let loadedTournaments = try? decoder.decode([Tournament].self, from: tData) {
            self.tournaments = deduplicateTournaments(loadedTournaments)
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
        
        if self.currentUser?.isRoot != true {
            self.isDemoModeEnabled = false
            UserDefaults.standard.set(false, forKey: "isDemoModeEnabled")
        }
        
        return true
    }
}
