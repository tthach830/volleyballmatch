import Foundation

public struct CourtLocations {
    public static let standardCourts = [
        "Main Beach",
        "Dream Inn",
        "Harbor",
        "4th Street",
        "Capitola Beach",
        "Seabright Beach",
        "Manhattan Beach Pier",
        "Hermosa Beach",
        "Huntington Beach"
    ]
    
    public static let customOption = "+ Custom Court Name..."
    
    public static var allOptions: [String] {
        standardCourts + [customOption]
    }
}
