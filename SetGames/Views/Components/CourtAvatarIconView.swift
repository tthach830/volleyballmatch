import SwiftUI

public struct IchthysFishShape: Shape {
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        // Upper arc from nose (left) to lower tail fin
        path.move(to: CGPoint(x: w * 0.08, y: h * 0.5))
        path.addCurve(
            to: CGPoint(x: w * 0.92, y: h * 0.72),
            control1: CGPoint(x: w * 0.30, y: h * 0.16),
            control2: CGPoint(x: w * 0.68, y: h * 0.25)
        )
        
        // Lower arc from nose (left) to upper tail fin
        path.move(to: CGPoint(x: w * 0.08, y: h * 0.5))
        path.addCurve(
            to: CGPoint(x: w * 0.92, y: h * 0.28),
            control1: CGPoint(x: w * 0.30, y: h * 0.84),
            control2: CGPoint(x: w * 0.68, y: h * 0.75)
        )
        
        // Eye
        let eyeRect = CGRect(x: w * 0.25, y: h * 0.44, width: w * 0.09, height: h * 0.09)
        path.addEllipse(in: eyeRect)
        
        return path
    }
}

public struct CourtAvatarIconView: View {
    public let avatarKey: String
    public var size: CGFloat
    
    public init(avatarKey: String, size: CGFloat = 32) {
        self.avatarKey = avatarKey
        self.size = size
    }
    
    public var customImageName: String? {
        if avatarKey == "slug" || avatarKey == "🍌" || avatarKey == "BananaSlugAvatar" || avatarKey.lowercased().contains("slug") {
            return "BananaSlugAvatar"
        }
        if avatarKey == "derp_ball" || avatarKey == "avatar_derp_ball" {
            return "AvatarDerpBall"
        }
        if avatarKey == "lobster" || avatarKey == "avatar_lobster" {
            return "AvatarLobster"
        }
        if avatarKey == "sunburn" || avatarKey == "avatar_sunburn" {
            return "AvatarSunburn"
        }
        if avatarKey == "net_stuck" || avatarKey == "avatar_net_stuck" {
            return "AvatarNetStuck"
        }
        if avatarKey == "seagull" || avatarKey == "avatar_seagull" {
            return "AvatarSeagull"
        }
        if avatarKey == "sand_face" || avatarKey == "avatar_sand_face" {
            return "AvatarSandFace"
        }
        if avatarKey == "wilson" || avatarKey == "avatar_wilson" {
            return "AvatarWilson"
        }
        return nil
    }
    
    public var isMustang: Bool {
        avatarKey == "mustang" || avatarKey == "horse" || avatarKey == "🐎"
    }
    
    public var isIchthys: Bool {
        avatarKey == "ichthys" || avatarKey == "fish_symbol" || avatarKey == "christian_fish" || avatarKey.lowercased().contains("ichthys")
    }
    
    public var isCross: Bool {
        avatarKey == "cross" || avatarKey == "✝️" || avatarKey == "✝"
    }
    
    public var body: some View {
        if let imageName = customImageName {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else if isMustang {
            Text("🐎")
                .font(.system(size: size * 0.82))
        } else if isIchthys {
            IchthysFishShape()
                .stroke(Color.primary, style: StrokeStyle(lineWidth: max(1.5, size * 0.07), lineCap: .round, lineJoin: .round))
                .frame(width: size * 0.82, height: size * 0.82)
        } else if isCross {
            Text("✝️")
                .font(.system(size: size * 0.82))
        } else {
            Text(avatarKey)
                .font(.system(size: size * 0.82))
        }
    }
}
