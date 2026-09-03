import SwiftUI

public struct CourtAvatarIconView: View {
    public let avatarKey: String
    public var size: CGFloat
    
    public init(avatarKey: String, size: CGFloat = 32) {
        self.avatarKey = avatarKey
        self.size = size
    }
    
    public var isBananaSlug: Bool {
        avatarKey == "slug" || avatarKey == "🍌" || avatarKey == "BananaSlugAvatar" || avatarKey.lowercased().contains("slug")
    }
    
    public var body: some View {
        if isBananaSlug {
            Image("BananaSlugAvatar")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else {
            Text(avatarKey)
                .font(.system(size: size * 0.82))
        }
    }
}
