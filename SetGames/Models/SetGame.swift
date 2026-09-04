import Foundation

public enum GameFormat: String, Codable, CaseIterable {
    case bestOfThree = "Best of 3 Sets (21-21-15)"
    case singleSet21 = "Single Set to 21"
    case kingOfTheBeach = "King of Beach (Rotating 3 Sets)"
    
    public var shortTitle: String {
        switch self {
        case .bestOfThree: return "2v2 Match"
        case .singleSet21: return "Quick Set 21"
        case .kingOfTheBeach: return "King/Queen"
        }
    }
}

public enum GameStatus: String, Codable, CaseIterable {
    case scheduled = "Scheduled"
    case inProgress = "In Progress"
    case completed = "Completed"
    case canceled = "Canceled"
}

public struct SetScore: Codable, Hashable, Identifiable {
    public var id: UUID = UUID()
    public var setNumber: Int
    public var team1Score: Int
    public var team2Score: Int
    
    public init(setNumber: Int, team1Score: Int, team2Score: Int) {
        self.setNumber = setNumber
        self.team1Score = team1Score
        self.team2Score = team2Score
    }
    
    public var scoreText: String {
        "\(team1Score) - \(team2Score)"
    }
    
    public var isTeam1Winner: Bool {
        team1Score > team2Score
    }
}

public struct SubMatch: Identifiable, Codable, Hashable {
    public var id: UUID
    public var matchNumber: Int
    public var courtNumber: String
    public var setNumber: Int
    public var team1PlayerIds: [UUID]
    public var team2PlayerIds: [UUID]
    public var restingPlayerIds: [UUID]
    public var team1Score: Int?
    public var team2Score: Int?
    public var isCompleted: Bool
    public var winningTeam: Int?
    
    public init(
        id: UUID = UUID(),
        matchNumber: Int,
        courtNumber: String = "Court #1",
        setNumber: Int = 1,
        team1PlayerIds: [UUID] = [],
        team2PlayerIds: [UUID] = [],
        restingPlayerIds: [UUID] = [],
        team1Score: Int? = nil,
        team2Score: Int? = nil,
        isCompleted: Bool = false,
        winningTeam: Int? = nil
    ) {
        self.id = id
        self.matchNumber = matchNumber
        self.courtNumber = courtNumber
        self.setNumber = setNumber
        self.team1PlayerIds = team1PlayerIds
        self.team2PlayerIds = team2PlayerIds
        self.restingPlayerIds = restingPlayerIds
        self.team1Score = team1Score
        self.team2Score = team2Score
        self.isCompleted = isCompleted
        self.winningTeam = winningTeam
    }
}

public struct GameChatMessage: Identifiable, Codable, Hashable {
    public var id: UUID
    public var senderId: UUID
    public var senderName: String
    public var text: String
    public var date: Date
    
    public init(id: UUID = UUID(), senderId: UUID, senderName: String, text: String, date: Date = Date()) {
        self.id = id
        self.senderId = senderId
        self.senderName = senderName
        self.text = text
        self.date = date
    }
    
    public var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

public struct SetGame: Identifiable, Codable, Hashable {
    public var id: UUID
    public var title: String
    public var targetRating: RatingTier
    public var format: GameFormat
    public var status: GameStatus
    public var scheduledDate: Date
    public var courtLocation: String
    public var courtNumber: String
    
    // Team 1 (2 players)
    public var team1PlayerIds: [UUID]
    // Team 2 (2 players)
    public var team2PlayerIds: [UUID]
    
    // Completed sets
    public var setScores: [SetScore]
    public var winningTeam: Int? // 1 or 2
    
    // Matchmaking metadata
    public var isAutoMatched: Bool
    public var matchedOptionName: String
    public var notes: String
    
    // Host & Level Lock
    public var hostPlayerId: UUID?
    public var isLevelLocked: Bool
    public var maxPlayers: Int
    // Submitted ratings: [ReviewerUUID: [TargetPlayerUUID: Stars]]
    public var submittedRatings: [UUID: [UUID: Int]]
    // Match Chat & ETA messages
    public var messages: [GameChatMessage]
    public var rawId: String?
    public var subMatches: [SubMatch]
    // Waitlist for full games
    public var waitlistPlayerIds: [UUID]
    
    public init(
        id: UUID = UUID(),
        rawId: String? = nil,
        title: String = "Beach Doubles Set",
        targetRating: RatingTier,
        format: GameFormat = .bestOfThree,
        status: GameStatus = .scheduled,
        scheduledDate: Date,
        courtLocation: String = "Manhattan Beach Pier",
        courtNumber: String = "Court #4",
        maxPlayers: Int = 4,
        team1PlayerIds: [UUID] = [],
        team2PlayerIds: [UUID] = [],
        setScores: [SetScore] = [],
        winningTeam: Int? = nil,
        isAutoMatched: Bool = true,
        matchedOptionName: String = "Smart Availability",
        notes: String = "Bring an official Molten or Wilson beach ball!",
        hostPlayerId: UUID? = nil,
        isLevelLocked: Bool = true,
        submittedRatings: [UUID: [UUID: Int]] = [:],
        messages: [GameChatMessage] = [],
        subMatches: [SubMatch] = [],
        waitlistPlayerIds: [UUID] = []
    ) {
        self.id = id
        self.rawId = rawId ?? id.uuidString
        self.title = title
        self.targetRating = targetRating
        self.format = format
        self.status = status
        self.scheduledDate = scheduledDate
        self.courtLocation = courtLocation
        self.courtNumber = courtNumber
        self.maxPlayers = maxPlayers
        self.team1PlayerIds = team1PlayerIds
        self.team2PlayerIds = team2PlayerIds
        self.subMatches = subMatches
        self.setScores = setScores
        self.winningTeam = winningTeam
        self.isAutoMatched = isAutoMatched
        self.matchedOptionName = matchedOptionName
        self.notes = notes
        self.hostPlayerId = hostPlayerId
        self.isLevelLocked = isLevelLocked
        self.submittedRatings = submittedRatings
        self.messages = messages
        self.waitlistPlayerIds = waitlistPlayerIds
    }
    
    public var allPlayerIds: [UUID] {
        team1PlayerIds + team2PlayerIds
    }
    
    public func isPlayerWaitlisted(_ playerId: UUID) -> Bool {
        waitlistPlayerIds.contains(playerId)
    }
    
    public func waitlistPosition(for playerId: UUID) -> Int? {
        if let idx = waitlistPlayerIds.firstIndex(of: playerId) {
            return idx + 1
        }
        return nil
    }
    
    public var teamCapacity: Int {
        max(1, maxPlayers / 2)
    }
    
    public var isFull: Bool {
        allPlayerIds.count >= maxPlayers
    }
    
    public var spotsRemaining: Int {
        max(0, maxPlayers - allPlayerIds.count)
    }
    
    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d • h:mm a"
        return formatter.string(from: scheduledDate)
    }
    
    public var team1SetsWon: Int {
        setScores.filter { $0.team1Score > $0.team2Score }.count
    }
    
    public var team2SetsWon: Int {
        setScores.filter { $0.team2Score > $0.team1Score }.count
    }
    
    public var scoreSummary: String {
        if setScores.isEmpty {
            return "Upcoming"
        }
        return setScores.map { "\($0.team1Score)-\($0.team2Score)" }.joined(separator: ", ")
    }
    
    public static func parseUUID(from string: String?) -> UUID? {
        guard let string = string, !string.isEmpty else { return nil }
        if let uuid = UUID(uuidString: string) {
            return uuid
        }
        var hash = [UInt8](repeating: 0, count: 16)
        let bytes = Array(string.utf8)
        for (i, b) in bytes.enumerated() {
            hash[i % 16] ^= b
        }
        hash[6] = (hash[6] & 0x0F) | 0x40
        hash[8] = (hash[8] & 0x3F) | 0x80
        let tuple: uuid_t = (
            hash[0], hash[1], hash[2], hash[3],
            hash[4], hash[5], hash[6], hash[7],
            hash[8], hash[9], hash[10], hash[11],
            hash[12], hash[13], hash[14], hash[15]
        )
        return UUID(uuid: tuple)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, targetRating, format, status, scheduledDate, courtLocation, courtNumber
        case team1PlayerIds, team2PlayerIds, setScores, winningTeam, isAutoMatched, matchedOptionName, notes
        case hostPlayerId, isLevelLocked, submittedRatings, messages, maxPlayers, subMatches, waitlistPlayerIds
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        
        // 1. ID decoding (UUID or String)
        if let raw = try? c.decode(String.self, forKey: .id) {
            rawId = raw
            id = UUID(uuidString: raw) ?? SetGame.parseUUID(from: raw) ?? UUID()
        } else if let uuid = try? c.decode(UUID.self, forKey: .id) {
            id = uuid
            rawId = uuid.uuidString
        } else {
            id = UUID()
            rawId = nil
        }
        
        // 2. Title
        title = (try? c.decode(String.self, forKey: .title)) ?? "Beach Match"
        
        // 3. Rating Tier
        if let tier = try? c.decode(RatingTier.self, forKey: .targetRating) {
            targetRating = tier
        } else if let tierStr = try? c.decode(String.self, forKey: .targetRating) {
            switch tierStr.lowercased() {
            case "novice", "nov": targetRating = .novice
            case "intermediate", "int": targetRating = .intermediate
            case "b": targetRating = .b
            case "a": targetRating = .a
            case "aa": targetRating = .aa
            case "open": targetRating = .open
            default: targetRating = .b
            }
        } else {
            targetRating = .b
        }
        
        // 4. Format
        if let f = try? c.decode(GameFormat.self, forKey: .format) {
            format = f
        } else if let fStr = try? c.decode(String.self, forKey: .format) {
            if fStr.localizedCaseInsensitiveContains("king") {
                format = .kingOfTheBeach
            } else if fStr.localizedCaseInsensitiveContains("single") || fStr.localizedCaseInsensitiveContains("1 set") || fStr.localizedCaseInsensitiveContains("21") {
                format = .singleSet21
            } else {
                format = .bestOfThree
            }
        } else {
            format = .bestOfThree
        }
        
        // 5. Status
        if let s = try? c.decode(GameStatus.self, forKey: .status) {
            status = s
        } else if let sStr = try? c.decode(String.self, forKey: .status) {
            switch sStr.lowercased() {
            case "scheduled": status = .scheduled
            case "inprogress", "in progress", "in_progress": status = .inProgress
            case "completed": status = .completed
            case "canceled", "cancelled": status = .canceled
            default: status = .scheduled
            }
        } else {
            status = .scheduled
        }
        
        // 6. Scheduled Date (Date, ISO8601 String, or Timestamp)
        if let d = try? c.decode(Date.self, forKey: .scheduledDate) {
            scheduledDate = d
        } else if let dStr = try? c.decode(String.self, forKey: .scheduledDate) {
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let parsed = iso.date(from: dStr) {
                scheduledDate = parsed
            } else {
                iso.formatOptions = [.withInternetDateTime]
                scheduledDate = iso.date(from: dStr) ?? Date()
            }
        } else if let ts = try? c.decode(Double.self, forKey: .scheduledDate) {
            if ts > 500_000_000 && ts < 1_500_000_000 {
                scheduledDate = Date(timeIntervalSinceReferenceDate: ts)
            } else if ts > 10_000_000_000 {
                scheduledDate = Date(timeIntervalSince1970: ts / 1000)
            } else {
                scheduledDate = Date(timeIntervalSince1970: ts)
            }
        } else {
            scheduledDate = Date()
        }
        
        // 7. Court Location & Number
        courtLocation = (try? c.decode(String.self, forKey: .courtLocation)) ?? "Main Beach"
        courtNumber = (try? c.decode(String.self, forKey: .courtNumber)) ?? "Court #1"
        maxPlayers = (try? c.decode(Int.self, forKey: .maxPlayers)) ?? 4
        
        // 8. Team 1 & Team 2 Player IDs
        if let t1 = try? c.decode([UUID].self, forKey: .team1PlayerIds) {
            team1PlayerIds = t1
        } else if let t1Str = try? c.decode([String].self, forKey: .team1PlayerIds) {
            team1PlayerIds = t1Str.compactMap { SetGame.parseUUID(from: $0) }
        } else {
            team1PlayerIds = []
        }
        
        if let t2 = try? c.decode([UUID].self, forKey: .team2PlayerIds) {
            team2PlayerIds = t2
        } else if let t2Str = try? c.decode([String].self, forKey: .team2PlayerIds) {
            team2PlayerIds = t2Str.compactMap { SetGame.parseUUID(from: $0) }
        } else {
            team2PlayerIds = []
        }
        
        // 9. Scores & Winner
        setScores = (try? c.decode([SetScore].self, forKey: .setScores)) ?? []
        winningTeam = try? c.decode(Int.self, forKey: .winningTeam)
        isAutoMatched = (try? c.decode(Bool.self, forKey: .isAutoMatched)) ?? false
        matchedOptionName = (try? c.decode(String.self, forKey: .matchedOptionName)) ?? "Host Scheduled"
        notes = (try? c.decode(String.self, forKey: .notes)) ?? ""
        
        // 10. Host Player ID
        if let hUUID = try? c.decode(UUID.self, forKey: .hostPlayerId) {
            hostPlayerId = hUUID
        } else if let hStr = try? c.decode(String.self, forKey: .hostPlayerId) {
            hostPlayerId = SetGame.parseUUID(from: hStr)
        } else {
            hostPlayerId = nil
        }
        
        isLevelLocked = (try? c.decode(Bool.self, forKey: .isLevelLocked)) ?? true
        submittedRatings = (try? c.decode([UUID: [UUID: Int]].self, forKey: .submittedRatings)) ?? [:]
        messages = (try? c.decode([GameChatMessage].self, forKey: .messages)) ?? []
        subMatches = (try? c.decode([SubMatch].self, forKey: .subMatches)) ?? []
        
        if let wl = try? c.decode([UUID].self, forKey: .waitlistPlayerIds) {
            waitlistPlayerIds = wl
        } else if let wlStr = try? c.decode([String].self, forKey: .waitlistPlayerIds) {
            waitlistPlayerIds = wlStr.compactMap { SetGame.parseUUID(from: $0) }
        } else {
            waitlistPlayerIds = []
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(rawId ?? id.uuidString, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encode(targetRating, forKey: .targetRating)
        try c.encode(format, forKey: .format)
        try c.encode(status, forKey: .status)
        try c.encode(scheduledDate, forKey: .scheduledDate)
        try c.encode(courtLocation, forKey: .courtLocation)
        try c.encode(courtNumber, forKey: .courtNumber)
        try c.encode(maxPlayers, forKey: .maxPlayers)
        try c.encode(team1PlayerIds, forKey: .team1PlayerIds)
        try c.encode(team2PlayerIds, forKey: .team2PlayerIds)
        try c.encode(setScores, forKey: .setScores)
        try c.encodeIfPresent(winningTeam, forKey: .winningTeam)
        try c.encode(isAutoMatched, forKey: .isAutoMatched)
        try c.encode(matchedOptionName, forKey: .matchedOptionName)
        try c.encode(notes, forKey: .notes)
        try c.encodeIfPresent(hostPlayerId, forKey: .hostPlayerId)
        try c.encode(isLevelLocked, forKey: .isLevelLocked)
        try c.encode(submittedRatings, forKey: .submittedRatings)
        try c.encode(messages, forKey: .messages)
        try c.encode(subMatches, forKey: .subMatches)
        try c.encode(waitlistPlayerIds, forKey: .waitlistPlayerIds)
    }
}
