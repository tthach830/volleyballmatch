import Foundation

public struct AvailabilitySlot: Identifiable, Codable, Hashable {
    public var id: UUID
    public var playerId: UUID
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
        playerId: UUID,
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
        self.playerId = playerId
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
}
