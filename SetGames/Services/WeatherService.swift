import Foundation
import SwiftUI
import Combine

public struct BeachWeatherForecast: Identifiable, Codable, Hashable {
    public var id: String { "\(courtLocation)_\(dateSlot)" }
    public let courtLocation: String
    public let dateSlot: String
    public let tempF: Int
    public let uvIndex: Double
    public let windMph: Int
    public let conditionEmoji: String
    public let conditionText: String
    
    public init(
        courtLocation: String,
        dateSlot: String,
        tempF: Int,
        uvIndex: Double,
        windMph: Int,
        conditionEmoji: String,
        conditionText: String
    ) {
        self.courtLocation = courtLocation
        self.dateSlot = dateSlot
        self.tempF = tempF
        self.uvIndex = uvIndex
        self.windMph = windMph
        self.conditionEmoji = conditionEmoji
        self.conditionText = conditionText
    }
    
    public var uvCategory: String {
        switch uvIndex {
        case ..<3.0: return "Low"
        case ..<6.0: return "Moderate"
        case ..<8.0: return "High"
        case ..<11.0: return "Very High"
        default: return "Extreme"
        }
    }
    
    public var uvColor: Color {
        switch uvIndex {
        case ..<3.0: return .green
        case ..<6.0: return Color(red: 0.95, green: 0.7, blue: 0.1) // Amber/Yellow
        case ..<8.0: return .orange
        case ..<11.0: return .red
        default: return .purple
        }
    }
    
    public var uvSunscreenAdvice: String {
        switch uvIndex {
        case ..<3.0: return "Minimal sun protection needed."
        case ..<6.0: return "Apply SPF 30+ sunscreen and wear sunglasses."
        case ..<8.0: return "Generous SPF 50+, hat & sunglasses strongly recommended."
        default: return "Extreme exposure: seek shade between sets and reapply SPF often."
        }
    }
    
    public var windDirection: String {
        "NW"
    }
    
    public var windCategory: String {
        switch windMph {
        case ..<6: return "Calm"
        case ..<12: return "Breezy"
        case ..<18: return "Windy"
        default: return "High Wind"
        }
    }
    
    public var windAdvice: String {
        switch windMph {
        case ..<6:
            return "Ideal beach conditions • Crisp sets and consistent float serves."
        case ..<12:
            return "Gentle ocean breeze • Mild ball drift; favor tighter setting."
        case ..<18:
            return "Noticeable wind • Ball floats quickly; adjust approach and deep passes."
        default:
            return "High coastal gusts • Tough passing; keep sets low and aggressive."
        }
    }
    
    public var compactSummary: String {
        "\(tempF)°F • UV \(Int(uvIndex.rounded())) (\(uvCategory)) • 💨 \(windMph) mph (\(windCategory))"
    }
}

@MainActor
public class WeatherService: ObservableObject {
    public static let shared = WeatherService()
    
    @Published public private(set) var cache: [String: BeachWeatherForecast] = [:]
    private var inFlightTasks: [String: Task<BeachWeatherForecast?, Never>] = [:]
    
    private init() {}
    
    // Coordinates for known courts/beaches
    public static func coordinates(for court: String) -> (lat: Double, lon: Double) {
        let clean = court.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        if clean.contains("harbor") {
            return (36.9631, -122.0016) // Santa Cruz Harbor Beach
        } else if clean.contains("4th") || clean.contains("seabright") {
            return (36.9650, -122.0100) // 4th Ave / Seabright Beach
        } else if clean.contains("manhattan") {
            return (33.8837, -118.4116) // Manhattan Beach Pier
        } else if clean.contains("hermosa") {
            return (33.8617, -118.4011) // Hermosa Beach
        } else if clean.contains("huntington") {
            return (33.6595, -117.9988) // Huntington Beach
        } else {
            // Default: Main Beach, Santa Cruz
            return (36.9638, -122.0179)
        }
    }
    
    private func cacheKey(court: String, date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH"
        formatter.timeZone = TimeZone(identifier: "America/Los_Angeles") ?? .current
        let dateKey = formatter.string(from: date)
        let cleanCourt = court.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return "\(cleanCourt)_\(dateKey)"
    }
    
    public func cachedForecast(for court: String, on date: Date) -> BeachWeatherForecast? {
        let key = cacheKey(court: court, date: date)
        return cache[key]
    }
    
    @discardableResult
    public func loadForecast(for court: String, on date: Date) -> BeachWeatherForecast? {
        let key = cacheKey(court: court, date: date)
        if let existing = cache[key] {
            return existing
        }
        
        // If already fetching, return nil for now until published
        if inFlightTasks[key] != nil {
            return nil
        }
        
        let task = Task { [weak self] () -> BeachWeatherForecast? in
            guard let self = self else { return nil }
            let forecast = await self.fetchForecast(for: court, on: date)
            await MainActor.run {
                if let forecast = forecast {
                    self.cache[key] = forecast
                }
                self.inFlightTasks.removeValue(forKey: key)
            }
            return forecast
        }
        inFlightTasks[key] = task
        return nil
    }
    
    public func fetchForecast(for court: String, on date: Date) async -> BeachWeatherForecast? {
        let coords = Self.coordinates(for: court)
        let baseParams = "latitude=\(coords.lat)&longitude=\(coords.lon)&hourly=temperature_2m,uv_index,wind_speed_10m,wind_gusts_10m,weather_code&temperature_unit=fahrenheit&wind_speed_unit=mph&timezone=auto&past_days=7&forecast_days=14"
        // Use NOAA National Blend of Models (NBM) — more accurate for US coastal locations
        let nbmURLString = "https://api.open-meteo.com/v1/forecast?\(baseParams)&models=ncep_nbm_conus"
        let defaultURLString = "https://api.open-meteo.com/v1/forecast?\(baseParams)"
        
        for urlString in [nbmURLString, defaultURLString] {
            guard let url = URL(string: urlString) else { continue }
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { continue }
                let decoded = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
                return parseClosestHour(from: decoded, court: court, targetDate: date)
            } catch {
                continue
            }
        }
        return fallbackForecast(for: court, on: date)
    }
    
    private func parseClosestHour(from response: OpenMeteoResponse, court: String, targetDate: Date) -> BeachWeatherForecast {
        let times = response.hourly.time
        guard !times.isEmpty else {
            return fallbackForecast(for: court, on: targetDate)
        }
        
        // Match format "2026-09-06T10:00"
        let isoFormatter = DateFormatter()
        isoFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        isoFormatter.timeZone = TimeZone(identifier: "America/Los_Angeles") ?? .current
        
        var bestIdx = 0
        var minDiff: TimeInterval = .infinity
        
        for (i, tStr) in times.enumerated() {
            if let d = isoFormatter.date(from: tStr) {
                let diff = abs(d.timeIntervalSince(targetDate))
                if diff < minDiff {
                    minDiff = diff
                    bestIdx = i
                }
            }
        }
        
        let temp = (bestIdx < response.hourly.temperature_2m.count) ? Int(response.hourly.temperature_2m[bestIdx].rounded()) : 72
        let uv = (bestIdx < response.hourly.uv_index.count) ? response.hourly.uv_index[bestIdx] : 5.0
        let wind = (bestIdx < response.hourly.wind_speed_10m.count) ? Int(response.hourly.wind_speed_10m[bestIdx].rounded()) : 8
        let code = (bestIdx < response.hourly.weather_code.count) ? response.hourly.weather_code[bestIdx] : 0
        
        let (emoji, text) = weatherCodeInterpretation(code)
        
        return BeachWeatherForecast(
            courtLocation: court,
            dateSlot: times[bestIdx],
            tempF: temp,
            uvIndex: uv,
            windMph: wind,
            conditionEmoji: emoji,
            conditionText: text
        )
    }
    
    private func fallbackForecast(for court: String, on date: Date) -> BeachWeatherForecast {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        
        // Reasonable daylight coastal beach volleyball averages
        let temp: Int
        let uv: Double
        let wind: Int
        
        if hour < 11 {
            temp = 65
            uv = 3.5
            wind = 5
        } else if hour < 16 {
            temp = 73
            uv = 7.0
            wind = 9
        } else {
            temp = 68
            uv = 2.0
            wind = 8
        }
        
        return BeachWeatherForecast(
            courtLocation: court,
            dateSlot: "avg",
            tempF: temp,
            uvIndex: uv,
            windMph: wind,
            conditionEmoji: "☀️",
            conditionText: "Seasonal Average"
        )
    }
    
    private func weatherCodeInterpretation(_ code: Int) -> (String, String) {
        switch code {
        case 0:
            return ("☀️", "Sunny")
        case 1, 2:
            return ("🌤️", "Mostly Sunny")
        case 3:
            return ("☁️", "Overcast")
        case 45, 48:
            return ("🌫️", "Foggy")
        case 51...55:
            return ("🌦️", "Light Drizzle")
        case 61...65:
            return ("🌧️", "Rain")
        case 80...82:
            return ("🌧️", "Rain Showers")
        case 95...99:
            return ("⛈️", "Thunderstorm")
        default:
            return ("☀️", "Clear")
        }
    }
}

// MARK: - Open-Meteo Decodable Schema
fileprivate struct OpenMeteoResponse: Decodable {
    let hourly: OpenMeteoHourly
}

fileprivate struct OpenMeteoHourly: Decodable {
    let time: [String]
    let temperature_2m: [Double]
    let uv_index: [Double]
    let wind_speed_10m: [Double]
    let weather_code: [Int]
}
