import Foundation

public enum NotificationType: String, Codable {
    case matchConfirmed = "Match Confirmed"
    case matchInvite = "Match Update"
    case matchChat = "Match Chat"
    case scoreLogged = "Score Logged"
    case queueUpdate = "Queue Update"
    case ladderRankChange = "Ladder Update"
    case communityBadge = "Popular Kids Badge"
    
    public var icon: String {
        switch self {
        case .matchConfirmed: return "volleyball.fill"
        case .matchInvite: return "bell.badge.fill"
        case .matchChat: return "bubble.left.and.bubble.right.fill"
        case .scoreLogged: return "trophy.fill"
        case .queueUpdate: return "bolt.fill"
        case .ladderRankChange: return "chart.line.uptrend.xyaxis"
        case .communityBadge: return "crown.fill"
        }
    }
}

public struct AppNotification: Identifiable, Codable, Hashable {
    public var id: UUID = UUID()
    public var title: String
    public var message: String
    public var type: NotificationType
    public var date: Date
    public var isRead: Bool
    public var relatedGameId: UUID?
    
    public init(
        id: UUID = UUID(),
        title: String,
        message: String,
        type: NotificationType,
        date: Date = Date(),
        isRead: Bool = false,
        relatedGameId: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.type = type
        self.date = date
        self.isRead = isRead
        self.relatedGameId = relatedGameId
    }
    
    public var timeAgoFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
