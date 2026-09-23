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
    
    public func evaluate(hour: HourlyVolleyballWeather) -> (suitability: VolleyballSuitability, label: String, tip: String) {
        var issues: [String] = []
        var warnings: [String] = []
        
        // Wind speed check
        if hour.windMph > maxWind + 3 {
            issues.append("Too windy (\(hour.windMph) mph)")
        } else if hour.windMph > maxWind {
            warnings.append("Breezy (\(hour.windMph) mph)")
        }
        
        // Temperature check
        if hour.temp > maxTemp {
            issues.append("Too hot (\(hour.temp)°F)")
        } else if hour.temp < minTemp - 4 {
            issues.append("Too cold (\(hour.temp)°F)")
        } else if hour.temp < minTemp {
            warnings.append("Chilly (\(hour.temp)°F)")
        } else if hour.temp > maxTemp - 2 {
            warnings.append("Warm (\(hour.temp)°F)")
        }
        
        // UV index check
        if hour.uvIndex > maxUV + 2.5 {
            issues.append("High UV (\(String(format: "%.1f", hour.uvIndex)))")
        } else if hour.uvIndex > maxUV {
            warnings.append("Moderate UV (\(String(format: "%.1f", hour.uvIndex)))")
        }
        
        let textLower = hour.conditionText.lowercased()
        if textLower.contains("rain") || textLower.contains("storm") {
            issues.append("Rain")
        }
        
        if !issues.isEmpty {
            return (.poor, issues.first ?? "Poor", issues.joined(separator: " • "))
        } else if !warnings.isEmpty {
            return (.fair, warnings.first ?? "Fair", warnings.joined(separator: " • "))
        } else {
            return (.good, "Good to Play", "Prime conditions: Low wind drift, comfortable temp, crisp sets.")
        }
    }
    
    public func calculateBestPlayingWindow(daylightHours: [HourlyVolleyballWeather]) -> (windowText: String, isGreen: Bool)? {
        guard !daylightHours.isEmpty else { return nil }
        
        let evaluated = daylightHours.map { (hour: $0, eval: evaluate(hour: $0)) }
        
        var bestStart = -1
        var bestLen = 0
        var curStart = -1
        var curLen = 0
        
        for i in 0..<evaluated.count {
            if evaluated[i].eval.suitability == .good {
                if curStart == -1 { curStart = i }
                curLen += 1
                if curLen > bestLen {
                    bestLen = curLen
                    bestStart = curStart
                }
            } else {
                curStart = -1
                curLen = 0
            }
        }
        
        if bestLen >= 2 {
            let startH = evaluated[bestStart].hour
            let endH = evaluated[bestStart + bestLen - 1].hour
            return ("\(startH.hourLabel) – \(endH.hourLabel)", true)
        }
        
        for i in 0..<evaluated.count {
            if evaluated[i].eval.suitability != .poor {
                if curStart == -1 { curStart = i }
                curLen += 1
                if curLen > bestLen {
                    bestLen = curLen
                    bestStart = curStart
                }
            } else {
                curStart = -1
                curLen = 0
            }
        }
        
        if bestLen >= 1 {
            let startH = evaluated[bestStart].hour
            let endH = evaluated[bestStart + bestLen - 1].hour
            return ("\(startH.hourLabel) – \(endH.hourLabel)", false)
        }
        
        return nil
    }
}

public struct HourlyVolleyballWeather: Identifiable, Codable, Hashable {
    public var id: String { timeStr }
    public let timeStr: String
    public let hourLabel: String
    public let hour24: Int
    public let temp: Int
    public let windMph: Int
    public let uvIndex: Double
    public let conditionEmoji: String
    public let conditionText: String
    
    public init(
        timeStr: String,
        hourLabel: String,
        hour24: Int,
        temp: Int,
        windMph: Int,
        uvIndex: Double,
        conditionEmoji: String,
        conditionText: String
    ) {
        self.timeStr = timeStr
        self.hourLabel = hourLabel
        self.hour24 = hour24
        self.temp = temp
        self.windMph = windMph
        self.uvIndex = uvIndex
        self.conditionEmoji = conditionEmoji
        self.conditionText = conditionText
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
    public let sunrise: String
    public let sunset: String
    public let daylightHours: [HourlyVolleyballWeather]
    
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
        conditionText: String,
        sunrise: String = "6:56 AM",
        sunset: String = "7:04 PM",
        daylightHours: [HourlyVolleyballWeather] = []
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
        self.sunrise = sunrise
        self.sunset = sunset
        self.daylightHours = daylightHours
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
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(coords.lat)&longitude=\(coords.lon)&daily=weather_code,temperature_2m_max,temperature_2m_min,uv_index_max,wind_speed_10m_max,sunrise,sunset&hourly=temperature_2m,uv_index,wind_speed_10m,weather_code&temperature_unit=fahrenheit&wind_speed_unit=mph&timezone=auto&forecast_days=7"
        
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
        
        let isoTimeFormatter = DateFormatter()
        isoTimeFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        isoTimeFormatter.timeZone = TimeZone(identifier: "America/Los_Angeles") ?? .current
        
        let sunTimeFormatter = DateFormatter()
        sunTimeFormatter.dateFormat = "h:mm a"
        sunTimeFormatter.timeZone = TimeZone(identifier: "America/Los_Angeles") ?? .current
        
        let hourLabelFormatter = DateFormatter()
        hourLabelFormatter.dateFormat = "h a"
        hourLabelFormatter.timeZone = TimeZone(identifier: "America/Los_Angeles") ?? .current
        
        let hourly = response.hourly
        let hTimes = hourly?.time ?? []
        
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
            
            // Sunrise and Sunset parsing
            let rawSunrise = (i < (daily.sunrise?.count ?? 0)) ? (daily.sunrise?[i] ?? "") : ""
            let rawSunset = (i < (daily.sunset?.count ?? 0)) ? (daily.sunset?[i] ?? "") : ""
            
            let sunriseDate = isoTimeFormatter.date(from: rawSunrise)
            let sunsetDate = isoTimeFormatter.date(from: rawSunset)
            
            let sunriseStr = sunriseDate != nil ? sunTimeFormatter.string(from: sunriseDate!) : "6:56 AM"
            let sunsetStr = sunsetDate != nil ? sunTimeFormatter.string(from: sunsetDate!) : "7:04 PM"
            
            var startHour = 7
            var endHour = 19
            if let sr = sunriseDate {
                startHour = max(5, min(8, Calendar.current.component(.hour, from: sr)))
            }
            if let ss = sunsetDate {
                endHour = max(17, min(21, Calendar.current.component(.hour, from: ss)))
            }
            
            var daylightHours: [HourlyVolleyballWeather] = []
            if let h = hourly {
                for (hIdx, hTimeStr) in hTimes.enumerated() {
                    guard hTimeStr.hasPrefix(dateStr) else { continue }
                    if let hDate = isoTimeFormatter.date(from: hTimeStr) {
                        let hour24 = Calendar.current.component(.hour, from: hDate)
                        if hour24 >= startHour && hour24 <= endHour {
                            let hTemp = (hIdx < h.temperature_2m.count) ? Int(h.temperature_2m[hIdx].rounded()) : tAvg
                            let hWind = (hIdx < h.wind_speed_10m.count) ? Int(h.wind_speed_10m[hIdx].rounded()) : 6
                            let hUv = (hIdx < h.uv_index.count) ? h.uv_index[hIdx] : 2.0
                            let hCode = (hIdx < h.weather_code.count) ? h.weather_code[hIdx] : code
                            let (hEmoji, hText) = weatherCodeInterpretation(hCode)
                            let hLabel = hourLabelFormatter.string(from: hDate)
                            
                            daylightHours.append(HourlyVolleyballWeather(
                                timeStr: hTimeStr,
                                hourLabel: hLabel,
                                hour24: hour24,
                                temp: hTemp,
                                windMph: hWind,
                                uvIndex: hUv,
                                conditionEmoji: hEmoji,
                                conditionText: hText
                            ))
                        }
                    }
                }
            }
            
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
                conditionText: text,
                sunrise: sunriseStr,
                sunset: sunsetStr,
                daylightHours: daylightHours
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
        
        let sampleTemps = [60, 63, 67, 70, 72, 74, 75, 76, 74, 72, 70, 67, 63]
        let sampleWinds = [4, 5, 6, 7, 8, 9, 10, 11, 12, 10, 8, 6, 5]
        let sampleUvs = [0.5, 1.2, 2.2, 3.4, 4.2, 4.8, 5.0, 4.5, 3.5, 2.5, 1.5, 0.6, 0.1]
        let sampleHours = [7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19]
        
        for i in 0..<7 {
            let d = calendar.date(byAdding: .day, value: i, to: Date()) ?? Date()
            let dayName = i == 0 ? "Today" : (i == 1 ? "Tomorrow" : weekdayFormatter.string(from: d))
            let dateFormatted = displayFormatter.string(from: d)
            let fullTitle = fullFormatter.string(from: d)
            let tMax = baseTemps[i]
            let tMin = tMax - 16
            
            var daylightHours: [HourlyVolleyballWeather] = []
            for hIdx in 0..<sampleHours.count {
                let h24 = sampleHours[hIdx]
                let ampm = h24 >= 12 ? "PM" : "AM"
                let h12 = h24 % 12 == 0 ? 12 : h24 % 12
                daylightHours.append(HourlyVolleyballWeather(
                    timeStr: "day-\(i)-h\(h24)",
                    hourLabel: "\(h12) \(ampm)",
                    hour24: h24,
                    temp: sampleTemps[hIdx],
                    windMph: min(baseWinds[i] + (sampleWinds[hIdx] - 8), 20),
                    uvIndex: sampleUvs[hIdx],
                    conditionEmoji: sampleWinds[hIdx] > 11 ? "💨" : (h24 == 19 ? "🌅" : emojis[i]),
                    conditionText: sampleWinds[hIdx] > 11 ? "Breezy" : (h24 == 19 ? "Sunset" : texts[i])
                ))
            }
            
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
                conditionText: texts[i],
                sunrise: "6:56 AM",
                sunset: "7:04 PM",
                daylightHours: daylightHours
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
    let sunrise: [String]?
    let sunset: [String]?
}

fileprivate struct OpenMeteoHourly: Decodable {
    let time: [String]
    let temperature_2m: [Double]
    let uv_index: [Double]
    let wind_speed_10m: [Double]
    let weather_code: [Int]
}
