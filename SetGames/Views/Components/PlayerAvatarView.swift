import SwiftUI

public struct PlayerAvatarView: View {
    public let player: Player
    public var dimension: CGFloat = 44
    public var showBadge: Bool = true
    
    public init(player: Player, dimension: CGFloat = 44, showBadge: Bool = true) {
        self.player = player
        self.dimension = dimension
        self.showBadge = showBadge
    }
    
    public var body: some View {
        VStack(spacing: 2) {
            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [player.rating.badgeColor.opacity(0.25), player.rating.badgeColor.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: dimension, height: dimension)
                        .overlay(
                            Circle()
                                .stroke(player.isFlaker ? Color.red : player.rating.badgeColor.opacity(0.6), lineWidth: player.isFlaker ? 2 : 1.5)
                        )
                    
                    CourtAvatarIconView(avatarKey: player.avatarEmoji, size: dimension * 0.78)
                }
                
                if showBadge {
                    Text(player.rating.shortCode)
                        .font(.system(size: max(8, dimension * 0.22), weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1.5)
                        .background(player.rating.badgeColor)
                        .clipShape(Capsule())
                        .offset(x: 4, y: 2)
                }
            }
            
            if player.isFlaker {
                Text("F")
                    .font(.system(size: max(8, dimension * 0.22), weight: .black))
                    .foregroundColor(.white)
                    .frame(width: max(13, dimension * 0.3), height: max(13, dimension * 0.3))
                    .background(Color.red)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.2), radius: 1)
            }
        }
    }
}
