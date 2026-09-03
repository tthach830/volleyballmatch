import SwiftUI

public enum RatingTier: String, CaseIterable, Codable, Identifiable {
    case novice = "Novice"
    case intermediate = "Intermediate"
    case b = "B"
    case a = "A"
    case aa = "AA"
    case open = "Open"
    
    public var id: String { rawValue }
    
    public var shortCode: String {
        switch self {
        case .novice: return "NOV"
        case .intermediate: return "INT"
        case .b: return "B"
        case .a: return "A"
        case .aa: return "AA"
        case .open: return "OPEN"
        }
    }
    
    public var levelScore: Int {
        switch self {
        case .novice: return 1
        case .intermediate: return 2
        case .b: return 3
        case .a: return 4
        case .aa: return 5
        case .open: return 6
        }
    }
    
    public var badgeColor: Color {
        switch self {
        case .novice: return Color(red: 0.1, green: 0.7, blue: 0.6)
        case .intermediate: return Color(red: 0.1, green: 0.5, blue: 0.9)
        case .b: return Color(red: 0.4, green: 0.3, blue: 0.9)
        case .a: return Color(red: 0.95, green: 0.55, blue: 0.1)
        case .aa: return Color(red: 0.9, green: 0.25, blue: 0.3)
        case .open: return Color(red: 0.85, green: 0.65, blue: 0.1)
        }
    }
    
    public var iconName: String {
        switch self {
        case .novice: return "leaf.fill"
        case .intermediate: return "figure.volleyball"
        case .b: return "flame.fill"
        case .a: return "bolt.fill"
        case .aa: return "star.fill"
        case .open: return "crown.fill"
        }
    }
    
    public var description: String {
        switch self {
        case .novice:
            return "Learning the sand fundamentals. Basic bump/overhead passes, casual rallying."
        case .intermediate:
            return "Consistent 3-touch play (bump, set, hit). Understands wind, sand movement, and court boundaries."
        case .b:
            return "Competitive recreational player. Controlled platform sets, directional serves, and active transition defense."
        case .a:
            return "Advanced beach player. Hand-setting proficiency, jump serves, cut shots, reading hitters, and disciplined blocking."
        case .aa:
            return "Tournament finalist / Semi-Pro level. Hard-driven ball defense, explosive sand vertical, high volleyball IQ, and elite consistency."
        case .open:
            return "Open / Professional tour level player with national or international competition experience."
        }
    }
    
    public func isCompatible(with other: RatingTier, tolerance: Int = 1) -> Bool {
        abs(self.levelScore - other.levelScore) <= tolerance
    }
}
