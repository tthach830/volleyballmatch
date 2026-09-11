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
        CourtAvatar(id: "seagull-fry", name: "Seagull Fry", emoji: "seagull-fry"),
        CourtAvatar(id: "sunburned-tourist", name: "Sunburned Tourist", emoji: "sunburned-tourist"),
        CourtAvatar(id: "dramatic-sand-crab", name: "Dramatic Sand Crab", emoji: "dramatic-sand-crab"),
        CourtAvatar(id: "cross", name: "Cross", emoji: "✝️"),
        CourtAvatar(id: "ichthys", name: "Christian Fish", emoji: "ichthys"),
        CourtAvatar(id: "mustang", name: "Wild Horse", emoji: "🐎"),
        CourtAvatar(id: "shark", name: "Shark", emoji: "🦈"),
        CourtAvatar(id: "otter", name: "Otter", emoji: "🦦"),
        CourtAvatar(id: "orca", name: "Orca", emoji: "🐋"),
        CourtAvatar(id: "ball", name: "Volleyball", emoji: "🏐"),
        CourtAvatar(id: "surfer", name: "Surfer", emoji: "🏄‍♂️"),
        CourtAvatar(id: "beach", name: "Beach", emoji: "🏖️"),
        CourtAvatar(id: "palm", name: "Palm Tree", emoji: "🌴")
    ]
}
