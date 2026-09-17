import Foundation

public enum TournamentDivisionCategory: String, Codable, CaseIterable, Identifiable {
    case coedNovice2v2 = "2v2 Coed Novice"
    case coedIntermediate2v2 = "2v2 Coed Intermediate"
    case coed4v4 = "4v4 Coed"
    case mensIntermediate2v2 = "2v2 Men's Intermediate"
    
    public var id: String { rawValue }
    
    public var displayName: String { rawValue }
    
    public var icon: String {
        switch self {
        case .coedNovice2v2, .coedIntermediate2v2: return "👫"
        case .coed4v4: return "🏐"
        case .mensIntermediate2v2: return "👨"
        }
    }
    
    public var genderCategory: GameGenderCategory {
        switch self {
        case .coedNovice2v2, .coedIntermediate2v2, .coed4v4: return .coed
        case .mensIntermediate2v2: return .male
        }
    }
    
    public var skillLevel: String {
        switch self {
        case .coedNovice2v2: return "Novice"
        case .coedIntermediate2v2, .mensIntermediate2v2: return "Intermediate"
        case .coed4v4: return "Open"
        }
    }
    
    public var teamSize: Int {
        switch self {
        case .coed4v4: return 4
        case .coedNovice2v2, .coedIntermediate2v2, .mensIntermediate2v2: return 2
        }
    }
    
    public var isQuads: Bool {
        self == .coed4v4
    }
    
    public var isNovice: Bool {
        self == .coedNovice2v2
    }
    
    public var maxAllowedRating: RatingTier? {
        switch self {
        case .coedNovice2v2: return .novice
        default: return nil
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        if let exact = TournamentDivisionCategory(rawValue: raw) {
            self = exact
            return
        }
        // Backward compatibility mapping for legacy values
        switch raw {
        case "Coed Novice", "2v2 Coed Novice":
            self = .coedNovice2v2
        case "Coed Intermediate", "2v2 Coed Intermediate":
            self = .coedIntermediate2v2
        case "Men's Intermediate", "2v2 Men's Intermediate":
            self = .mensIntermediate2v2
        case "4v4 Coed", "4v4":
            self = .coed4v4
        case "Men's Novice":
            // Men's Novice deprecated -> mapped to Men's Intermediate
            self = .mensIntermediate2v2
        case "Women's Novice", "Women's Intermediate":
            // Women's divisions deprecated -> mapped to Coed Intermediate
            self = .coedIntermediate2v2
        default:
            self = .coedNovice2v2
        }
    }
}

public enum TournamentTeamFormat: String, Codable, CaseIterable, Identifiable {
    case doubles2v2 = "2v2"
    case quads4v4 = "4v4"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .doubles2v2: return "2v2 Doubles"
        case .quads4v4: return "4v4 Quads"
        }
    }
    
    public var icon: String {
        switch self {
        case .doubles2v2: return "👥"
        case .quads4v4: return "🏐"
        }
    }
    
    public var teamSize: Int {
        switch self {
        case .doubles2v2: return 2
        case .quads4v4: return 4
        }
    }
}

public struct TournamentFreeAgent: Identifiable, Codable, Hashable {
    public var id: UUID
    public var playerId: UUID
    public var division: TournamentDivisionCategory
    public var notes: String
    public var registeredAt: Date
    
    public init(
        id: UUID = UUID(),
        playerId: UUID,
        division: TournamentDivisionCategory,
        notes: String = "",
        registeredAt: Date = Date()
    ) {
        self.id = id
        self.playerId = playerId
        self.division = division
        self.notes = notes
        self.registeredAt = registeredAt
    }
    
    enum CodingKeys: String, CodingKey {
        case id, playerId, division, notes, registeredAt
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let raw = try? container.decode(String.self, forKey: .id) {
            id = UUID(uuidString: raw) ?? SetGame.parseUUID(from: raw) ?? UUID()
        } else if let uuid = try? container.decode(UUID.self, forKey: .id) {
            id = uuid
        } else {
            id = UUID()
        }
        
        if let pRaw = try? container.decode(String.self, forKey: .playerId) {
            playerId = UUID(uuidString: pRaw) ?? SetGame.parseUUID(from: pRaw) ?? UUID()
        } else {
            playerId = (try? container.decode(UUID.self, forKey: .playerId)) ?? UUID()
        }
        
        division = try container.decode(TournamentDivisionCategory.self, forKey: .division)
        notes = (try? container.decode(String.self, forKey: .notes)) ?? ""
        registeredAt = (try? container.decode(Date.self, forKey: .registeredAt)) ?? Date()
    }
}

public struct TournamentTeam: Identifiable, Codable, Hashable {
    public var id: UUID
    public var teamName: String
    public var player1Id: UUID
    public var player2Id: UUID?
    public var player3Id: UUID?
    public var player4Id: UUID?
    public var seed: Int?
    public var poolName: String?
    public var poolSeed: Int?
    public var division: TournamentDivisionCategory
    public var isConfirmed: Bool
    public var registeredAt: Date
    
    public init(
        id: UUID = UUID(),
        teamName: String,
        player1Id: UUID,
        player2Id: UUID? = nil,
        player3Id: UUID? = nil,
        player4Id: UUID? = nil,
        seed: Int? = nil,
        poolName: String? = nil,
        poolSeed: Int? = nil,
        division: TournamentDivisionCategory,
        isConfirmed: Bool = true,
        registeredAt: Date = Date()
    ) {
        self.id = id
        self.teamName = teamName
        self.player1Id = player1Id
        self.player2Id = player2Id
        self.player3Id = player3Id
        self.player4Id = player4Id
        self.seed = seed
        self.poolName = poolName
        self.poolSeed = poolSeed
        self.division = division
        self.isConfirmed = isConfirmed
        self.registeredAt = registeredAt
    }
    
    enum CodingKeys: String, CodingKey {
        case id, teamName, player1Id, player2Id, player3Id, player4Id, seed, poolName, poolSeed, division, isConfirmed, registeredAt
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let raw = try? container.decode(String.self, forKey: .id) {
            id = UUID(uuidString: raw) ?? SetGame.parseUUID(from: raw) ?? UUID()
        } else if let uuid = try? container.decode(UUID.self, forKey: .id) {
            id = uuid
        } else {
            id = UUID()
        }
        
        teamName = (try? container.decode(String.self, forKey: .teamName)) ?? "Team"
        
        if let p1Raw = try? container.decode(String.self, forKey: .player1Id) {
            player1Id = UUID(uuidString: p1Raw) ?? SetGame.parseUUID(from: p1Raw) ?? UUID()
        } else {
            player1Id = (try? container.decode(UUID.self, forKey: .player1Id)) ?? UUID()
        }
        
        if let p2Raw = try? container.decode(String.self, forKey: .player2Id) {
            player2Id = UUID(uuidString: p2Raw) ?? SetGame.parseUUID(from: p2Raw)
        } else {
            player2Id = try? container.decode(UUID.self, forKey: .player2Id)
        }
        
        if let p3Raw = try? container.decode(String.self, forKey: .player3Id) {
            player3Id = UUID(uuidString: p3Raw) ?? SetGame.parseUUID(from: p3Raw)
        } else {
            player3Id = try? container.decode(UUID.self, forKey: .player3Id)
        }
        
        if let p4Raw = try? container.decode(String.self, forKey: .player4Id) {
            player4Id = UUID(uuidString: p4Raw) ?? SetGame.parseUUID(from: p4Raw)
        } else {
            player4Id = try? container.decode(UUID.self, forKey: .player4Id)
        }
        
        seed = try container.decodeIfPresent(Int.self, forKey: .seed)
        poolName = try container.decodeIfPresent(String.self, forKey: .poolName)
        poolSeed = try container.decodeIfPresent(Int.self, forKey: .poolSeed)
        division = try container.decode(TournamentDivisionCategory.self, forKey: .division)
        isConfirmed = try container.decodeIfPresent(Bool.self, forKey: .isConfirmed) ?? true
        registeredAt = try container.decodeIfPresent(Date.self, forKey: .registeredAt) ?? Date()
    }
    
    public var allPlayerIds: [UUID] {
        var list: [UUID] = [player1Id]
        if let p2 = player2Id { list.append(p2) }
        if let p3 = player3Id { list.append(p3) }
        if let p4 = player4Id { list.append(p4) }
        return list
    }
    
    public func containsPlayer(_ playerId: UUID) -> Bool {
        allPlayerIds.contains(playerId)
    }
    
    public static func formatFirstLastInit(from name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        
        if trimmed.contains("/") {
            return trimmed.components(separatedBy: "/")
                .map { formatFirstLastInit(from: $0) }
                .joined(separator: "/")
        }
        
        let parts = trimmed.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        guard parts.count > 1 else { return parts.first ?? "" }
        
        let first = parts[0]
        let last = parts[parts.count - 1]
        
        if last.count == 1 {
            return "\(first) \(last.uppercased())."
        }
        if last.count == 2 && last.hasSuffix(".") {
            return "\(first) \(last.uppercased())"
        }
        
        let initial = String(last.prefix(1)).uppercased()
        return "\(first) \(initial)."
    }

    public func playerNamesDisplay(players: [Player]) -> String {
        let resolvedNames: [String] = allPlayerIds.compactMap { pid in
            if let p = players.first(where: { $0.id == pid }) {
                let pName = p.name.isEmpty ? (p.displayName.isEmpty ? p.nickname : p.displayName) : p.name
                if !pName.isEmpty {
                    return TournamentTeam.formatFirstLastInit(from: pName)
                }
            }
            return nil
        }
        
        if !resolvedNames.isEmpty {
            return resolvedNames.joined(separator: "/")
        }
        
        // Demo team name mapping fallback
        let lower = teamName.lowercased()
        if lower.contains("sandstorm") {
            return "Lauren L./Peter T."
        } else if lower.contains("spike force") {
            return "Alicia M./Emily S."
        } else if lower.contains("net ninjas") {
            return "Billy K./Harshal P."
        } else if lower.contains("ace bandits") {
            return "Lucas V./Chloe B."
        } else if lower.contains("block party") {
            return "Kai R./Taylor J."
        } else if lower.contains("sun spikers") {
            return "Maya L./Carlos G."
        } else if lower.contains("coast crushers") {
            return "Sam R./Jordan H."
        } else if lower.contains("dune diggers") {
            return "Alex M./Chris P."
        }
        
        if teamName.contains("/") {
            return TournamentTeam.formatFirstLastInit(from: teamName)
        }
        if teamName.contains("&") {
            return teamName.components(separatedBy: "&")
                .map { TournamentTeam.formatFirstLastInit(from: $0) }
                .joined(separator: "/")
        }
        
        return teamName
    }
}

public struct PoolTeamStanding: Identifiable, Hashable {
    public var id: UUID { team.id }
    public let team: TournamentTeam
    public let matchesPlayed: Int
    public let wins: Int
    public let losses: Int
    public let pointsFor: Int
    public let pointsAgainst: Int
    public var pointDifferential: Int { pointsFor - pointsAgainst }
    public var winRate: Double {
        matchesPlayed > 0 ? Double(wins) / Double(matchesPlayed) : 0.0
    }
}

public struct TournamentMatch: Identifiable, Codable, Hashable {
    public var id: UUID
    public var roundNumber: Int
    public var matchNumber: Int
    public var division: TournamentDivisionCategory
    public var courtNumber: String
    public var team1Id: UUID?
    public var team2Id: UUID?
    public var team1Score: Int?
    public var team2Score: Int?
    public var winningTeamId: UUID?
    public var isCompleted: Bool
    public var poolName: String?
    public var stage: String // "pool", "quarterfinal", "semifinal", "final", "third_place"
    public var bracketRound: Int?
    public var nextMatchId: UUID?
    public var nextMatchSlot: Int? // 1 or 2
    
    public var status: String {
        if isCompleted { return "completed" }
        if team1Score != nil || team2Score != nil { return "in_progress" }
        return "scheduled"
    }
    
    public init(
        id: UUID = UUID(),
        roundNumber: Int = 1,
        matchNumber: Int = 1,
        division: TournamentDivisionCategory,
        courtNumber: String = "Court #1",
        team1Id: UUID? = nil,
        team2Id: UUID? = nil,
        team1Score: Int? = nil,
        team2Score: Int? = nil,
        winningTeamId: UUID? = nil,
        isCompleted: Bool = false,
        poolName: String? = nil,
        stage: String = "pool",
        bracketRound: Int? = nil,
        nextMatchId: UUID? = nil,
        nextMatchSlot: Int? = nil
    ) {
        self.id = id
        self.roundNumber = roundNumber
        self.matchNumber = matchNumber
        self.division = division
        self.courtNumber = courtNumber
        self.team1Id = team1Id
        self.team2Id = team2Id
        self.team1Score = team1Score
        self.team2Score = team2Score
        self.winningTeamId = winningTeamId
        self.isCompleted = isCompleted
        self.poolName = poolName
        self.stage = stage
        self.bracketRound = bracketRound
        self.nextMatchId = nextMatchId
        self.nextMatchSlot = nextMatchSlot
    }
    
    enum CodingKeys: String, CodingKey {
        case id, roundNumber, matchNumber, division, courtNumber, team1Id, team2Id, team1Score, team2Score, winningTeamId, isCompleted, poolName, stage, bracketRound, nextMatchId, nextMatchSlot
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let raw = try? container.decode(String.self, forKey: .id) {
            id = UUID(uuidString: raw) ?? SetGame.parseUUID(from: raw) ?? UUID()
        } else if let uuid = try? container.decode(UUID.self, forKey: .id) {
            id = uuid
        } else {
            id = UUID()
        }
        
        roundNumber = (try? container.decode(Int.self, forKey: .roundNumber)) ?? 1
        matchNumber = (try? container.decode(Int.self, forKey: .matchNumber)) ?? 1
        division = try container.decode(TournamentDivisionCategory.self, forKey: .division)
        courtNumber = (try? container.decode(String.self, forKey: .courtNumber)) ?? "Court #1"
        
        if let t1Raw = try? container.decode(String.self, forKey: .team1Id) {
            team1Id = UUID(uuidString: t1Raw) ?? SetGame.parseUUID(from: t1Raw)
        } else {
            team1Id = try? container.decode(UUID.self, forKey: .team1Id)
        }
        
        if let t2Raw = try? container.decode(String.self, forKey: .team2Id) {
            team2Id = UUID(uuidString: t2Raw) ?? SetGame.parseUUID(from: t2Raw)
        } else {
            team2Id = try? container.decode(UUID.self, forKey: .team2Id)
        }
        
        team1Score = try? container.decode(Int.self, forKey: .team1Score)
        team2Score = try? container.decode(Int.self, forKey: .team2Score)
        
        if let wRaw = try? container.decode(String.self, forKey: .winningTeamId) {
            winningTeamId = UUID(uuidString: wRaw) ?? SetGame.parseUUID(from: wRaw)
        } else {
            winningTeamId = try? container.decode(UUID.self, forKey: .winningTeamId)
        }
        
        isCompleted = (try? container.decode(Bool.self, forKey: .isCompleted)) ?? false
        poolName = try? container.decode(String.self, forKey: .poolName)
        stage = (try? container.decode(String.self, forKey: .stage)) ?? "pool"
        bracketRound = try? container.decode(Int.self, forKey: .bracketRound)
        
        if let nextRaw = try? container.decode(String.self, forKey: .nextMatchId) {
            nextMatchId = UUID(uuidString: nextRaw) ?? SetGame.parseUUID(from: nextRaw)
        } else {
            nextMatchId = try? container.decode(UUID.self, forKey: .nextMatchId)
        }
        
        nextMatchSlot = try? container.decode(Int.self, forKey: .nextMatchSlot)
    }
}

public struct Tournament: Identifiable, Codable, Hashable {
    public var id: UUID
    public var rawId: String?
    public var title: String
    public var hostPlayerId: UUID?
    public var date: Date
    public var location: String
    public var courts: [String]
    public var allowedDivisions: [TournamentDivisionCategory]
    public var maxTeamsPerDivision: Int
    public var teams: [TournamentTeam]
    public var freeAgents: [TournamentFreeAgent]
    public var matches: [TournamentMatch]
    public var status: String // "registration_open", "in_progress", "completed"
    public var notes: String
    public var createdAt: Date
    public var teamFormat: TournamentTeamFormat
    
    public init(
        id: UUID = UUID(),
        rawId: String? = nil,
        title: String,
        hostPlayerId: UUID? = nil,
        date: Date,
        location: String = "Main Beach",
        courts: [String] = ["Court #1", "Court #2", "Court #3", "Court #4"],
        allowedDivisions: [TournamentDivisionCategory] = TournamentDivisionCategory.allCases,
        maxTeamsPerDivision: Int = 8,
        teams: [TournamentTeam] = [],
        freeAgents: [TournamentFreeAgent] = [],
        matches: [TournamentMatch] = [],
        status: String = "registration_open",
        notes: String = "Standard beach rules. Rally score to 21, switch sides every 7 points.",
        createdAt: Date = Date(),
        teamFormat: TournamentTeamFormat = .doubles2v2
    ) {
        self.id = id
        self.rawId = rawId ?? id.uuidString
        self.title = title
        self.hostPlayerId = hostPlayerId
        self.date = date
        self.location = location
        self.courts = courts
        self.allowedDivisions = allowedDivisions
        self.maxTeamsPerDivision = maxTeamsPerDivision
        self.teams = teams
        self.freeAgents = freeAgents
        self.matches = matches
        self.status = status
        self.notes = notes
        self.createdAt = createdAt
        self.teamFormat = teamFormat
    }
    
    enum CodingKeys: String, CodingKey {
        case id, rawId, title, hostPlayerId, date, location, courts, allowedDivisions, maxTeamsPerDivision, teams, freeAgents, matches, status, notes, createdAt, teamFormat
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let raw = try? container.decode(String.self, forKey: .id) {
            rawId = raw
            id = UUID(uuidString: raw) ?? SetGame.parseUUID(from: raw) ?? UUID()
        } else if let uuid = try? container.decode(UUID.self, forKey: .id) {
            id = uuid
            rawId = uuid.uuidString
        } else {
            id = UUID()
            rawId = id.uuidString
        }
        
        title = (try? container.decode(String.self, forKey: .title)) ?? "Tournament"
        
        if let hRaw = try? container.decode(String.self, forKey: .hostPlayerId) {
            hostPlayerId = UUID(uuidString: hRaw) ?? SetGame.parseUUID(from: hRaw)
        } else {
            hostPlayerId = try? container.decode(UUID.self, forKey: .hostPlayerId)
        }
        
        if let d = try? container.decode(Date.self, forKey: .date) {
            date = d
        } else if let dStr = try? container.decode(String.self, forKey: .date),
                  let parsed = ISO8601DateFormatter().date(from: dStr) {
            date = parsed
        } else {
            date = Date()
        }
        
        location = (try? container.decode(String.self, forKey: .location)) ?? "Main Beach"
        courts = (try? container.decode([String].self, forKey: .courts)) ?? ["Court #1", "Court #2"]
        allowedDivisions = (try? container.decode([TournamentDivisionCategory].self, forKey: .allowedDivisions)) ?? TournamentDivisionCategory.allCases
        maxTeamsPerDivision = (try? container.decode(Int.self, forKey: .maxTeamsPerDivision)) ?? 8
        teams = (try? container.decode([TournamentTeam].self, forKey: .teams)) ?? []
        freeAgents = (try? container.decode([TournamentFreeAgent].self, forKey: .freeAgents)) ?? []
        matches = (try? container.decode([TournamentMatch].self, forKey: .matches)) ?? []
        status = (try? container.decode(String.self, forKey: .status)) ?? "registration_open"
        notes = (try? container.decode(String.self, forKey: .notes)) ?? ""
        
        if let c = try? container.decode(Date.self, forKey: .createdAt) {
            createdAt = c
        } else {
            createdAt = Date()
        }
        
        teamFormat = (try? container.decode(TournamentTeamFormat.self, forKey: .teamFormat)) ?? .doubles2v2
    }
    
    public var teamSize: Int {
        teamFormat.teamSize
    }
    
    public var isQuads: Bool {
        teamFormat == .quads4v4
    }
    
    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d • h:mm a"
        return formatter.string(from: date)
    }
    
    public func teams(for division: TournamentDivisionCategory) -> [TournamentTeam] {
        teams.filter { $0.division == division }
    }
    
    public func freeAgents(for division: TournamentDivisionCategory) -> [TournamentFreeAgent] {
        freeAgents.filter { $0.division == division }
    }
    
    public func matches(for division: TournamentDivisionCategory) -> [TournamentMatch] {
        matches.filter { $0.division == division }
    }
    
    public func isPlayerRegistered(_ playerId: UUID) -> Bool {
        teams.contains { $0.containsPlayer(playerId) } || freeAgents.contains { $0.playerId == playerId }
    }
    
    public func registrationStatus(for division: TournamentDivisionCategory) -> String {
        let count = teams(for: division).count
        if count >= maxTeamsPerDivision {
            return "Full (Waitlist Available)"
        }
        return "\(count)/\(maxTeamsPerDivision) Teams"
    }
    
    public var isRegistrationOpen: Bool {
        status == "registration_open"
    }
    
    public var isInProgress: Bool {
        status == "in_progress"
    }
    
    public var isCompleted: Bool {
        status == "completed"
    }
    
    public func poolNames(for division: TournamentDivisionCategory) -> [String] {
        let divTeams = teams(for: division)
        let names = Set(divTeams.compactMap { $0.poolName })
        return names.sorted()
    }
    
    public func poolMatches(for division: TournamentDivisionCategory, poolName: String? = nil) -> [TournamentMatch] {
        matches(for: division).filter { m in
            m.stage == "pool" && (poolName == nil || m.poolName == poolName)
        }
    }
    
    public func bracketMatches(for division: TournamentDivisionCategory) -> [TournamentMatch] {
        matches(for: division).filter { m in
            m.stage != "pool"
        }
    }
    
    public func poolStandings(for division: TournamentDivisionCategory, poolName: String) -> [PoolTeamStanding] {
        let poolTeams = teams(for: division).filter { $0.poolName == poolName }
        let pMatches = matches(for: division).filter { $0.poolName == poolName && $0.stage == "pool" }
        
        var standings: [PoolTeamStanding] = poolTeams.map { team in
            var mp = 0
            var wins = 0
            var losses = 0
            var pf = 0
            var pa = 0
            
            for m in pMatches where m.isCompleted {
                if m.team1Id == team.id {
                    mp += 1
                    let s1 = m.team1Score ?? 0
                    let s2 = m.team2Score ?? 0
                    pf += s1
                    pa += s2
                    if m.winningTeamId == team.id { wins += 1 } else { losses += 1 }
                } else if m.team2Id == team.id {
                    mp += 1
                    let s1 = m.team1Score ?? 0
                    let s2 = m.team2Score ?? 0
                    pf += s2
                    pa += s1
                    if m.winningTeamId == team.id { wins += 1 } else { losses += 1 }
                }
            }
            
            return PoolTeamStanding(
                team: team,
                matchesPlayed: mp,
                wins: wins,
                losses: losses,
                pointsFor: pf,
                pointsAgainst: pa
            )
        }
        
        standings.sort { a, b in
            if a.wins != b.wins {
                return a.wins > b.wins
            }
            if a.pointDifferential != b.pointDifferential {
                return a.pointDifferential > b.pointDifferential
            }
            return a.pointsFor > b.pointsFor
        }
        
        return standings
    }
}
