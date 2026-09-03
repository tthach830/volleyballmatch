import SwiftUI

public enum MatchmakingType: String, CaseIterable, Identifiable {
    case smartAvailability = "Smart Window"
    case instantQueue = "Fast Lobby"
    case kingOfTheBeach = "King/Queen"
    case openBoard = "Court Auto-Fill"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .smartAvailability: return "calendar.badge.clock"
        case .instantQueue: return "bolt.horizontal.circle.fill"
        case .kingOfTheBeach: return "crown.fill"
        case .openBoard: return "sparkles.rectangle.stack.fill"
        }
    }
    
    public var title: String {
        switch self {
        case .smartAvailability: return "Smart Availability Matcher"
        case .instantQueue: return "Instant Pickup Lobby"
        case .kingOfTheBeach: return "King of the Beach (Solo Queue)"
        case .openBoard: return "Open Court Compatibility Fill"
        }
    }
    
    public var subtitle: String {
        switch self {
        case .smartAvailability:
            return "Set recurring or upcoming free windows. The engine pairs 4 players of compatible tier and auto-confirms the match."
        case .instantQueue:
            return "Drop into today's live morning or sunset waves. Fills 4-player lobbies and alerts you once full."
        case .kingOfTheBeach:
            return "No partner required! 4 players rotate partners across 3 sets. Individual win/loss record tracked."
        case .openBoard:
            return "Matches you with existing games missing 1 player based on 0-100% skill & schedule compatibility."
        }
    }
    
    public var tag: String {
        switch self {
        case .smartAvailability: return "RECOMMENDED"
        case .instantQueue: return "FASTEST"
        case .kingOfTheBeach: return "ROTATING 2V2"
        case .openBoard: return "DYNAMIC"
        }
    }
    
    public var themeColor: Color {
        switch self {
        case .smartAvailability: return Color.orange
        case .instantQueue: return Color.blue
        case .kingOfTheBeach: return Color.purple
        case .openBoard: return Color.teal
        }
    }
}
