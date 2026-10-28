import SwiftUI

public struct SmartForecastsSheet: View {
    @Binding var minTemp: Int
    @Binding var maxTemp: Int
    @Binding var maxWind: Int
    @Binding var maxUV: Double
    
    let day: DailyVolleyballWeather?
    var onSave: (() -> Void)? = nil
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPreset: SmartForecastPreset = .primeDoubles
    
    // Working state
    @State private var localMinTemp: Int
    @State private var localMaxTemp: Int
    @State private var localMaxWind: Int
    @State private var localMaxUV: Double
    
    public init(
        minTemp: Binding<Int>,
        maxTemp: Binding<Int>,
        maxWind: Binding<Int>,
        maxUV: Binding<Double>,
        day: DailyVolleyballWeather?,
        onSave: (() -> Void)? = nil
    ) {
        self._minTemp = minTemp
        self._maxTemp = maxTemp
        self._maxWind = maxWind
        self._maxUV = maxUV
        self.day = day
        self.onSave = onSave
        
        self._localMinTemp = State(initialValue: minTemp.wrappedValue)
        self._localMaxTemp = State(initialValue: maxTemp.wrappedValue)
        self._localMaxWind = State(initialValue: maxWind.wrappedValue)
        self._localMaxUV = State(initialValue: maxUV.wrappedValue)
    }
    
    private var currentCriteria: VolleyballCriteria {
        VolleyballCriteria(
            minTemp: localMinTemp,
            maxTemp: localMaxTemp,
            maxWind: localMaxWind,
            maxUV: localMaxUV
        )
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Beach Volleyball Play Style Presets
                    presetChipsRow
                    
                    // Step 1: String together multiple conditions
                    stepOneSection
                    
                    Divider().background(Color.white.opacity(0.12))
                    
                    // Step 2: We'll highlight when those conditions are met
                    stepTwoSection
                    
                    // Footer & Action Button
                    footerSection
                }
                .padding(18)
            }
            .background(Color(red: 0.09, green: 0.11, blue: 0.16).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.cyan)
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Beach Volleyball Smart Forecast")
                        .font(.system(size: 15, weight: .black))
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    // MARK: - Beach Volleyball Play Style Presets Row
    private var presetChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SmartForecastPreset.allCases) { preset in
                    let isSelected = selectedPreset == preset
                    Button {
                        selectedPreset = preset
                        localMinTemp = preset.defaultCriteria.minTemp
                        localMaxTemp = preset.defaultCriteria.maxTemp
                        localMaxWind = preset.defaultCriteria.maxWind
                        localMaxUV = preset.defaultCriteria.maxUV
                    } label: {
                        HStack(spacing: 6) {
                            Text(preset.icon)
                            Text(preset.rawValue)
                                .font(.system(size: 12, weight: .bold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(isSelected ? Color.cyan.opacity(0.2) : Color.white.opacity(0.06))
                        .foregroundColor(isSelected ? .cyan : Color.white.opacity(0.8))
                        .cornerRadius(999)
                        .overlay(
                            RoundedRectangle(cornerRadius: 999)
                                .stroke(isSelected ? Color.cyan.opacity(0.6) : Color.white.opacity(0.1), lineWidth: 1)
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Step 1: String Together Multiple Conditions
    private var stepOneSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Text("1")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(Color.white.opacity(0.4))
                
                Text("String together\nbeach volleyball conditions")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .lineSpacing(2)
            }
            
            // Equation Row: [TEMPS] + [WIND] + [UV] = [ACTIVITY]
            HStack(spacing: 6) {
                conditionBox(
                    icon: "thermometer.medium",
                    label: "TEMPS",
                    value: "\(localMinTemp)° - \(localMaxTemp)°F",
                    color: .orange
                )
                
                Text("+")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.4))
                
                conditionBox(
                    icon: "wind",
                    label: "WIND",
                    value: "0 - \(localMaxWind) mph",
                    color: .cyan
                )
                
                Text("+")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.4))
                
                conditionBox(
                    icon: "sun.max.fill",
                    label: "UV",
                    value: "0 - \(String(format: "%.1f", localMaxUV))",
                    color: .yellow
                )
                
                Text("=")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.4))
                
                // Activity Circle Badge
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 50, height: 50)
                            .shadow(color: Color.black.opacity(0.3), radius: 4)
                            .overlay(Circle().stroke(Color.cyan, lineWidth: 2))
                        
                        Text(selectedPreset.icon)
                            .font(.system(size: 24))
                    }
                    
                    Text(selectedPreset.label)
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
            }
            
            // Sliders Drawer
            VStack(spacing: 12) {
                // Temp
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("🌡️ Temperature Range")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(localMinTemp)°F – \(localMaxTemp)°F")
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(.orange)
                    }
                    HStack(spacing: 8) {
                        Stepper("Min \(localMinTemp)°", value: $localMinTemp, in: 45...max(45, localMaxTemp - 5))
                            .labelsHidden()
                        Spacer()
                        Stepper("Max \(localMaxTemp)°", value: $localMaxTemp, in: min(95, localMinTemp + 5)...95)
                            .labelsHidden()
                    }
                }
                
                // Wind
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("💨 Max Wind Speed")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        Text("Below \(localMaxWind) mph")
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(.cyan)
                    }
                    Slider(value: Binding(get: { Double(localMaxWind) }, set: { localMaxWind = Int($0) }), in: 5...25, step: 1)
                        .tint(.cyan)
                }
                
                // UV
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("☀️ Max UV Index")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        Text("Below \(String(format: "%.1f", localMaxUV))")
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(.yellow)
                    }
                    Slider(value: $localMaxUV, in: 1...11, step: 0.5)
                        .tint(.yellow)
                }
            }
            .padding(12)
            .background(Color.black.opacity(0.3))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
        }
    }
    
    private func conditionBox(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(red: 0.88, green: 0.91, blue: 0.95))
                    .frame(width: 50, height: 50)
                    .shadow(color: Color.black.opacity(0.3), radius: 3)
                
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(Color(red: 0.15, green: 0.18, blue: 0.25))
            }
            
            Text(label)
                .font(.system(size: 8, weight: .black))
                .foregroundColor(.white)
                .tracking(0.5)
            
            Text(value)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(Color.white.opacity(0.6))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Step 2: We'll highlight when conditions are met
    private var stepTwoSection: some View {
        let daylight = day?.daylightHours ?? []
        let windowInfo = currentCriteria.calculateBestPlayingWindowDetails(daylightHours: daylight)
        
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Text("2")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(Color.white.opacity(0.4))
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("We'll")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        Text("highlight")
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(.yellow)
                        Text("when those")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    Text("conditions are met.")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            
            // The Live Highlight Bar vs Muted Dot Timeline Chart
            VStack(spacing: 8) {
                HStack(alignment: .bottom, spacing: 3) {
                    if daylight.isEmpty {
                        Text("No daytime hourly data available.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, minHeight: 60)
                    } else {
                        ForEach(daylight, id: \.id) { hour in
                            let eval = currentCriteria.evaluate(hour: hour)
                            let isMatch = eval.suitability == .good
                            let isFair = eval.suitability == .fair
                            
                            VStack {
                                Spacer()
                                if isMatch || isFair {
                                    // Highlighted rounded vertical bar
                                    let barHeight: CGFloat = isMatch ? CGFloat(min(70, max(35, (hour.temp - 50) * 2 + 25))) : 28
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(
                                            isMatch ?
                                            LinearGradient(colors: [Color.yellow, Color.orange], startPoint: .top, endPoint: .bottom) :
                                            LinearGradient(colors: [Color.yellow.opacity(0.8), Color.orange.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                                        )
                                        .frame(maxWidth: 12, minHeight: barHeight, maxHeight: barHeight)
                                        .shadow(color: isMatch ? Color.orange.opacity(0.6) : .clear, radius: 4)
                                } else {
                                    // Muted circular dot
                                    Circle()
                                        .fill(Color.white.opacity(0.25))
                                        .frame(width: 5, height: 5)
                                        .padding(.bottom, 2)
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: 75)
                        }
                    }
                }
                .padding(.horizontal, 6)
                .padding(.bottom, 4)
                .overlay(
                    Rectangle()
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 1),
                    alignment: .bottom
                )
                
                // Time axis markers
                if !daylight.isEmpty {
                    HStack {
                        Text(daylight.first?.hourLabel.replacingOccurrences(of: " ", with: "") ?? "7A")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color.white.opacity(0.5))
                        Spacer()
                        if daylight.count > 4 {
                            Text(daylight[daylight.count / 2].hourLabel.replacingOccurrences(of: " ", with: ""))
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(Color.white.opacity(0.5))
                            Spacer()
                        }
                        Text(daylight.last?.hourLabel.replacingOccurrences(of: " ", with: "") ?? "7P")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color.white.opacity(0.5))
                    }
                    .padding(.horizontal, 4)
                }
                
                // Day name
                Text(day?.dayName.uppercased() ?? "TODAY")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(Color.white.opacity(0.4))
                    .tracking(1)
            }
            .padding(14)
            .background(Color.black.opacity(0.35))
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
            
            // Highlighted window pill
            if windowInfo.suitability != .poor {
                HStack(spacing: 6) {
                    Text("🌟")
                        .font(.system(size: 12))
                    Text("Highlighted Window: \(windowInfo.windowText)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.yellow)
                    Spacer()
                    Text(windowInfo.summaryText)
                        .font(.system(size: 9))
                        .foregroundColor(Color.white.opacity(0.65))
                }
                .padding(10)
                .background(Color.yellow.opacity(0.12))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.yellow.opacity(0.25), lineWidth: 1))
            }
        }
    }
    
    // MARK: - Footer
    private var footerSection: some View {
        VStack(spacing: 12) {
            Text("Personalized weather and wind forecasts for beach volleyball.")
                .font(.system(size: 13))
                .foregroundColor(Color.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                minTemp = localMinTemp
                maxTemp = localMaxTemp
                maxWind = localMaxWind
                maxUV = localMaxUV
                onSave?()
                dismiss()
            } label: {
                Text("Apply Beach Volleyball Criteria")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(colors: [Color.blue, Color.cyan], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(12)
            }
        }
        .padding(.top, 8)
    }
}
