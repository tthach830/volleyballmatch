import Foundation

public struct AvailabilitySlot: Identifiable, Codable, Hashable {
    public var id: UUID
    public var rawId: String?
    public var playerId: UUID
    public var rawPlayerId: String?
    public var date: Date
    public var startTime: Date
    public var endTime: Date
    public var preferredBeach: String
    public var acceptedTiers: [RatingTier]
    public var allowPlusMinusOneTier: Bool
    public var isRecurringWeekly: Bool
    public var isMatched: Bool
    
    public init(
        id: UUID = UUID(),
        rawId: String? = nil,
        playerId: UUID,
        rawPlayerId: String? = nil,
        date: Date = Date(),
        startTime: Date,
        endTime: Date,
        preferredBeach: String = "South Beach Courts",
        acceptedTiers: [RatingTier] = [.intermediate, .b, .a],
        allowPlusMinusOneTier: Bool = true,
        isRecurringWeekly: Bool = false,
        isMatched: Bool = false
    ) {
        self.id = id
        self.rawId = rawId ?? id.uuidString
        self.playerId = playerId
        self.rawPlayerId = rawPlayerId ?? playerId.uuidString
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.preferredBeach = preferredBeach
        self.acceptedTiers = acceptedTiers
        self.allowPlusMinusOneTier = allowPlusMinusOneTier
        self.isRecurringWeekly = isRecurringWeekly
        self.isMatched = isMatched
    }
    
    public var timeRangeFormatted: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: startTime)) – \(formatter.string(from: endTime))"
    }
    
    public var dayFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }
    
    /// Checks if this availability overlaps with another slot by at least 60 minutes
    public func overlaps(with other: AvailabilitySlot, minimumMinutes: Int = 60) -> Bool {
        // Must be on the same calendar day (or matching recurring day of week)
        let cal = Calendar.current
        let sameDay = cal.isDate(self.date, inSameDayAs: other.date)
        guard sameDay else { return false }
        
        // Check time interval overlap
        let startMax = max(self.startTime.timeIntervalSince1970, other.startTime.timeIntervalSince1970)
        let endMin = min(self.endTime.timeIntervalSince1970, other.endTime.timeIntervalSince1970)
        let overlapDurationSeconds = endMin - startMax
        return overlapDurationSeconds >= Double(minimumMinutes * 60)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, rawId, playerId, rawPlayerId, date, startTime, endTime
        case preferredBeach, acceptedTiers, allowPlusMinusOneTier, isRecurringWeekly, isMatched
    }
    
    private static func parseTime(from string: String, on baseDate: Date) -> Date? {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = iso.date(from: string) { return d }
        iso.formatOptions = [.withInternetDateTime]
        if let d = iso.date(from: string) { return d }
        
        let timeFormats = ["HH:mm", "H:mm", "h:mm a", "hh:mm a", "h:mma", "HH:mm:ss", "yyyy-MM-dd'T'HH:mm:ssZ"]
        for fmt in timeFormats {
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.dateFormat = fmt
            if let parsed = df.date(from: string) {
                let cal = Calendar.current
                let comps = cal.dateComponents([.hour, .minute], from: parsed)
                if let hour = comps.hour, let min = comps.minute {
                    if let merged = cal.date(bySettingHour: hour, minute: min, second: 0, of: baseDate) {
                        return merged
                    }
                }
                return parsed
            }
        }
        return nil
    }
    
    private static func parseDate(from string: String) -> Date? {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = iso.date(from: string) { return d }
        iso.formatOptions = [.withInternetDateTime]
        if let d = iso.date(from: string) { return d }
        
        let dateFormats = ["yyyy-MM-dd", "yyyy/MM/dd", "MM/dd/yyyy", "MMM d, yyyy"]
        for fmt in dateFormats {
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.dateFormat = fmt
            if let d = df.date(from: string) { return d }
        }
        return nil
    }
    
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        
        // 1. ID
        if let raw = try? c.decode(String.self, forKey: .id) {
            rawId = raw
            id = UUID(uuidString: raw) ?? SetGame.parseUUID(from: raw) ?? UUID()
        } else if let uuid = try? c.decode(UUID.self, forKey: .id) {
            id = uuid
            rawId = uuid.uuidString
        } else {
            id = UUID()
            rawId = id.uuidString
        }
        
        // 2. Player ID
        if let raw = try? c.decode(String.self, forKey: .playerId) {
            rawPlayerId = raw
            playerId = UUID(uuidString: raw) ?? SetGame.parseUUID(from: raw) ?? UUID()
        } else if let uuid = try? c.decode(UUID.self, forKey: .playerId) {
            playerId = uuid
            rawPlayerId = uuid.uuidString
        } else {
            playerId = UUID()
            rawPlayerId = nil
        }
        
        // 3. Date
        if let d = try? c.decode(Date.self, forKey: .date) {
            date = d
        } else if let dStr = try? c.decode(String.self, forKey: .date) {
            date = Self.parseDate(from: dStr) ?? Date()
        } else if let ts = try? c.decode(Double.self, forKey: .date) {
            if ts > 10_000_000_000 {
                date = Date(timeIntervalSince1970: ts / 1000)
            } else if ts > 500_000_000 && ts < 1_500_000_000 {
                date = Date(timeIntervalSinceReferenceDate: ts)
            } else {
                date = Date(timeIntervalSince1970: ts)
            }
        } else {
            date = Date()
        }
        
        // 4. Start Time
        if let st = try? c.decode(Date.self, forKey: .startTime) {
            startTime = st
        } else if let stStr = try? c.decode(String.self, forKey: .startTime) {
            startTime = Self.parseTime(from: stStr, on: date) ?? date
        } else if let ts = try? c.decode(Double.self, forKey: .startTime) {
            if ts > 10_000_000_000 {
                startTime = Date(timeIntervalSince1970: ts / 1000)
            } else if ts > 500_000_000 && ts < 1_500_000_000 {
                startTime = Date(timeIntervalSinceReferenceDate: ts)
            } else {
                startTime = Date(timeIntervalSince1970: ts)
            }
        } else {
            startTime = date
        }
        
        // 5. End Time
        if let et = try? c.decode(Date.self, forKey: .endTime) {
            endTime = et
        } else if let etStr = try? c.decode(String.self, forKey: .endTime) {
            endTime = Self.parseTime(from: etStr, on: date) ?? date.addingTimeInterval(7200)
        } else if let ts = try? c.decode(Double.self, forKey: .endTime) {
            if ts > 10_000_000_000 {
                endTime = Date(timeIntervalSince1970: ts / 1000)
            } else if ts > 500_000_000 && ts < 1_500_000_000 {
                endTime = Date(timeIntervalSinceReferenceDate: ts)
            } else {
                endTime = Date(timeIntervalSince1970: ts)
            }
        } else {
            endTime = date.addingTimeInterval(7200)
        }
        
        // 6. Preferred Beach
        preferredBeach = (try? c.decode(String.self, forKey: .preferredBeach)) ?? "Main Beach"
        
        // 7. Accepted Tiers
        if let tiers = try? c.decode([RatingTier].self, forKey: .acceptedTiers) {
            acceptedTiers = tiers
        } else if let tierStrs = try? c.decode([String].self, forKey: .acceptedTiers) {
            let parsed = tierStrs.compactMap { str -> RatingTier? in
                switch str.lowercased() {
                case "novice", "nov": return .novice
                case "intermediate", "int": return .intermediate
                case "b": return .b
                case "a": return .a
                case "aa": return .aa
                case "open": return .open
                default: return RatingTier(rawValue: str)
                }
            }
            acceptedTiers = parsed.isEmpty ? [.intermediate, .b, .a] : parsed
        } else {
            acceptedTiers = [.intermediate, .b, .a]
        }
        
        // 8. Booleans
        allowPlusMinusOneTier = (try? c.decode(Bool.self, forKey: .allowPlusMinusOneTier)) ?? true
        isRecurringWeekly = (try? c.decode(Bool.self, forKey: .isRecurringWeekly)) ?? false
        isMatched = (try? c.decode(Bool.self, forKey: .isMatched)) ?? false
    }
    
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        let slotId = rawId ?? id.uuidString
        try c.encode(slotId, forKey: .id)
        if let raw = rawId {
            try c.encode(raw, forKey: .rawId)
        }
        let pId = rawPlayerId ?? playerId.uuidString
        try c.encode(pId, forKey: .playerId)
        if let rawPlayer = rawPlayerId {
            try c.encode(rawPlayer, forKey: .rawPlayerId)
        }
        
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        try c.encode(iso.string(from: date), forKey: .date)
        try c.encode(iso.string(from: startTime), forKey: .startTime)
        try c.encode(iso.string(from: endTime), forKey: .endTime)
        
        try c.encode(preferredBeach, forKey: .preferredBeach)
        try c.encode(acceptedTiers.map { $0.rawValue }, forKey: .acceptedTiers)
        try c.encode(allowPlusMinusOneTier, forKey: .allowPlusMinusOneTier)
        try c.encode(isRecurringWeekly, forKey: .isRecurringWeekly)
        try c.encode(isMatched, forKey: .isMatched)
    }
}
