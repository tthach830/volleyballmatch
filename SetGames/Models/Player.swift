import Foundation

public struct Player: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var nickname: String
    public var avatarEmoji: String
    public var rating: RatingTier
    public var eloRating: Int
    public var homeBeach: String
    public var wins: Int
    public var losses: Int
    public var streak: Int
    public var pointsScored: Int
    public var pointsAllowed: Int
    public var uniquePartnerIds: [UUID]
    public var uniqueOpponentIds: [UUID]
    public var recentForm: [Bool] // true = Win, false = Loss
    public var bio: String
    public var phoneNumber: String
    public var password: String
    public var starRatingSum: Int
    public var starRatingCount: Int
    public var consecutiveBackouts: Int
    
    public var isFlaker: Bool {
        consecutiveBackouts >= 3
    }
    
    public var isRoot: Bool {
        let cleaned = phoneNumber.filter { $0.isNumber }
        return cleaned == "4087869405" || id.uuidString.uppercased() == "47519EF2-207D-4C20-B9A6-BFEDA40FE581"
    }
    
    public init(
        id: UUID = UUID(),
        name: String,
        nickname: String = "",
        avatarEmoji: String = "🍌",
        rating: RatingTier,
        eloRating: Int = 1500,
        homeBeach: String = "Main Beach",
        phoneNumber: String = "",
        password: String = "",
        starRatingSum: Int = 0,
        starRatingCount: Int = 0,
        consecutiveBackouts: Int = 0,
        wins: Int = 0,
        losses: Int = 0,
        streak: Int = 0,
        pointsScored: Int = 0,
        pointsAllowed: Int = 0,
        uniquePartnerIds: [UUID] = [],
        uniqueOpponentIds: [UUID] = [],
        recentForm: [Bool] = [],
        bio: String = "Beach volleyball enthusiast!"
    ) {
        self.id = id
        self.name = name
        self.nickname = nickname.isEmpty ? name.components(separatedBy: " ").first ?? name : nickname
        self.avatarEmoji = avatarEmoji
        self.rating = rating
        self.eloRating = eloRating
        self.homeBeach = homeBeach
        self.phoneNumber = phoneNumber
        self.password = password
        self.starRatingSum = starRatingSum
        self.starRatingCount = starRatingCount
        self.wins = wins
        self.losses = losses
        self.streak = streak
        self.pointsScored = pointsScored
        self.pointsAllowed = pointsAllowed
        self.consecutiveBackouts = consecutiveBackouts
        self.uniquePartnerIds = uniquePartnerIds
        self.uniqueOpponentIds = uniqueOpponentIds
        self.recentForm = recentForm
        self.bio = bio
    }
    
    public var totalMatches: Int {
        wins + losses
    }
    
    public var winRate: Double {
        guard totalMatches > 0 else { return 0.0 }
        return (Double(wins) / Double(totalMatches)) * 100.0
    }
    
    public var winRateFormatted: String {
        guard totalMatches > 0 else { return "0%" }
        return String(format: "%.1f%%", winRate)
    }
    
    public var pointDifferential: Int {
        pointsScored - pointsAllowed
    }
    
    /// Unique network size ("The Popular Kids" metric)
    public var uniqueConnectionsCount: Int {
        var all = Set(uniquePartnerIds)
        all.formUnion(uniqueOpponentIds)
        return all.count
    }
    
    public var popularKidsTitle: String {
        switch uniqueConnectionsCount {
        case 30...: return "👑 Beach Mayor"
        case 20..<30: return "🌟 Social Catalyst"
        case 12..<20: return "🤝 Community Wingman"
        case 5..<12: return "🏖️ Active Regular"
        default: return "🌱 New on Court"
        }
    }
    
    public var formattedRecord: String {
        "\(wins)W - \(losses)L"
    }
    
    public var streakFormatted: String {
        if streak > 0 {
            return "🔥 \(streak)W"
        } else if streak < 0 {
            return "❄️ \(abs(streak))L"
        } else {
            return "–"
        }
    }
    
    public var averageStarRating: Double {
        let base = starRatingCount > 0 ? (Double(starRatingSum) / Double(starRatingCount)) : 5.0
        let penalty = isFlaker ? 1.0 : 0.0
        return max(1.0, base - penalty)
    }
    
    public var formattedStarRating: String {
        String(format: "%.1f", averageStarRating)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, nickname, avatarEmoji, rating, eloRating, homeBeach, phoneNumber, password
        case wins, losses, streak, pointsScored, pointsAllowed, uniquePartnerIds, uniqueOpponentIds, recentForm, bio
        case starRatingSum, starRatingCount, consecutiveBackouts
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let uuid = try? c.decode(UUID.self, forKey: .id) {
            id = uuid
        } else if let idStr = try? c.decode(String.self, forKey: .id) {
            id = SetGame.parseUUID(from: idStr) ?? UUID()
        } else {
            id = UUID()
        }
        
        name = (try? c.decode(String.self, forKey: .name)) ?? "Beach Player"
        nickname = (try? c.decode(String.self, forKey: .nickname)) ?? ""
        avatarEmoji = (try? c.decode(String.self, forKey: .avatarEmoji)) ?? "slug"
        
        if let r = try? c.decode(RatingTier.self, forKey: .rating) {
            rating = r
        } else if let rStr = try? c.decode(String.self, forKey: .rating) {
            switch rStr.lowercased() {
            case "novice", "nov": rating = .novice
            case "intermediate", "int": rating = .intermediate
            case "b": rating = .b
            case "a": rating = .a
            case "aa": rating = .aa
            case "open": rating = .open
            default: rating = .b
            }
        } else {
            rating = .b
        }
        
        eloRating = (try? c.decode(Int.self, forKey: .eloRating)) ?? 1500
        homeBeach = (try? c.decode(String.self, forKey: .homeBeach)) ?? "Main Beach"
        phoneNumber = (try? c.decode(String.self, forKey: .phoneNumber)) ?? ""
        password = (try? c.decode(String.self, forKey: .password)) ?? ""
        starRatingSum = (try? c.decode(Int.self, forKey: .starRatingSum)) ?? 0
        starRatingCount = (try? c.decode(Int.self, forKey: .starRatingCount)) ?? 0
        consecutiveBackouts = (try? c.decode(Int.self, forKey: .consecutiveBackouts)) ?? 0
        wins = (try? c.decode(Int.self, forKey: .wins)) ?? 0
        losses = (try? c.decode(Int.self, forKey: .losses)) ?? 0
        streak = (try? c.decode(Int.self, forKey: .streak)) ?? 0
        pointsScored = (try? c.decode(Int.self, forKey: .pointsScored)) ?? 0
        pointsAllowed = (try? c.decode(Int.self, forKey: .pointsAllowed)) ?? 0
        
        if let partners = try? c.decode([UUID].self, forKey: .uniquePartnerIds) {
            uniquePartnerIds = partners
        } else if let pStrs = try? c.decode([String].self, forKey: .uniquePartnerIds) {
            uniquePartnerIds = pStrs.compactMap { SetGame.parseUUID(from: $0) }
        } else {
            uniquePartnerIds = []
        }
        
        if let opponents = try? c.decode([UUID].self, forKey: .uniqueOpponentIds) {
            uniqueOpponentIds = opponents
        } else if let oStrs = try? c.decode([String].self, forKey: .uniqueOpponentIds) {
            uniqueOpponentIds = oStrs.compactMap { SetGame.parseUUID(from: $0) }
        } else {
            uniqueOpponentIds = []
        }
        
        recentForm = (try? c.decode([Bool].self, forKey: .recentForm)) ?? []
        bio = (try? c.decode(String.self, forKey: .bio)) ?? "Beach volleyball enthusiast!"
    }
}
