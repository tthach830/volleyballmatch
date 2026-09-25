import SwiftUI

public struct VolleyballWeatherView: View {
    @ObservedObject var dataManager: DataManager
    @StateObject private var weatherService = WeatherService.shared
    
    @State private var selectedCourt: String = "Main Beach"
    @State private var weeklyDays: [DailyVolleyballWeather] = []
    @State private var selectedDayIndex: Int = 0
    @State private var selectedHourIndex: Int? = nil
    @State private var selectedDayHourMap: [Int: Int] = [:]
    @State private var isLoading: Bool = true
    @State private var showSettings: Bool = false
    @State private var showEmbedSheet: Bool = false
    @State private var showSmartForecastsSheet: Bool = false
    
    // User configurable criteria (stored in UserDefaults)
    @AppStorage("vb_min_temp") private var minTemp: Int = 60
    @AppStorage("vb_max_temp") private var maxTemp: Int = 80
    @AppStorage("vb_max_wind") private var maxWind: Int = 10
    @AppStorage("vb_max_uv") private var maxUV: Double = 4.0
    
    let courts = [
        "Main Beach",
        "Harbor Beach",
        "Capitola Jetty & Beach",
        "Seabright Beach",
        "Manhattan Beach",
        "Hermosa Beach",
        "Huntington Beach"
    ]
    
    private var criteria: VolleyballCriteria {
        VolleyballCriteria(minTemp: minTemp, maxTemp: maxTemp, maxWind: maxWind, maxUV: maxUV)
    }
    
    public init(dataManager: DataManager) {
        self.dataManager = dataManager
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Header & Beach Selector
                    headerSection
                    
                    if isLoading {
                        ProgressView("Fetching 7-day coastal forecast...")
                            .frame(maxWidth: .infinity, minHeight: 120)
                            .foregroundColor(.secondary)
                    } else {
                        // 7-Day Glanceable Best Times Forecast Card
                        glanceableWeeklyForecastCard
                        
                        // Daytime Hourly Forecast (ONLY for the selected day!)
                        if weeklyDays.indices.contains(selectedDayIndex) {
                            daytimeHourlySection(for: weeklyDays[selectedDayIndex], dayIndex: selectedDayIndex)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 90)
            }
            .background(Color(red: 0.08, green: 0.09, blue: 0.13).ignoresSafeArea())
            .navigationTitle("Volleyball?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        if let webcamURL = CourtLocations.webcamURL(for: selectedCourt) {
                            Link(destination: webcamURL) {
                                Image(systemName: "video.fill")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.cyan)
                            }
                        }
                        
                        Button {
                            showSmartForecastsSheet = true
                        } label: {
                            Image(systemName: "sparkles")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.yellow)
                        }
                        
                        Button {
                            showEmbedSheet = true
                        } label: {
                            Image(systemName: "chevron.left.forwardslash.chevron.right")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.cyan)
                        }
                        
                        Button {
                            Task { await loadForecast() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            .sheet(isPresented: $showEmbedSheet) {
                WidgetEmbedSheet(initialCourt: selectedCourt, criteria: criteria)
            }
            .sheet(isPresented: $showSmartForecastsSheet) {
                SmartForecastsSheet(
                    minTemp: $minTemp,
                    maxTemp: $maxTemp,
                    maxWind: $maxWind,
                    maxUV: $maxUV,
                    day: weeklyDays.indices.contains(selectedDayIndex) ? weeklyDays[selectedDayIndex] : weeklyDays.first
                )
            }
            .task {
                await loadForecast()
            }
            .refreshable {
                await loadForecast()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Volleyball?")
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        
                        if let today = weeklyDays.first {
                            let eval = criteria.evaluate(day: today)
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(eval.suitability.dotColor)
                                    .frame(width: 7, height: 7)
                                Text(eval.suitability == .good ? "Great Today" : (eval.suitability == .fair ? "Fair Today" : "Poor Today"))
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(eval.suitability.dotColor)
                            }
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3.5)
                            .background(eval.suitability.dotColor.opacity(0.15))
                            .cornerRadius(999)
                        }
                    }
                    
                    Text("Weekly weather forecast & beach playing suitability")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer(minLength: 8)
                
                // Beach selector menu
                Menu {
                    ForEach(courts, id: \.self) { court in
                        Button {
                            selectedCourt = court
                            Task { await loadForecast() }
                        } label: {
                            HStack {
                                Text(court)
                                if court == selectedCourt {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 11))
                        Text(selectedCourt)
                            .font(.system(size: 12, weight: .bold))
                            .lineLimit(1)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color.cyan.opacity(0.12))
                    .cornerRadius(10)
                }
            }
            
            // Live Beach Web Cam Link
            if let webcamURL = CourtLocations.webcamURL(for: selectedCourt) {
                Link(destination: webcamURL) {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color.cyan.opacity(0.2))
                                .frame(width: 32, height: 32)
                            Image(systemName: "video.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.cyan)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text("\(selectedCourt) Web Cam")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                                Text("LIVE")
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 1.5)
                                    .background(Color.red)
                                    .clipShape(Capsule())
                            }
                            Text("Tap to check real-time waves, sand, tide, and courts")
                                .font(.system(size: 11))
                                .foregroundColor(Color.white.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.right.square.fill")
                            .font(.system(size: 15))
                            .foregroundColor(.cyan)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.11, green: 0.16, blue: 0.25), Color(red: 0.08, green: 0.12, blue: 0.19)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cyan.opacity(0.35), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - 7-Day Glanceable Best Times Forecast Card
    private var glanceableWeeklyForecastCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Title & Subtitle
            HStack(alignment: .center) {
                Text("7-DAY FORECAST (GLANCEABLE BEST TIMES)")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundColor(.white)
                    .tracking(0.3)
                
                Spacer()
                
                Text("Tap a day for hourly view")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.55))
            }
            
            // 7 Days Columns Row
            HStack(alignment: .top, spacing: 3) {
                ForEach(Array(weeklyDays.enumerated()), id: \.element.id) { index, day in
                    let isSelected = index == selectedDayIndex
                    let windowInfo = criteria.calculateBestPlayingWindowDetails(daylightHours: day.daylightHours)
                    let minTempAll = weeklyDays.map { $0.tempMin }.min() ?? 45
                    let maxTempAll = weeklyDays.map { $0.tempMax }.max() ?? 95
                    let tempRange = max(1, maxTempAll - minTempAll)
                    let barHeightPct = max(0.25, min(1.0, Double(day.tempMax - minTempAll) / Double(tempRange)))
                    
                    let pillText: String = {
                        if windowInfo.suitability == .poor { return "Poor" }
                        let parts = windowInfo.windowText.components(separatedBy: " – ")
                        if parts.count == 2 {
                            let s1 = parts[0].replacingOccurrences(of: " ", with: "")
                            let s2 = parts[1].replacingOccurrences(of: " ", with: "")
                            return "\(s1)–\(s2)"
                        }
                        return windowInfo.windowText
                    }()
                    
                    let colDayName: String = {
                        if index == 0 { return "TODAY" }
                        if let commaIdx = day.fullDayTitle.firstIndex(of: ",") {
                            return String(day.fullDayTitle[..<commaIdx].prefix(3)).uppercased()
                        }
                        return String(day.dayName.prefix(3)).uppercased()
                    }()
                    
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                            selectedDayIndex = index
                        }
                    } label: {
                        VStack(spacing: 5) {
                            // Day Name (e.g. TODAY, THU, FRI)
                            Text(colDayName)
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundColor(isSelected ? .orange : Color.white.opacity(0.85))
                                .lineLimit(1)
                            
                            // Weather Emoji
                            Text(day.conditionEmoji)
                                .font(.system(size: 16))
                            
                            // Best Time Pill
                            Text(pillText)
                                .font(.system(size: 8, weight: .heavy))
                                .foregroundColor(windowInfo.suitability == .good ? Color(red: 0.29, green: 0.87, blue: 0.5) : (windowInfo.suitability == .fair ? Color(red: 0.98, green: 0.8, blue: 0.08) : Color(red: 0.97, green: 0.44, blue: 0.44)))
                                .padding(.horizontal, 3)
                                .padding(.vertical, 2)
                                .frame(maxWidth: .infinity)
                                .background(
                                    (windowInfo.suitability == .good ? Color.green : (windowInfo.suitability == .fair ? Color.yellow : Color.red)).opacity(0.18)
                                )
                                .cornerRadius(4)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            
                            // Vertical Thermometer Bar
                            ZStack(alignment: .bottom) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.white.opacity(0.08))
                                    .frame(width: 8, height: 50)
                                
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.orange, Color.cyan],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: 8, height: CGFloat(50 * barHeightPct))
                            }
                            
                            // Max Temp
                            Text("\(day.tempMax)°")
                                .font(.system(size: 12, weight: .heavy))
                                .foregroundColor(.white)
                            
                            // Min Temp
                            Text("\(day.tempMin)°")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.55))
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 2)
                        .frame(maxWidth: .infinity)
                        .background(isSelected ? Color(red: 0.22, green: 0.14, blue: 0.12) : Color.clear)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isSelected ? Color(red: 0.9, green: 0.45, blue: 0.25) : Color.clear, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(Color(red: 0.09, green: 0.11, blue: 0.15))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(red: 0.16, green: 0.19, blue: 0.26), lineWidth: 1))
    }
    
    // MARK: - Customizable Criteria Card
    private var criteriaSettingsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    showSettings.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(.orange)
                    Text("Your Ideal Playing Conditions")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(minTemp)-\(maxTemp)°F • <\(maxWind)mph • UV <\(String(format: "%.0f", maxUV))")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                    Image(systemName: showSettings ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                }
            }
            
            if showSettings {
                VStack(spacing: 14) {
                    Divider().background(Color.white.opacity(0.1))
                    
                    // Temperature Range
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("🌡️ Temperature Range")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                            Spacer()
                            Text("\(minTemp)°F – \(maxTemp)°F")
                                .font(.system(size: 12, weight: .black))
                                .foregroundColor(.orange)
                        }
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("MIN: \(minTemp)°F").font(.caption2).foregroundColor(.secondary)
                                Stepper("", value: $minTemp, in: 45...max(45, maxTemp - 5))
                                    .labelsHidden()
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("MAX: \(maxTemp)°F").font(.caption2).foregroundColor(.secondary)
                                Stepper("", value: $maxTemp, in: min(95, minTemp + 5)...95)
                                    .labelsHidden()
                            }
                        }
                    }
                    
                    // Max Wind Speed
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("💨 Max Wind Speed")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                            Spacer()
                            Text("Below \(maxWind) mph")
                                .font(.system(size: 12, weight: .black))
                                .foregroundColor(.cyan)
                        }
                        Slider(value: Binding(get: { Double(maxWind) }, set: { maxWind = Int($0) }), in: 5...25, step: 1)
                            .tint(.cyan)
                        HStack {
                            Text("5 mph (Calm)").font(.caption2).foregroundColor(.secondary)
                            Spacer()
                            Text("10 mph (Default)").font(.caption2).foregroundColor(.secondary)
                            Spacer()
                            Text("25 mph (Gale)").font(.caption2).foregroundColor(.secondary)
                        }
                    }
                    
                    // Max UV Index
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("☀️ Max UV Index")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                            Spacer()
                            Text("Below \(String(format: "%.1f", maxUV))")
                                .font(.system(size: 12, weight: .black))
                                .foregroundColor(.yellow)
                        }
                        Slider(value: $maxUV, in: 1...11, step: 0.5)
                            .tint(.yellow)
                        HStack {
                            Text("1 (Low)").font(.caption2).foregroundColor(.secondary)
                            Spacer()
                            Text("4 (Default: Mod)").font(.caption2).foregroundColor(.secondary)
                            Spacer()
                            Text("11 (Extreme)").font(.caption2).foregroundColor(.secondary)
                        }
                    }
                    
                    // Reset Button
                    HStack {
                        Spacer()
                        Button("Reset to Defaults") {
                            minTemp = 60
                            maxTemp = 80
                            maxWind = 10
                            maxUV = 4.0
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding(14)
        .background(Color(red: 0.12, green: 0.14, blue: 0.20))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
    
    private func activeHourIndex(for day: DailyVolleyballWeather, dayIndex: Int) -> Int? {
        if let chosen = selectedDayHourMap[dayIndex], chosen < day.daylightHours.count {
            return chosen
        }
        if let idealIdx = day.daylightHours.firstIndex(where: { criteria.evaluate(hour: $0).suitability == .good }) {
            return idealIdx
        }
        if let fairIdx = day.daylightHours.firstIndex(where: { criteria.evaluate(hour: $0).suitability == .fair }) {
            return fairIdx
        }
        return day.daylightHours.isEmpty ? nil : 0
    }
    
    // MARK: - Daytime Hourly Suitability Section (Sunrise to Sunset)
    private func daytimeHourlySection(for day: DailyVolleyballWeather, dayIndex: Int) -> some View {
        let bestWindow = criteria.calculateBestPlayingWindow(daylightHours: day.daylightHours)
        let activeHIdx = activeHourIndex(for: day, dayIndex: dayIndex)
        
        return VStack(alignment: .leading, spacing: 12) {
            // Header: Title & Sunrise/Sunset
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(day.fullDayTitle)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                            if dayIndex == 0 {
                                Text("TODAY")
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.orange)
                                    .cornerRadius(4)
                            }
                        }
                        Text("Sunrise to Sunset")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.65))
                    }
                    
                    Spacer(minLength: 4)
                    
                    // Sunrise & Sunset chips
                    HStack(spacing: 6) {
                        HStack(spacing: 3) {
                            Text("🌅")
                                .font(.system(size: 10))
                            Text(day.sunrise)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.orange.opacity(0.12))
                        .cornerRadius(6)
                        
                        HStack(spacing: 3) {
                            Text("🌇")
                                .font(.system(size: 10))
                            Text(day.sunset)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.pink)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.pink.opacity(0.12))
                        .cornerRadius(6)
                    }
                }
            }
            
            // Best window badge (if found)
            if let bw = bestWindow {
                HStack(spacing: 8) {
                    Text("🌟")
                        .font(.system(size: 13))
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("Best Window to Play:")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                            Text(bw.windowText)
                                .font(.system(size: 12, weight: .black))
                                .foregroundColor(bw.isGreen ? .green : .yellow)
                        }
                        Text(bw.isGreen ? "Optimal wind, UV, and comfortable temperatures." : "Playable conditions with manageable breeze.")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.8))
                    }
                    Spacer()
                }
                .padding(10)
                .background((bw.isGreen ? Color.green : Color.yellow).opacity(0.12))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke((bw.isGreen ? Color.green : Color.yellow).opacity(0.3), lineWidth: 1)
                )
            }
            
            // Smart Highlight Bar vs Muted Dot Timeline Chart
            if !day.daylightHours.isEmpty {
                VStack(spacing: 8) {
                    HStack {
                        Label("CONDITIONS HIGHLIGHTED", systemImage: "sparkles")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.yellow)
                        Spacer()
                        Button {
                            showSmartForecastsSheet = true
                        } label: {
                            Text("Edit Conditions")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.cyan)
                        }
                    }
                    
                    HStack(alignment: .bottom, spacing: 3) {
                        ForEach(Array(day.daylightHours.enumerated()), id: \.element.id) { hIdx, hour in
                            let eval = criteria.evaluate(hour: hour)
                            let isMatch = eval.suitability == .good
                            let isFair = eval.suitability == .fair
                            let isSelected = activeHIdx == hIdx
                            
                            Button {
                                withAnimation(.spring(response: 0.25)) {
                                    selectedDayHourMap[dayIndex] = hIdx
                                }
                            } label: {
                                VStack {
                                    Spacer()
                                    if isMatch || isFair {
                                        let barHeight: CGFloat = isMatch ? CGFloat(min(56, max(28, (hour.temp - 50) * 2 + 20))) : 22
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(
                                                isMatch ?
                                                LinearGradient(colors: [Color.yellow, Color.orange], startPoint: .top, endPoint: .bottom) :
                                                LinearGradient(colors: [Color.yellow.opacity(0.8), Color.orange.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                                            )
                                            .frame(maxWidth: 14, minHeight: barHeight, maxHeight: barHeight)
                                            .shadow(color: isMatch ? Color.orange.opacity(0.6) : .clear, radius: 3)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 3)
                                                    .stroke(isSelected ? Color.cyan : Color.clear, lineWidth: 1.5)
                                            )
                                    } else {
                                        Circle()
                                            .fill(isSelected ? Color.cyan : Color.white.opacity(0.25))
                                            .frame(width: isSelected ? 7 : 5, height: isSelected ? 7 : 5)
                                            .padding(.bottom, 2)
                                    }
                                }
                                .frame(maxWidth: .infinity, maxHeight: 60)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.bottom, 4)
                    .overlay(
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 1),
                        alignment: .bottom
                    )
                    
                    HStack {
                        Text(day.daylightHours.first?.hourLabel.replacingOccurrences(of: " ", with: "") ?? "7A")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(Color.white.opacity(0.5))
                        Spacer()
                        if day.daylightHours.count > 4 {
                            Text(day.daylightHours[day.daylightHours.count / 2].hourLabel.replacingOccurrences(of: " ", with: ""))
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(Color.white.opacity(0.5))
                            Spacer()
                        }
                        Text(day.daylightHours.last?.hourLabel.replacingOccurrences(of: " ", with: "") ?? "7P")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(Color.white.opacity(0.5))
                    }
                    .padding(.horizontal, 2)
                }
                .padding(10)
                .background(Color.black.opacity(0.3))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.06), lineWidth: 1))
            }
            
            // Hourly horizontal track
            if day.daylightHours.isEmpty {
                Text("No daytime hourly data available for this day.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 60)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 52), spacing: 6)], spacing: 6) {
                    ForEach(Array(day.daylightHours.enumerated()), id: \.element.id) { hIdx, hour in
                        hourlyCard(for: hour, index: hIdx, isSelected: activeHIdx == hIdx) {
                            selectedDayHourMap[dayIndex] = hIdx
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            
            // Selected Hour Detail Callout
            if let hIdx = activeHIdx, hIdx < day.daylightHours.count {
                selectedHourDetailCard(for: day.daylightHours[hIdx])
            }
        }
        .padding(14)
        .background(Color(red: 0.09, green: 0.11, blue: 0.15))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(red: 0.16, green: 0.19, blue: 0.26), lineWidth: 1))
    }
    
    // MARK: - Hourly Card (Fits Screen Width without Horizontal Scroll)
    private func hourlyCard(for hour: HourlyVolleyballWeather, index: Int, isSelected: Bool, onSelect: @escaping () -> Void) -> some View {
        let eval = criteria.evaluate(hour: hour)
        
        return Button {
            withAnimation(.spring(response: 0.25)) {
                onSelect()
            }
        } label: {
            VStack(spacing: 4) {
                // Hour label (e.g., 7 AM)
                Text(hour.hourLabel)
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(isSelected ? .orange : .white)
                    .lineLimit(1)
                
                // Suitability Dot with Glow
                ZStack {
                    Circle()
                        .fill(eval.suitability.dotColor.opacity(0.25))
                        .frame(width: 16, height: 16)
                    Circle()
                        .fill(eval.suitability.dotColor)
                        .frame(width: 7, height: 7)
                        .shadow(color: eval.suitability.dotColor.opacity(0.8), radius: 3)
                }
                
                // Condition emoji
                Text(hour.conditionEmoji)
                    .font(.system(size: 15))
                
                // Temp
                Text("\(hour.temp)°")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(hour.temp > criteria.maxTemp ? .red : (hour.temp < criteria.minTemp ? .blue : .white))
                    .lineLimit(1)
                
                // Wind
                Text("💨\(hour.windMph)")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(hour.windMph > criteria.maxWind ? .red : .cyan)
                    .lineLimit(1)
                    .padding(.horizontal, 2)
                    .padding(.vertical, 1)
                    .background(Color.cyan.opacity(0.12))
                    .cornerRadius(3)
                
                // UV
                Text("☀️\(String(format: "%.0f", hour.uvIndex))")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(hour.uvIndex > criteria.maxUV ? .orange : .yellow)
                    .lineLimit(1)
                    .padding(.horizontal, 2)
                    .padding(.vertical, 1)
                    .background(Color.yellow.opacity(0.12))
                    .cornerRadius(3)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 2)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.orange.opacity(0.2) : Color.white.opacity(0.04))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.orange : Color.white.opacity(0.08), lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func selectedHourDetailCard(for hour: HourlyVolleyballWeather) -> some View {
        let eval = criteria.evaluate(hour: hour)
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(hour.hourLabel) Conditions & Suitability")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(eval.suitability.dotColor)
                        .frame(width: 6, height: 6)
                    Text(eval.label)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(eval.suitability.dotColor)
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(eval.suitability.dotColor.opacity(0.15))
                .cornerRadius(6)
            }
            
            HStack(spacing: 8) {
                metricChip(
                    icon: "thermometer.medium",
                    title: "\(hour.temp)°F",
                    subtitle: hour.temp >= criteria.minTemp && hour.temp <= criteria.maxTemp ? "Ideal" : (hour.temp > criteria.maxTemp ? "Hot" : "Cold"),
                    color: hour.temp > criteria.maxTemp ? .red : (hour.temp < criteria.minTemp ? .blue : .orange)
                )
                metricChip(
                    icon: "wind",
                    title: "\(hour.windMph) mph",
                    subtitle: hour.windMph <= criteria.maxWind ? "Calm" : "Breezy/Windy",
                    color: hour.windMph > criteria.maxWind ? .red : .cyan
                )
                metricChip(
                    icon: "sun.max.fill",
                    title: "UV \(String(format: "%.1f", hour.uvIndex))",
                    subtitle: hour.uvIndex <= criteria.maxUV ? "Safe" : "High",
                    color: hour.uvIndex > criteria.maxUV ? .red : .yellow
                )
            }
            
            HStack(spacing: 6) {
                Text("🏐")
                    .font(.system(size: 11))
                Text(eval.tip)
                    .font(.system(size: 11))
                    .foregroundColor(Color.white.opacity(0.9))
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.04))
            .cornerRadius(6)
        }
        .padding(10)
        .background(Color(red: 0.15, green: 0.17, blue: 0.24))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(eval.suitability.dotColor.opacity(0.4), lineWidth: 1)
        )
    }
    
    // MARK: - Weekly Highlights Banner (Top Playing Times at a Glance)
    @ViewBuilder
    private var weeklyHighlightsBanner: some View {
        let ranked: [(index: Int, day: DailyVolleyballWeather, info: BestPlayingWindowInfo)] = weeklyDays.enumerated().compactMap { (index, day) in
            let info = criteria.calculateBestPlayingWindowDetails(daylightHours: day.daylightHours)
            if info.suitability == .poor { return nil }
            return (index, day, info)
        }
        .sorted { $0.info.score > $1.info.score }
        
        let topWindows = Array(ranked.prefix(3))
        
        if !topWindows.isEmpty {
            let medals = ["🥇", "🥈", "🥉"]
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("TOP PLAYING TIMES THIS WEEK", systemImage: "trophy.fill")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.yellow)
                        .tracking(0.5)
                    Spacer()
                    Text("Tap to view day")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 6) {
                    ForEach(Array(topWindows.enumerated()), id: \.element.index) { medalIdx, item in
                        Button {
                            withAnimation(.spring(response: 0.25)) {
                                selectedDayIndex = item.index
                                selectedHourIndex = nil
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Text(medalIdx < medals.count ? medals[medalIdx] : "🏐")
                                    .font(.system(size: 14))
                                
                                VStack(alignment: .leading, spacing: 1) {
                                    HStack(spacing: 4) {
                                        Text("\(item.day.dayName):")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.white)
                                        Text(item.info.windowText)
                                            .font(.system(size: 11, weight: .black))
                                            .foregroundColor(item.info.suitability == .good ? .green : .yellow)
                                    }
                                    Text(item.info.summaryText)
                                        .font(.system(size: 9))
                                        .foregroundColor(Color.white.opacity(0.65))
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(Color.white.opacity(0.4))
                            }
                            .padding(8)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke((item.info.suitability == .good ? Color.green : Color.yellow).opacity(0.25), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(12)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.16, green: 0.13, blue: 0.08), Color(red: 0.12, green: 0.14, blue: 0.20)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Mini Daytime Timeline (Sunrise to Sunset)
    @ViewBuilder
    private func miniTimelineView(for day: DailyVolleyballWeather) -> some View {
        if !day.daylightHours.isEmpty {
            VStack(spacing: 5) {
                HStack {
                    Text("🌅 \(day.sunrise)")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.orange)
                    Spacer()
                    Text("DAYTIME HOURS • SUNRISE TO SUNSET")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(Color.white.opacity(0.5))
                        .tracking(0.5)
                    Spacer()
                    Text("🌇 \(day.sunset)")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.pink)
                }
                
                HStack(spacing: 2) {
                    ForEach(day.daylightHours, id: \.id) { hour in
                        let hEval = criteria.evaluate(hour: hour)
                        let isIdeal = hEval.suitability == .good
                        VStack(spacing: 2) {
                            Text(hour.hourLabel.replacingOccurrences(of: " ", with: ""))
                                .font(.system(size: 8, weight: .heavy))
                                .foregroundColor(isIdeal ? .white : Color.white.opacity(0.6))
                                .lineLimit(1)
                            
                            VStack {
                                Spacer()
                                if isIdeal {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(LinearGradient(colors: [Color.yellow, Color.orange], startPoint: .top, endPoint: .bottom))
                                        .frame(width: 7, height: 14)
                                        .shadow(color: Color.orange.opacity(0.5), radius: 2)
                                } else if hEval.suitability == .fair {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.yellow)
                                        .frame(width: 7, height: 8)
                                } else {
                                    Circle()
                                        .fill(Color.white.opacity(0.25))
                                        .frame(width: 4, height: 4)
                                        .padding(.bottom, 2)
                                }
                            }
                            .frame(height: 14)
                            
                            Text("\(hour.temp)°")
                                .font(.system(size: 7, weight: .semibold))
                                .foregroundColor(Color.white.opacity(0.7))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 3)
                        .background(isIdeal ? Color.yellow.opacity(0.12) : Color.white.opacity(0.03))
                        .cornerRadius(4)
                    }
                }
            }
            .padding(7)
            .background(Color.black.opacity(0.3))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.06), lineWidth: 1))
        }
    }

    // MARK: - Daily Breakdown Cards
    private var dailyBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            weeklyHighlightsBanner
            
            Text("7-DAY FORECAST")
                .font(.system(size: 13, weight: .black))
                .foregroundColor(.white)
                .tracking(0.5)
                .padding(.top, 4)
            
            ForEach(Array(weeklyDays.enumerated()), id: \.element.id) { index, day in
                dailyCard(for: day, index: index)
            }
        }
    }
    
    private func dailyCard(for day: DailyVolleyballWeather, index: Int) -> some View {
        let eval = criteria.evaluate(day: day)
        let isSelected = index == selectedDayIndex
        let windowInfo = criteria.calculateBestPlayingWindowDetails(daylightHours: day.daylightHours)
        
        return VStack(alignment: .leading, spacing: 10) {
            // Header with Day Summary & Prominent Best Playing Time Badge
            HStack(alignment: .top) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(eval.suitability.dotColor)
                        .frame(width: 8, height: 8)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(day.fullDayTitle)
                                .font(.system(size: 15, weight: .black))
                                .foregroundColor(.white)
                            if index == 0 {
                                Text("TODAY")
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.2))
                                    .cornerRadius(4)
                            }
                        }
                        Text("\(day.conditionEmoji) \(day.conditionText) • High \(day.tempMax)°F, Low \(day.tempMin)°F")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Prominent Best Time Badge (Glanceable!)
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(windowInfo.suitability == .poor ? "⚠️" : "🌟")
                            .font(.system(size: 10))
                        Text(windowInfo.suitability == .poor ? "Poor All Day" : "Best: \(windowInfo.windowText)")
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(windowInfo.suitability.dotColor)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(windowInfo.suitability.dotColor.opacity(0.12))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(windowInfo.suitability.dotColor.opacity(0.35), lineWidth: 1)
                    )
                    
                    Text(windowInfo.summaryText)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.65))
                        .lineLimit(1)
                }
            }
            
            // Mini Daytime Timeline Track (Sunrise to Sunset)
            miniTimelineView(for: day)
            
            // Metrics Chips Row
            HStack(spacing: 8) {
                metricChip(
                    icon: "thermometer.medium",
                    title: "\(day.tempAvg)°F Avg",
                    subtitle: "\(day.tempMin)°–\(day.tempMax)°",
                    color: day.tempMax > maxTemp ? .red : (day.tempAvg < minTemp ? .blue : .orange)
                )
                metricChip(
                    icon: "wind",
                    title: "\(day.windMax) mph",
                    subtitle: day.windMax <= maxWind ? "Calm/Breeze" : "Windy",
                    color: day.windMax > maxWind ? (day.windMax > maxWind + 3 ? .red : .yellow) : .cyan
                )
                metricChip(
                    icon: "sun.max.fill",
                    title: "UV \(String(format: "%.1f", day.uvMax))",
                    subtitle: day.uvMax <= maxUV ? "Low Risk" : "SPF Advised",
                    color: day.uvMax > maxUV ? (day.uvMax > maxUV + 2.5 ? .red : .yellow) : .green
                )
            }
            
            // Beach Tip Box
            HStack(alignment: .top, spacing: 8) {
                Text("🏐")
                    .font(.system(size: 13))
                Text(eval.tip)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.85))
                    .lineSpacing(2)
            }
            .padding(9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.04))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(eval.suitability.dotColor.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(12)
        .background(isSelected ? Color.orange.opacity(0.08) : Color(red: 0.12, green: 0.14, blue: 0.20))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isSelected ? Color.orange.opacity(0.6) : Color.white.opacity(0.08), lineWidth: isSelected ? 1.5 : 1)
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.25)) {
                selectedDayIndex = index
                selectedHourIndex = nil
            }
        }
    }
    
    private func metricChip(icon: String, title: String, subtitle: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(color.opacity(0.1))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(color.opacity(0.25), lineWidth: 1))
    }
    
    // MARK: - Data Fetcher
    private func loadForecast() async {
        isLoading = true
        let days = await weatherService.fetchWeeklyForecast(for: selectedCourt)
        await MainActor.run {
            self.weeklyDays = days
            self.isLoading = false
        }
    }
}

// MARK: - Widget Embed Sheet
public struct WidgetEmbedSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCourt: String
    @State private var selectedTheme: String = "dark"
    @State private var selectedView: String = "full"
    @State private var copiedType: String? = nil
    
    let criteria: VolleyballCriteria
    let courts = [
        "Main Beach",
        "Harbor Beach",
        "Capitola Jetty & Beach",
        "Seabright Beach",
        "Manhattan Beach",
        "Hermosa Beach",
        "Huntington Beach"
    ]
    
    public init(initialCourt: String, criteria: VolleyballCriteria) {
        self._selectedCourt = State(initialValue: initialCourt)
        self.criteria = criteria
    }
    
    private var baseUrl: String {
        "https://setgames.app"
    }
    
    private var encodedCourt: String {
        selectedCourt.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? selectedCourt
    }
    
    private var iframeCode: String {
        let height = selectedView == "compact" ? "340" : "520"
        let url = "\(baseUrl)/widget.html?beach=\(encodedCourt)&theme=\(selectedTheme)&view=\(selectedView)&minTemp=\(criteria.minTemp)&maxTemp=\(criteria.maxTemp)&maxWind=\(criteria.maxWind)&maxUv=\(String(format: "%.1f", criteria.maxUV))"
        return "<iframe src=\"\(url)\" width=\"100%\" height=\"\(height)\" style=\"border:none; border-radius:16px; overflow:hidden;\" loading=\"lazy\"></iframe>"
    }
    
    private var scriptCode: String {
        let snippet = "<div id=\"volleyball-weather-widget\" data-beach=\"\(selectedCourt)\" data-theme=\"\(selectedTheme)\" data-view=\"\(selectedView)\" data-min-temp=\"\(criteria.minTemp)\" data-max-temp=\"\(criteria.maxTemp)\" data-max-wind=\"\(criteria.maxWind)\" data-max-uv=\"\(String(format: "%.1f", criteria.maxUV))\"></div>\n<script src=\"\(baseUrl)/widget.js\" async></script>"
        return snippet
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Intro
                    HStack(spacing: 12) {
                        Image(systemName: "globe")
                            .font(.system(size: 26))
                            .foregroundColor(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Embed on Any Website")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Works on Squarespace, WordPress, Wix, or custom websites")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(red: 0.12, green: 0.14, blue: 0.19))
                    .cornerRadius(12)
                    
                    // Options
                    VStack(alignment: .leading, spacing: 12) {
                        Text("WIDGET SETTINGS")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                        
                        // Beach Selector
                        Picker("Beach", selection: $selectedCourt) {
                            ForEach(courts, id: \.self) { court in
                                Text(court).tag(court)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(red: 0.14, green: 0.16, blue: 0.22))
                        .cornerRadius(10)
                        
                        // Theme & View Pickers
                        HStack(spacing: 10) {
                            Picker("Theme", selection: $selectedTheme) {
                                Text("Dark Theme").tag("dark")
                                Text("Light Theme").tag("light")
                            }
                            .pickerStyle(.segmented)
                            
                            Picker("Layout", selection: $selectedView) {
                                Text("Full").tag("full")
                                Text("Compact").tag("compact")
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                    
                    // Option 1: iframe
                    codeSnippetCard(
                        title: "Option 1: <iframe> Embed (Recommended)",
                        code: iframeCode,
                        type: "iframe"
                    )
                    
                    // Option 2: Script
                    codeSnippetCard(
                        title: "Option 2: Drop-in <script> Tag",
                        code: scriptCode,
                        type: "script"
                    )
                }
                .padding(16)
            }
            .background(Color(red: 0.08, green: 0.09, blue: 0.13).ignoresSafeArea())
            .navigationTitle("Website Widget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.orange)
                    .fontWeight(.bold)
                }
            }
        }
    }
    
    private func codeSnippetCard(title: String, code: String, type: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.footnote)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
                Button {
                    UIPasteboard.general.string = code
                    copiedType = type
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        if copiedType == type { copiedType = nil }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: copiedType == type ? "checkmark" : "doc.on.doc")
                        Text(copiedType == type ? "Copied!" : "Copy")
                    }
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(copiedType == type ? .white : .orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(copiedType == type ? Color.green : Color.orange.opacity(0.15))
                    .cornerRadius(8)
                }
            }
            
            Text(code)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.cyan)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(red: 0.05, green: 0.06, blue: 0.09))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.1), lineWidth: 1))
        }
        .padding(12)
        .background(Color(red: 0.12, green: 0.14, blue: 0.19))
        .cornerRadius(12)
    }
}

