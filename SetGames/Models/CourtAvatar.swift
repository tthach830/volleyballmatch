import Foundation

public struct CourtAvatar: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let emoji: String
    
    public init(id: String, name: String, emoji: String) {
        self.id = id
        self.name = name
        self.emoji = emoji
    }
    
    public static let availableAvatars: [CourtAvatar] = [
        CourtAvatar(id: "slug", name: "Banana Slug", emoji: "slug"),
        CourtAvatar(id: "derp_ball", name: "Derp Volleyball", emoji: "derp_ball"),
        CourtAvatar(id: "lobster", name: "Lobster", emoji: "lobster"),
        CourtAvatar(id: "sunburn", name: "Sunburn", emoji: "sunburn"),
        CourtAvatar(id: "net_stuck", name: "Net Stuck", emoji: "net_stuck"),
        CourtAvatar(id: "seagull", name: "Seagull", emoji: "seagull"),
        CourtAvatar(id: "sand_face", name: "Sand Face", emoji: "sand_face"),
        CourtAvatar(id: "wilson", name: "Wilson", emoji: "wilson"),
        CourtAvatar(id: "otter", name: "Otter", emoji: "otter"),
        CourtAvatar(id: "eagle", name: "Eagle", emoji: "eagle"),
        CourtAvatar(id: "lion", name: "Lion", emoji: "lion"),
        CourtAvatar(id: "cross", name: "Cross", emoji: "✝️"),
        CourtAvatar(id: "ichthys", name: "Christian Fish", emoji: "ichthys"),
        CourtAvatar(id: "mustang", name: "Wild Horse", emoji: "🐎"),
        CourtAvatar(id: "shark", name: "Shark", emoji: "🦈"),
        CourtAvatar(id: "orca", name: "Orca", emoji: "🐋"),
        CourtAvatar(id: "ball", name: "Volleyball", emoji: "🏐"),
        CourtAvatar(id: "surfer", name: "Surfer", emoji: "🏄‍♂️"),
        CourtAvatar(id: "beach", name: "Beach", emoji: "🏖️"),
        CourtAvatar(id: "palm", name: "Palm Tree", emoji: "🌴")
    ]
}
