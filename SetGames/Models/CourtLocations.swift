import Foundation

public struct CourtLocations {
    public static let standardCourts = [
        "Main Beach",
        "Harbor",
        "Capitola Jetty & Beach",
        "4th Street",
        "Manhattan Beach Pier",
        "Hermosa Beach",
        "Huntington Beach"
    ]
    
    public static let customOption = "+ Custom Court Name..."
    
    public static var allOptions: [String] {
        standardCourts + [customOption]
    }
    
    public static func webcamURL(for court: String) -> URL? {
        let clean = court.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if clean.contains("capitola") {
            return URL(string: "https://www.cityofcapitola.gov/851/Beach-Web-Cam")
        }
        return nil
    }
}
