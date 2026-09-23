import SwiftUI

public struct VolleyballWeatherView: View {
    @ObservedObject var dataManager: DataManager
    @StateObject private var weatherService = WeatherService.shared
    
    @State private var selectedCourt: String = "Main Beach"
    @State private var weeklyDays: [DailyVolleyballWeather] = []
    @State private var selectedDayIndex: Int = 0
    @State private var isLoading: Bool = true
    @State private var showSettings: Bool = false
    
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
                    Button {
                        Task { await loadForecast() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.orange)
                    }
                }
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
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(weeklyDays.enumerated()), id: \.element.id) { index, day in
                            chartColumn(for: day, index: index)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(14)
        .background(Color(red: 0.12, green: 0.14, blue: 0.20))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
    
    // MARK: - Chart Column for Each Day
    private func chartColumn(for day: DailyVolleyballWeather, index: Int) -> some View {
        let eval = criteria.evaluate(day: day)
        let isSelected = index == selectedDayIndex
        
        return Button {
            withAnimation(.spring(response: 0.25)) {
                selectedDayIndex = index
            }
        } label: {
            VStack(spacing: 6) {
                // Day name & date
                Text(day.dayName)
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(isSelected ? .orange : .white)
                Text(day.dateFormatted)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary)
                
                // Suitability Dot with Glow Ring
                ZStack {
                    Circle()
                        .fill(eval.suitability.dotColor.opacity(0.25))
                        .frame(width: 22, height: 22)
                    Circle()
                        .fill(eval.suitability.dotColor)
                        .frame(width: 10, height: 10)
                        .shadow(color: eval.suitability.dotColor.opacity(0.8), radius: 4)
                }
                
                // Condition Emoji
                Text(day.conditionEmoji)
                    .font(.system(size: 18))
                
                // High Temp
                Text("\(day.tempMax)°")
                    .font(.system(size: 13, weight: .black))
                    .foregroundColor(.white)
                
                // Proportional Temperature Bar
                RoundedRectangle(cornerRadius: 4)
                    .fill(LinearGradient(colors: [.red, .orange, .blue], startPoint: .top, endPoint: .bottom))
                    .frame(width: 6, height: max(20, min(65, CGFloat(day.tempMax - 40) * 1.5)))
                
                // Low Temp
                Text("\(day.tempMin)°")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                
                // Wind & UV Chips
                VStack(spacing: 3) {
                    Text("💨\(day.windMax)m")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.cyan)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.cyan.opacity(0.12))
                        .cornerRadius(4)
                    Text("☀️\(String(format: "%.0f", day.uvMax))")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.yellow.opacity(0.12))
                        .cornerRadius(4)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 8)
            .frame(width: 68)
            .background(isSelected ? Color.orange.opacity(0.15) : Color.white.opacity(0.04))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.orange : Color.white.opacity(0.08), lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
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
