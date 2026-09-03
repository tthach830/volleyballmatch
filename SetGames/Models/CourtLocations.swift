import Foundation

public struct CourtLocations {
    public static let standardCourts = [
        "Main Beach",
        "Harbor",
        "4th Street",
        "Manhattan Beach Pier",
        "Hermosa Beach",
        "Huntington Beach"
    ]
    
    public static let customOption = "+ Custom Court Name..."
    
    public static var allOptions: [String] {
        standardCourts + [customOption]
    }
}
