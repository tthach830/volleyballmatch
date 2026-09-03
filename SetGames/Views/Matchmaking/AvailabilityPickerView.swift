import SwiftUI

public struct AvailabilityPickerView: View {
    @ObservedObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedDate: Date = Date().addingTimeInterval(86400)
    @State private var startTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date().addingTimeInterval(86400)) ?? Date()
    @State private var endTime: Date = Calendar.current.date(bySettingHour: 11, minute: 30, second: 0, of: Date().addingTimeInterval(86400)) ?? Date()
    @State private var selectedBeach: String = "Main Beach"
    @State private var customBeachName: String = ""
    @State private var selectedTiers: Set<RatingTier> = [.b, .a]
    @State private var allowPlusMinus: Bool = true
    @State private var isRecurring: Bool = false
    
    private var effectiveBeach: String {
        if selectedBeach == CourtLocations.customOption {
            let trimmed = customBeachName.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? "Custom Court" : trimmed
        }
        return selectedBeach
    }
    
    public init(dataManager: DataManager) {
        self.dataManager = dataManager
        if let user = dataManager.currentUser {
            _selectedTiers = State(initialValue: [user.rating])
            _selectedBeach = State(initialValue: user.homeBeach)
        }
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section("Date & Time Window") {
                    DatePicker("Play Date", selection: $selectedDate, in: Date()..., displayedComponents: .date)
                    DatePicker("Start Window", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("End Window", selection: $endTime, displayedComponents: .hourAndMinute)
                    Toggle("Recurring Every Week", isOn: $isRecurring)
                }
                
                Section("Court Location") {
                    Picker("Preferred Beach", selection: $selectedBeach) {
                        ForEach(CourtLocations.allOptions, id: \.self) { beach in
                            Text(beach).tag(beach)
                        }
                    }
                    
                    if selectedBeach == CourtLocations.customOption {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("CUSTOM COURT NAME")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.orange)
                            
                            TextField("e.g. Seabright Beach, 26th Ave", text: $customBeachName)
                        }
                    }
                }
                
                Section("Accepted Skill Levels") {
                    Text("Select which rating tiers you are comfortable playing with:")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    ForEach(RatingTier.allCases) { tier in
                        Button {
                            if selectedTiers.contains(tier) {
                                if selectedTiers.count > 1 {
                                    selectedTiers.remove(tier)
                                }
                            } else {
                                selectedTiers.insert(tier)
                            }
                        } label: {
                            HStack {
                                RatingBadge(rating: tier, size: .small)
                                Spacer()
                                if selectedTiers.contains(tier) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                    }
                    
                    Toggle("Allow ±1 Tier Tolerance", isOn: $allowPlusMinus)
                }
            }
            .navigationTitle("Set Free Window")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save Window") {
                        dataManager.addAvailability(
                            date: selectedDate,
                            startTime: startTime,
                            endTime: endTime,
                            beach: effectiveBeach,
                            tiers: Array(selectedTiers),
                            allowPlusMinus: allowPlusMinus
                        )
                        // Auto-run matchmaking to instantly find matches if possible!
                        _ = dataManager.runAutoMatchmaking()
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                }
            }
        }
    }
}
