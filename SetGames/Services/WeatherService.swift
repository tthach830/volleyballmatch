import Foundation
import SwiftUI
import Combine

// MARK: - Daily Volleyball Weather & Criteria
public enum VolleyballSuitability: String, Codable {
    case good
    case fair
    case poor
    
    public var dotColor: Color {
        switch self {
        case .good: return .green
        case .fair: return .yellow
        case .poor: return .red
        }
    }
    
    public var title: String {
        switch self {
        case .good: return "Good"
        case .fair: return "Fair"
        case .poor: return "Poor"
        }
    }
}

public struct VolleyballCriteria: Codable, Equatable {
    public var minTemp: Int = 60
    public var maxTemp: Int = 80
    public var maxWind: Int = 10
    public var maxUV: Double = 4.0
    
    public static let `default` = VolleyballCriteria(minTemp: 60, maxTemp: 80, maxWind: 10, maxUV: 4.0)
    
    public func evaluate(day: DailyVolleyballWeather) -> (suitability: VolleyballSuitability, reason: String, tip: String) {
        var issues: [String] = []
        var warnings: [String] = []
        
        // Wind speed check
        if day.windMax > maxWind + 3 {
            issues.append("Too windy (\(day.windMax) mph)")
        } else if day.windMax > maxWind {
            warnings.append("Breezy (\(day.windMax) mph)")
        }
        
        // Temperature check
        if day.tempMax > maxTemp {
            issues.append("Too hot (\(day.tempMax)°F)")
        } else if day.tempAvg < minTemp - 6 {
            issues.append("Too cold (\(day.tempAvg)°F)")
        } else if day.tempAvg < minTemp {
            warnings.append("Chilly (\(day.tempAvg)°F)")
        }
        
        // UV Index check
        if day.uvMax > maxUV + 2.5 {
            warnings.append("High UV (\(String(format: "%.1f", day.uvMax)))")
        } else if day.uvMax > maxUV {
            warnings.append("Elevated UV (\(String(format: "%.1f", day.uvMax)))")
        }
        
        let textLower = day.conditionText.lowercased()
        if textLower.contains("rain") || textLower.contains("storm") || textLower.contains("drizzle") {
            issues.append("Rain: \(day.conditionText)")
        }
        
        if !issues.isEmpty {
            let reason = issues.joined(separator: " • ")
            let tip: String
            if issues.contains(where: { $0.lowercased().contains("wind") }) {
                tip = "High coastal wind: Keep sets low and passes tight to the net."
            } else if issues.contains(where: { $0.lowercased().contains("hot") }) {
                tip = "Hot sand alert: Sand socks and heavy hydration required."
            } else if issues.contains(where: { $0.lowercased().contains("rain") }) {
                tip = "Wet sand & slick balls: Indoor play recommended."
            } else {
                tip = "Chilly morning: Layer up with windbreaker & thermal gear."
            }
            return (.poor, reason, tip)
        } else if !warnings.isEmpty {
            let reason = warnings.joined(separator: " • ")
            let tip = warnings.contains(where: { $0.lowercased().contains("breezy") })
                ? "Moderate ocean breeze: Slight ball drift on deep float serves."
                : "Moderate sun exposure: SPF 30+ sunscreen & sunglasses recommended."
            return (.fair, reason, tip)
        } else {
            return (.good, "Good for Volleyball", "Prime beach conditions: Low wind drift, comfortable temp, crisp sets.")
        }
    }
}

public struct DailyVolleyballWeather: Identifiable, Codable, Hashable {
    public var id: String { "\(courtLocation)_\(dateStr)" }
    public let courtLocation: String
    public let dateIndex: Int
    public let dateStr: String
    public let dayName: String
    public let dateFormatted: String
    public let fullDayTitle: String
    public let tempMax: Int
    public let tempMin: Int
    public let tempAvg: Int
    public let windMax: Int
    public let uvMax: Double
    public let conditionEmoji: String
    public let conditionText: String
    
    public init(
        courtLocation: String,
        dateIndex: Int,
        dateStr: String,
        dayName: String,
        dateFormatted: String,
        fullDayTitle: String,
        tempMax: Int,
        tempMin: Int,
        tempAvg: Int,
        windMax: Int,
        uvMax: Double,
        conditionEmoji: String,
        conditionText: String
    ) {
        self.courtLocation = courtLocation
        self.dateIndex = dateIndex
        self.dateStr = dateStr
        self.dayName = dayName
        self.dateFormatted = dateFormatted
        self.fullDayTitle = fullDayTitle
        self.tempMax = tempMax
        self.tempMin = tempMin
        self.tempAvg = tempAvg
        self.windMax = windMax
        self.uvMax = uvMax
        self.conditionEmoji = conditionEmoji
        self.conditionText = conditionText
    }
}

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
    @Published public private(set) var weeklyCache: [String: [DailyVolleyballWeather]] = [:]
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
    
    public func fetchWeeklyForecast(for court: String) async -> [DailyVolleyballWeather] {
        let cleanCourt = court.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let cached = weeklyCache[cleanCourt] {
            return cached
        }
        
        let coords = Self.coordinates(for: court)
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(coords.lat)&longitude=\(coords.lon)&daily=weather_code,temperature_2m_max,temperature_2m_min,uv_index_max,wind_speed_10m_max&hourly=temperature_2m,uv_index,wind_speed_10m,weather_code&temperature_unit=fahrenheit&wind_speed_unit=mph&timezone=auto&forecast_days=7"
        
        guard let url = URL(string: urlString) else {
            return fallbackWeeklyForecast(for: court)
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return fallbackWeeklyForecast(for: court)
            }
            let decoded = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
            let days = parseWeeklyForecast(from: decoded, court: court)
            weeklyCache[cleanCourt] = days
            return days
        } catch {
            return fallbackWeeklyForecast(for: court)
        }
    }
    
    private func parseWeeklyForecast(from response: OpenMeteoResponse, court: String) -> [DailyVolleyballWeather] {
        guard let daily = response.daily, let times = daily.time, !times.isEmpty else {
            return fallbackWeeklyForecast(for: court)
        }
        
        var days: [DailyVolleyballWeather] = []
        let isoFormatter = DateFormatter()
        isoFormatter.dateFormat = "yyyy-MM-dd"
        isoFormatter.timeZone = TimeZone(identifier: "America/Los_Angeles") ?? .current
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MMM d"
        displayFormatter.timeZone = TimeZone(identifier: "America/Los_Angeles") ?? .current
        
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.dateFormat = "EEE"
        weekdayFormatter.timeZone = TimeZone(identifier: "America/Los_Angeles") ?? .current
        
        let fullFormatter = DateFormatter()
        fullFormatter.dateFormat = "EEEE, MMM d"
        fullFormatter.timeZone = TimeZone(identifier: "America/Los_Angeles") ?? .current
        
        for (i, dateStr) in times.prefix(7).enumerated() {
            let d = isoFormatter.date(from: dateStr) ?? Date()
            let dayName: String
            if i == 0 { dayName = "Today" }
            else if i == 1 { dayName = "Tomorrow" }
            else { dayName = weekdayFormatter.string(from: d) }
            
            let dateFormatted = displayFormatter.string(from: d)
            let fullTitle = fullFormatter.string(from: d)
            
            let tMax = (i < (daily.temperature_2m_max?.count ?? 0)) ? Int(daily.temperature_2m_max![i].rounded()) : 74
            let tMin = (i < (daily.temperature_2m_min?.count ?? 0)) ? Int(daily.temperature_2m_min![i].rounded()) : 56
            let tAvg = (tMax + tMin) / 2
            let wMax = (i < (daily.wind_speed_10m_max?.count ?? 0)) ? Int(daily.wind_speed_10m_max![i].rounded()) : 8
            let uvMax = (i < (daily.uv_index_max?.count ?? 0)) ? daily.uv_index_max![i] : 4.0
            let code = (i < (daily.weather_code?.count ?? 0)) ? daily.weather_code![i] : 0
            let (emoji, text) = weatherCodeInterpretation(code)
            
            days.append(DailyVolleyballWeather(
                courtLocation: court,
                dateIndex: i,
                dateStr: dateStr,
                dayName: dayName,
                dateFormatted: dateFormatted,
                fullDayTitle: fullTitle,
                tempMax: tMax,
                tempMin: tMin,
                tempAvg: tAvg,
                windMax: wMax,
                uvMax: uvMax,
                conditionEmoji: emoji,
                conditionText: text
            ))
        }
        
        return days.isEmpty ? fallbackWeeklyForecast(for: court) : days
    }
    
    private func fallbackWeeklyForecast(for court: String) -> [DailyVolleyballWeather] {
        var days: [DailyVolleyballWeather] = []
        let baseTemps = [72, 70, 75, 78, 82, 69, 71]
        let baseWinds = [7, 9, 8, 12, 16, 6, 8]
        let baseUVs = [3.8, 4.2, 3.5, 4.8, 5.2, 3.2, 3.9]
        let emojis = ["☀️", "🌤️", "☀️", "🌤️", "💨", "☀️", "🌤️"]
        let texts = ["Sunny", "Mostly Sunny", "Clear", "Partly Cloudy", "Breezy & Sunny", "Clear", "Sunny"]
        
        let calendar = Calendar.current
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.dateFormat = "EEE"
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MMM d"
        let fullFormatter = DateFormatter()
        fullFormatter.dateFormat = "EEEE, MMM d"
        
        for i in 0..<7 {
            let d = calendar.date(byAdding: .day, value: i, to: Date()) ?? Date()
            let dayName = i == 0 ? "Today" : (i == 1 ? "Tomorrow" : weekdayFormatter.string(from: d))
            let dateFormatted = displayFormatter.string(from: d)
            let fullTitle = fullFormatter.string(from: d)
            let tMax = baseTemps[i]
            let tMin = tMax - 16
            
            days.append(DailyVolleyballWeather(
                courtLocation: court,
                dateIndex: i,
                dateStr: "day-\(i)",
                dayName: dayName,
                dateFormatted: dateFormatted,
                fullDayTitle: fullTitle,
                tempMax: tMax,
                tempMin: tMin,
                tempAvg: (tMax + tMin) / 2,
                windMax: baseWinds[i],
                uvMax: baseUVs[i],
                conditionEmoji: emojis[i],
                conditionText: texts[i]
            ))
        }
        return days
    }
    
    private func parseClosestHour(from response: OpenMeteoResponse, court: String, targetDate: Date) -> BeachWeatherForecast {
        guard let hourly = response.hourly else {
            return fallbackForecast(for: court, on: targetDate)
        }
        let times = hourly.time
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
        
        let temp = (bestIdx < hourly.temperature_2m.count) ? Int(hourly.temperature_2m[bestIdx].rounded()) : 72
        let uv = (bestIdx < hourly.uv_index.count) ? hourly.uv_index[bestIdx] : 5.0
        let wind = (bestIdx < hourly.wind_speed_10m.count) ? Int(hourly.wind_speed_10m[bestIdx].rounded()) : 8
        let code = (bestIdx < hourly.weather_code.count) ? hourly.weather_code[bestIdx] : 0
        
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
    let hourly: OpenMeteoHourly?
    let daily: OpenMeteoDaily?
}

fileprivate struct OpenMeteoDaily: Decodable {
    let time: [String]?
    let weather_code: [Int]?
    let temperature_2m_max: [Double]?
    let temperature_2m_min: [Double]?
    let uv_index_max: [Double]?
    let wind_speed_10m_max: [Double]?
}

fileprivate struct OpenMeteoHourly: Decodable {
    let time: [String]
    let temperature_2m: [Double]
    let uv_index: [Double]
    let wind_speed_10m: [Double]
    let weather_code: [Int]
}
