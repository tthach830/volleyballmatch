import SwiftUI

public struct VolleyballWeatherView: View {
    @ObservedObject var dataManager: DataManager
    @StateObject private var weatherService = WeatherService.shared
    
    @State private var selectedCourt: String = "Main Beach"
    @State private var weeklyDays: [DailyVolleyballWeather] = []
    @State private var selectedDayIndex: Int = 0
    @State private var selectedHourIndex: Int? = nil
    @State private var isLoading: Bool = true
    @State private var showSettings: Bool = false
    @State private var showEmbedSheet: Bool = false
    
    // User configurable criteria (stored in UserDefaults)
    @AppStorage("vb_min_temp") private var minTemp: Int = 60
    @AppStorage("vb_max_temp") private var maxTemp: Int = 80
    @AppStorage("vb_max_wind") private var maxWind: Int = 10
    @AppStorage("vb_max_uv") private var maxUV: Double = 4.0
    
    let courts = [
        "Main Beach",
        "Harbor Beach",
        "Capitola Beach",
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
                VStack(alignment: .leading, spacing: 16) {
                    // Header & Beach Selector
                    headerSection
                    
                    // User Configurable Preferences Card
                    criteriaSettingsCard
                    
                    // 7-Day Chart with Colored Suitability Dots
                    chartSection
                    
                    // Daytime Hourly Suitability Chart (Sunrise to Sunset)
                    if !weeklyDays.isEmpty, selectedDayIndex < weeklyDays.count {
                        daytimeHourlySection(for: weeklyDays[selectedDayIndex])
                    }
                    
                    // Detailed Day Breakdown List
                    dailyBreakdownSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .background(Color(red: 0.08, green: 0.09, blue: 0.13).ignoresSafeArea())
            .navigationTitle("Volleyball?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 14) {
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Volleyball?")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                
                if let today = weeklyDays.first {
                    let eval = criteria.evaluate(day: today)
                    HStack(spacing: 5) {
                        Circle()
                            .fill(eval.suitability.dotColor)
                            .frame(width: 8, height: 8)
                        Text(eval.suitability == .good ? "Great Today" : (eval.suitability == .fair ? "Fair Today" : "Poor Today"))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(eval.suitability.dotColor)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(eval.suitability.dotColor.opacity(0.15))
                    .cornerRadius(999)
                }
                
                Spacer()
                
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
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 12))
                        Text(selectedCourt)
                            .font(.system(size: 13, weight: .bold))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.cyan.opacity(0.12))
                    .cornerRadius(10)
                }
            }
            
            Text("Weekly weather forecast & beach playing suitability")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
        }
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
    
    // MARK: - 7-Day Chart Section
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("7-Day Suitability Chart", systemImage: "chart.bar.xaxis")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                // Legend
                HStack(spacing: 8) {
                    HStack(spacing: 3) {
                        Circle().fill(Color.green).frame(width: 7, height: 7)
                        Text("Good").font(.system(size: 10, weight: .bold)).foregroundColor(.green)
                    }
                    HStack(spacing: 3) {
                        Circle().fill(Color.yellow).frame(width: 7, height: 7)
                        Text("Fair").font(.system(size: 10, weight: .bold)).foregroundColor(.yellow)
                    }
                    HStack(spacing: 3) {
                        Circle().fill(Color.red).frame(width: 7, height: 7)
                        Text("Poor").font(.system(size: 10, weight: .bold)).foregroundColor(.red)
                    }
                }
            }
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                HStack(spacing: 4) {
                    ForEach(Array(weeklyDays.enumerated()), id: \.element.id) { index, day in
                        chartColumn(for: day, index: index)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
        }
        .padding(14)
        .background(Color(red: 0.12, green: 0.14, blue: 0.20))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
    
    // MARK: - Chart Column for Each Day (Fits Screen Width)
    private func chartColumn(for day: DailyVolleyballWeather, index: Int) -> some View {
        let eval = criteria.evaluate(day: day)
        let isSelected = index == selectedDayIndex
        
        return Button {
            withAnimation(.spring(response: 0.25)) {
                selectedDayIndex = index
                selectedHourIndex = nil
            }
        } label: {
            VStack(spacing: 5) {
                // Day name & date
                Text(day.dayName)
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(isSelected ? .orange : .white)
                    .lineLimit(1)
                Text(day.dateFormatted)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // Suitability Dot with Glow Ring
                ZStack {
                    Circle()
                        .fill(eval.suitability.dotColor.opacity(0.25))
                        .frame(width: 18, height: 18)
                    Circle()
                        .fill(eval.suitability.dotColor)
                        .frame(width: 8, height: 8)
                        .shadow(color: eval.suitability.dotColor.opacity(0.8), radius: 3)
                }
                
                // Condition Emoji
                Text(day.conditionEmoji)
                    .font(.system(size: 16))
                
                // High Temp
                Text("\(day.tempMax)°")
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(.white)
                
                // Proportional Temperature Bar
                RoundedRectangle(cornerRadius: 4)
                    .fill(LinearGradient(colors: [.red, .orange, .blue], startPoint: .top, endPoint: .bottom))
                    .frame(width: 5, height: max(18, min(55, CGFloat(day.tempMax - 40) * 1.3)))
                
                // Low Temp
                Text("\(day.tempMin)°")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary)
                
                // Wind & UV Chips
                VStack(spacing: 2) {
                    Text("💨\(day.windMax)m")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.cyan)
                        .lineLimit(1)
                        .padding(.horizontal, 2)
                        .padding(.vertical, 1)
                        .background(Color.cyan.opacity(0.12))
                        .cornerRadius(3)
                    Text("☀️\(String(format: "%.0f", day.uvMax))")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.yellow)
                        .lineLimit(1)
                        .padding(.horizontal, 2)
                        .padding(.vertical, 1)
                        .background(Color.yellow.opacity(0.12))
                        .cornerRadius(3)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 2)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.orange.opacity(0.15) : Color.white.opacity(0.04))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.orange : Color.white.opacity(0.08), lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Daytime Hourly Suitability Section (Sunrise to Sunset)
    private func daytimeHourlySection(for day: DailyVolleyballWeather) -> some View {
        let bestWindow = criteria.calculateBestPlayingWindow(daylightHours: day.daylightHours)
        
        return VStack(alignment: .leading, spacing: 12) {
            // Header: Title & Sunrise/Sunset
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center) {
                    Label("\(day.dayName) Daytime Hours", systemImage: "sun.and.horizon.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
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
                
                Text("Daytime playing conditions from sunrise to sunset. Tap an hour for details.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            // Best window badge (if found)
            if let bw = bestWindow {
                HStack(spacing: 8) {
                    Text("🌟")
                        .font(.system(size: 13))
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 6) {
                            Text("Best Window to Play:")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                            Text(bw.windowText)
                                .font(.system(size: 12, weight: .black))
                                .foregroundColor(bw.isGreen ? .green : .yellow)
                        }
                        Text(bw.isGreen ? "Optimal wind, UV, and comfortable temperatures." : "Playable conditions with manageable breeze.")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
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
            
            // Hourly horizontal track
            if day.daylightHours.isEmpty {
                Text("No daytime hourly data available for this day.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 60)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 52), spacing: 6)], spacing: 6) {
                    ForEach(Array(day.daylightHours.enumerated()), id: \.element.id) { hIdx, hour in
                        hourlyCard(for: hour, index: hIdx)
                    }
                }
                .padding(.vertical, 4)
            }
            
            // Selected Hour Detail Callout
            if let hIdx = selectedHourIndex, hIdx < day.daylightHours.count {
                selectedHourDetailCard(for: day.daylightHours[hIdx])
            }
        }
        .padding(14)
        .background(Color(red: 0.12, green: 0.14, blue: 0.20))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
    
    // MARK: - Hourly Card (Fits Screen Width without Horizontal Scroll)
    private func hourlyCard(for hour: HourlyVolleyballWeather, index: Int) -> some View {
        let eval = criteria.evaluate(hour: hour)
        let isSelected = selectedHourIndex == index
        
        return Button {
            withAnimation(.spring(response: 0.25)) {
                if selectedHourIndex == index {
                    selectedHourIndex = nil
                } else {
                    selectedHourIndex = index
                }
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
    
    // MARK: - Daily Breakdown Cards
    private var dailyBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("DAILY BREAKDOWN & VOLLEYBALL TIPS")
                .font(.system(size: 11, weight: .black))
                .foregroundColor(.secondary)
                .tracking(0.5)
            
            ForEach(Array(weeklyDays.enumerated()), id: \.element.id) { index, day in
                dailyCard(for: day, index: index)
            }
        }
    }
    
    private func dailyCard(for day: DailyVolleyballWeather, index: Int) -> some View {
        let eval = criteria.evaluate(day: day)
        let isSelected = index == selectedDayIndex
        
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                HStack(spacing: 8) {
                    Text(day.conditionEmoji)
                        .font(.system(size: 24))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(day.fullDayTitle)
                            .font(.system(size: 15, weight: .black))
                            .foregroundColor(.white)
                        Text("\(day.conditionText) • High \(day.tempMax)°F, Low \(day.tempMin)°F")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Suitability Status Pill
                HStack(spacing: 5) {
                    Circle()
                        .fill(eval.suitability.dotColor)
                        .frame(width: 7, height: 7)
                    Text(eval.reason)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(eval.suitability.dotColor)
                        .lineLimit(1)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(eval.suitability.dotColor.opacity(0.12))
                .cornerRadius(999)
                .overlay(RoundedRectangle(cornerRadius: 999).stroke(eval.suitability.dotColor.opacity(0.3), lineWidth: 1))
            }
            
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
            
            // Volleyball Tip Box
            HStack(alignment: .top, spacing: 8) {
                Text("🏐")
                    .font(.system(size: 13))
                Text(eval.tip)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.85))
                    .lineSpacing(2)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.04))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(eval.suitability.dotColor.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(14)
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
        "Capitola Beach",
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

