import SwiftUI

public struct RatingBadge: View {
    public let rating: RatingTier
    public var size: BadgeSize = .regular
    
    public enum BadgeSize {
        case small, regular, large
        
        var font: Font {
            switch self {
            case .small: return .system(size: 11, weight: .bold)
            case .regular: return .system(size: 13, weight: .bold)
            case .large: return .system(size: 16, weight: .heavy)
            }
        }
        
        var paddingV: CGFloat {
            switch self {
            case .small: return 3
            case .regular: return 5
            case .large: return 8
            }
        }
        
        var paddingH: CGFloat {
            switch self {
            case .small: return 6
            case .regular: return 10
            case .large: return 14
            }
        }
    }
    
    public init(rating: RatingTier, size: BadgeSize = .regular) {
        self.rating = rating
        self.size = size
    }
    
    public var body: some View {
        HStack(spacing: 4) {
            Image(systemName: rating.iconName)
                .font(size.font)
            Text(rating.rawValue)
                .font(size.font)
        }
        .padding(.vertical, size.paddingV)
        .padding(.horizontal, size.paddingH)
        .background(rating.badgeColor.opacity(0.18))
        .foregroundColor(rating.badgeColor)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(rating.badgeColor.opacity(0.4), lineWidth: 1)
        )
    }
}
