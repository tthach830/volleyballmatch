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

// MARK: - Seagull Fry Avatar View
public struct SeagullFryAvatarView: View {
    public var size: CGFloat
    public init(size: CGFloat) { self.size = size }
    
    public var body: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.88, green: 0.95, blue: 1.0))
                .frame(width: size, height: size)
            
            // Seagull Body & Head
            Circle()
                .fill(Color.white)
                .frame(width: size * 0.62, height: size * 0.62)
                .overlay(Circle().stroke(Color(white: 0.85), lineWidth: 1))
                .offset(x: -size * 0.08, y: size * 0.08)
            
            // French Fry in Beak
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(red: 0.99, green: 0.78, blue: 0.15))
                .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color(red: 0.85, green: 0.55, blue: 0.05), lineWidth: 0.8))
                .frame(width: size * 0.48, height: size * 0.12)
                .rotationEffect(.degrees(-8))
                .offset(x: size * 0.16, y: size * 0.04)
            
            // Beak
            Path { path in
                path.move(to: CGPoint(x: size * 0.45, y: size * 0.42))
                path.addLine(to: CGPoint(x: size * 0.92, y: size * 0.52))
                path.addLine(to: CGPoint(x: size * 0.45, y: size * 0.64))
                path.closeSubpath()
            }
            .fill(Color(red: 0.98, green: 0.75, blue: 0.10))
            
            // Red dot on beak
            Circle()
                .fill(Color.red)
                .frame(width: size * 0.08, height: size * 0.08)
                .offset(x: size * 0.32, y: size * 0.06)
            
            // Wide Eye
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: size * 0.32, height: size * 0.32)
                    .overlay(Circle().stroke(Color.black, lineWidth: 1.5))
                Circle()
                    .fill(Color.black)
                    .frame(width: size * 0.16, height: size * 0.16)
                Circle()
                    .fill(Color.white)
                    .frame(width: size * 0.06, height: size * 0.06)
                    .offset(x: -size * 0.03, y: -size * 0.03)
            }
            .offset(x: -size * 0.10, y: -size * 0.10)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

// MARK: - Sunburned Tourist Avatar View
public struct SunburnedTouristAvatarView: View {
    public var size: CGFloat
    public init(size: CGFloat) { self.size = size }
    
    public var body: some View {
        ZStack {
            // Yellow background
            Circle()
                .fill(Color(red: 1.0, green: 0.94, blue: 0.55))
                .frame(width: size, height: size)
            
            // Lobster red face
            Circle()
                .fill(Color(red: 0.94, green: 0.27, blue: 0.27))
                .frame(width: size * 0.82, height: size * 0.82)
            
            // Neon Green Sunglasses Frame
            RoundedRectangle(cornerRadius: size * 0.08)
                .fill(Color(red: 0.13, green: 0.77, blue: 0.37))
                .frame(width: size * 0.70, height: size * 0.24)
                .offset(y: -size * 0.12)
            
            // Lenses
            HStack(spacing: size * 0.08) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.black)
                    .frame(width: size * 0.24, height: size * 0.16)
                    .overlay(
                        Capsule()
                            .fill(Color.cyan)
                            .frame(width: size * 0.12, height: 1.5)
                            .rotationEffect(.degrees(-35))
                    )
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.black)
                    .frame(width: size * 0.24, height: size * 0.16)
                    .overlay(
                        Capsule()
                            .fill(Color.cyan)
                            .frame(width: size * 0.12, height: 1.5)
                            .rotationEffect(.degrees(-35))
                    )
            }
            .offset(y: -size * 0.12)
            
            // White Zinc Cream on Nose
            Path { path in
                path.move(to: CGPoint(x: size * 0.5, y: size * 0.44))
                path.addLine(to: CGPoint(x: size * 0.42, y: size * 0.65))
                path.addLine(to: CGPoint(x: size * 0.58, y: size * 0.65))
                path.closeSubpath()
            }
            .fill(Color.white)
            
            // Wide goofy smile
            Path { path in
                path.addArc(center: CGPoint(x: size * 0.5, y: size * 0.70), radius: size * 0.16, startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
            }
            .fill(Color(red: 0.45, green: 0.05, blue: 0.05))
            
            // Teeth
            Capsule()
                .fill(Color.white)
                .frame(width: size * 0.22, height: size * 0.06)
                .offset(y: size * 0.21)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

// MARK: - Dramatic Sand Crab Avatar View
public struct DramaticSandCrabAvatarView: View {
    public var size: CGFloat
    public init(size: CGFloat) { self.size = size }
    
    public var body: some View {
        ZStack {
            // Sand background
            Circle()
                .fill(Color(red: 1.0, green: 0.84, blue: 0.67))
                .frame(width: size, height: size)
            
            // Volleyball overhead
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: size * 0.38, height: size * 0.38)
                    .overlay(Circle().stroke(Color.black, lineWidth: 1))
                
                Circle()
                    .stroke(Color.blue, lineWidth: 1.2)
                    .frame(width: size * 0.24, height: size * 0.36)
                
                Circle()
                    .stroke(Color.yellow, lineWidth: 1.2)
                    .frame(width: size * 0.36, height: size * 0.24)
            }
            .offset(y: -size * 0.25)
            
            // Raised Pincers
            HStack(spacing: size * 0.34) {
                Text("🦀")
                    .font(.system(size: size * 0.30))
                    .rotationEffect(.degrees(45))
                Text("🦀")
                    .font(.system(size: size * 0.30))
                    .rotationEffect(.degrees(-45))
                    .scaleEffect(x: -1, y: 1)
            }
            .offset(y: -size * 0.08)
            
            // Crab Body
            Ellipse()
                .fill(Color.orange)
                .frame(width: size * 0.56, height: size * 0.36)
                .overlay(Ellipse().stroke(Color(red: 0.78, green: 0.28, blue: 0.05), lineWidth: 1.5))
                .offset(y: size * 0.20)
            
            // Fierce Eyestalks
            HStack(spacing: size * 0.18) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: size * 0.15, height: size * 0.15)
                        .overlay(Circle().stroke(Color.black, lineWidth: 1))
                    Circle()
                        .fill(Color.black)
                        .frame(width: size * 0.07, height: size * 0.07)
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: size * 0.16, height: 1.8)
                        .rotationEffect(.degrees(25))
                        .offset(y: -size * 0.06)
                }
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: size * 0.15, height: size * 0.15)
                        .overlay(Circle().stroke(Color.black, lineWidth: 1))
                    Circle()
                        .fill(Color.black)
                        .frame(width: size * 0.07, height: size * 0.07)
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: size * 0.16, height: 1.8)
                        .rotationEffect(.degrees(-25))
                        .offset(y: -size * 0.06)
                }
            }
            .offset(y: -size * 0.02)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

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
    
    public var isMustang: Bool {
        avatarKey == "mustang" || avatarKey == "horse" || avatarKey == "🐎"
    }
    
    public var isIchthys: Bool {
        avatarKey == "ichthys" || avatarKey == "fish_symbol" || avatarKey == "christian_fish" || avatarKey.lowercased().contains("ichthys")
    }
    
    public var isCross: Bool {
        avatarKey == "cross" || avatarKey == "✝️" || avatarKey == "✝"
    }
    
    public var isSeagullFry: Bool {
        avatarKey == "seagull-fry" || avatarKey == "seagull_fry" || avatarKey.contains("seagull")
    }
    
    public var isSunburnedTourist: Bool {
        avatarKey == "sunburned-tourist" || avatarKey == "sunburned_tourist" || avatarKey.contains("sunburned")
    }
    
    public var isDramaticSandCrab: Bool {
        avatarKey == "dramatic-sand-crab" || avatarKey == "dramatic_sand_crab" || avatarKey.contains("sand-crab") || avatarKey.contains("sand_crab")
    }
    
    public var body: some View {
        if isBananaSlug {
            Image("BananaSlugAvatar")
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
        } else if isSeagullFry {
            SeagullFryAvatarView(size: size)
        } else if isSunburnedTourist {
            SunburnedTouristAvatarView(size: size)
        } else if isDramaticSandCrab {
            DramaticSandCrabAvatarView(size: size)
        } else {
            Text(avatarKey)
                .font(.system(size: size * 0.82))
        }
    }
}
