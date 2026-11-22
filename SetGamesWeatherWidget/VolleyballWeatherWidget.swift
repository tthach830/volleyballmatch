import WidgetKit
import SwiftUI

public struct BeachSpotSnapshot: Codable, Hashable {
    public let name: String
    public let shortName: String
    public let tempF: Int
    public let windMph: Int
    public let uvIndex: Int
    public let conditionEmoji: String
    public let conditionText: String
    
    public var verdictText: String {
        if windMph > 15 || tempF < 54 {
            return "Windy"
        } else if windMph > 10 || tempF < 60 {
            return "Breezy"
        } else {
            return "Optimal"
        }
    }
    
    public var verdictColor: Color {
        if windMph > 15 || tempF < 54 {
            return .red
        } else if windMph > 10 || tempF < 60 {
            return .yellow
        } else {
            return .green
        }
    }
}

public struct VolleyballWeatherEntry: TimelineEntry {
    public let date: Date
    public let primaryBeach: BeachSpotSnapshot
    public let allBeaches: [BeachSpotSnapshot]
    public let bestWindowText: String
}

public struct VolleyballWeatherProvider: TimelineProvider {
    private static let defaultBeaches: [BeachSpotSnapshot] = [
        BeachSpotSnapshot(name: "Harbor Beach", shortName: "Harbor", tempF: 69, windMph: 7, uvIndex: 5, conditionEmoji: "☀️", conditionText: "Sunny"),
        BeachSpotSnapshot(name: "Main Beach", shortName: "Main Beach", tempF: 68, windMph: 8, uvIndex: 5, conditionEmoji: "🌤️", conditionText: "Mostly Clear"),
        BeachSpotSnapshot(name: "Dream Inn", shortName: "Dream Inn", tempF: 67, windMph: 7, uvIndex: 5, conditionEmoji: "☀️", conditionText: "Sunny")
    ]
    
    public func placeholder(in context: Context) -> VolleyballWeatherEntry {
        VolleyballWeatherEntry(
            date: Date(),
            primaryBeach: Self.defaultBeaches[0],
            allBeaches: Self.defaultBeaches,
            bestWindowText: "Best Play: 10 AM – 3 PM (Light Wind)"
        )
    }
    
    public func getSnapshot(in context: Context, completion: @escaping (VolleyballWeatherEntry) -> Void) {
        completion(placeholder(in: context))
    }
    
    public func getTimeline(in context: Context, completion: @escaping (Timeline<VolleyballWeatherEntry>) -> Void) {
        Task {
            let snapshots = await fetchAllBeaches()
            let primary = snapshots.first ?? Self.defaultBeaches[0]
            let advice: String
            if primary.windMph <= 10 {
                advice = "Clean setting & passing conditions at \(primary.shortName)"
            } else if primary.windMph <= 15 {
                advice = "Moderate breeze — set tighter to the net"
            } else {
                advice = "High wind alert — pass low & firm"
            }
            let entry = VolleyballWeatherEntry(
                date: Date(),
                primaryBeach: primary,
                allBeaches: snapshots,
                bestWindowText: advice
            )
            let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
            completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
        }
    }
    
    private func fetchAllBeaches() async -> [BeachSpotSnapshot] {
        let coords: [(name: String, shortName: String, lat: Double, lon: Double, fallback: BeachSpotSnapshot)] = [
            ("Harbor Beach", "Harbor", 36.9628, -122.0019, Self.defaultBeaches[0]),
            ("Main Beach", "Main Beach", 36.9641, -122.0177, Self.defaultBeaches[1]),
            ("Dream Inn", "Dream Inn", 36.9619, -122.0242, Self.defaultBeaches[2])
        ]
        
        var results: [BeachSpotSnapshot] = []
        for spot in coords {
            if let live = await fetchSpot(name: spot.name, shortName: spot.shortName, lat: spot.lat, lon: spot.lon) {
                results.append(live)
            } else {
                results.append(spot.fallback)
            }
        }
        return results
    }
    
    private struct OpenMeteoCurrentResponse: Decodable {
        struct Current: Decodable {
            let temperature_2m: Double?
            let wind_speed_10m: Double?
            let weather_code: Int?
        }
        struct Hourly: Decodable {
            let uv_index: [Double]?
        }
        let current: Current?
        let hourly: Hourly?
    }
    
    private func fetchSpot(name: String, shortName: String, lat: Double, lon: Double) async -> BeachSpotSnapshot? {
        let urlStr = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current=temperature_2m,weather_code,wind_speed_10m&hourly=uv_index&temperature_unit=fahrenheit&wind_speed_unit=mph&timezone=America%2FLos_Angeles&forecast_days=1"
        guard let url = URL(string: urlStr) else { return nil }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            let decoded = try JSONDecoder().decode(OpenMeteoCurrentResponse.self, from: data)
            let temp = Int((decoded.current?.temperature_2m ?? 68.0).rounded())
            let wind = Int((decoded.current?.wind_speed_10m ?? 7.0).rounded())
            let code = decoded.current?.weather_code ?? 0
            let hourIdx = Calendar.current.component(.hour, from: Date())
            let uvVal: Int
            if let uvs = decoded.hourly?.uv_index, uvs.indices.contains(hourIdx) {
                uvVal = Int(uvs[hourIdx].rounded())
            } else {
                uvVal = 5
            }
            let (emoji, text) = mapWeatherCode(code)
            return BeachSpotSnapshot(
                name: name,
                shortName: shortName,
                tempF: temp,
                windMph: wind,
                uvIndex: uvVal,
                conditionEmoji: emoji,
                conditionText: text
            )
        } catch {
            return nil
        }
    }
    
    private func mapWeatherCode(_ code: Int) -> (String, String) {
        switch code {
        case 0: return ("☀️", "Clear Sky")
        case 1: return ("🌤️", "Mainly Clear")
        case 2: return ("⛅", "Partly Cloudy")
        case 3: return ("☁️", "Overcast")
        case 45, 48: return ("🌫️", "Coastal Fog")
        case 51, 53, 55, 61, 63, 65: return ("🌧️", "Rain")
        default: return ("🌤️", "Clear")
        }
    }
}

public struct VolleyballWeatherWidgetEntryView: View {
    var entry: VolleyballWeatherProvider.Entry
    @Environment(\.widgetFamily) var family
    
    public var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        case .accessoryRectangular:
            lockScreenView
        default:
            smallView
        }
    }
    
    private var smallView: some View {
        let b = entry.primaryBeach
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("🏐 \(b.shortName)")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Spacer()
                Circle()
                    .fill(b.verdictColor)
                    .frame(width: 8, height: 8)
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(b.conditionEmoji)
                    .font(.system(size: 20))
                Text("\(b.tempF)°F")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            }
            
            Text(b.verdictText + " Play")
                .font(.system(size: 11, weight: .black))
                .foregroundColor(b.verdictColor)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(Capsule().fill(b.verdictColor.opacity(0.2)))
            
            Spacer(minLength: 2)
            
            HStack(spacing: 8) {
                Text("💨 \(b.windMph) mph")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.cyan)
                Text("☀️ UV \(b.uvIndex)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.orange)
            }
        }
        .padding(12)
        .widgetURL(URL(string: "setgames://weather?beach=Harbor%20Beach"))
    }
    
    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 5) {
                    Text("🏐")
                        .font(.system(size: 13))
                    Text("SANTA CRUZ BEACH VOLLEYBALL WEATHER")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.cyan)
                }
                Spacer()
                Text(entry.primaryBeach.verdictText.uppercased())
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(entry.primaryBeach.verdictColor)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(entry.primaryBeach.verdictColor.opacity(0.2)))
            }
            
            HStack(spacing: 8) {
                ForEach(entry.allBeaches, id: \.name) { spot in
                    Link(destination: URL(string: "setgames://weather?beach=\(spot.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Harbor%20Beach")")!) {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(spot.verdictColor)
                                    .frame(width: 6, height: 6)
                                Text(spot.shortName)
                                    .font(.system(size: 11, weight: .heavy))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                            }
                            HStack(spacing: 3) {
                                Text(spot.conditionEmoji)
                                    .font(.system(size: 12))
                                Text("\(spot.tempF)°F")
                                    .font(.system(size: 15, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            Text("💨 \(spot.windMph) mph • UV \(spot.uvIndex)")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.cyan)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(10)
                    }
                }
            }
            
            Text("💨 \(entry.bestWindowText)")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white.opacity(0.75))
                .lineLimit(1)
        }
        .padding(12)
        .widgetURL(URL(string: "setgames://weather?beach=Harbor%20Beach"))
    }
    
    private var lockScreenView: some View {
        let b = entry.primaryBeach
        return VStack(alignment: .leading, spacing: 2) {
            Text("🏐 \(b.name) • \(b.verdictText)")
                .font(.system(size: 12, weight: .heavy))
            Text("\(b.conditionEmoji) \(b.tempF)°F • 💨 \(b.windMph) mph • UV \(b.uvIndex)")
                .font(.system(size: 11, weight: .semibold))
        }
        .widgetURL(URL(string: "setgames://weather?beach=Harbor%20Beach"))
    }
}

@main
public struct VolleyballWeatherWidget: Widget {
    public let kind: String = "VolleyballWeatherWidget"
    
    public init() {}
    
    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VolleyballWeatherProvider()) { entry in
            if #available(iOS 17.0, *) {
                VolleyballWeatherWidgetEntryView(entry: entry)
                    .containerBackground(for: .widget) {
                        LinearGradient(
                            colors: [Color(red: 0.09, green: 0.14, blue: 0.22), Color(red: 0.06, green: 0.08, blue: 0.13)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
            } else {
                VolleyballWeatherWidgetEntryView(entry: entry)
                    .background(Color(red: 0.08, green: 0.10, blue: 0.15))
            }
        }
        .configurationDisplayName("Volleyball? Beach Weather")
        .description("Live beach volleyball temperature, wind speed, UV index, and playability for Harbor Beach, Main Beach, and Dream Inn.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
        .contentMarginsDisabled()
    }
}
