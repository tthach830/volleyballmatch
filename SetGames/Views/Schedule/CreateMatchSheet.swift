import SwiftUI

public struct CreateMatchSheet: View {
    @ObservedObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var selectedRatings: Set<RatingTier> = [.b]
    @State private var format: GameFormat = .bestOfThree
    @State private var maxPlayers: Int = 4
    @State private var courtLocation: String = "Main Beach"
    @State private var customCourtLocation: String = ""
    @State private var courtNumber: String = "Court #1"
    @State private var scheduledDate: Date = Date().addingTimeInterval(3600 * 24)
    @State private var isLevelLocked: Bool = true
    @State private var notes: String = "Bring an official Wilson or Molten beach volleyball!"
    
    public init(dataManager: DataManager) {
        self.dataManager = dataManager
        if let user = dataManager.currentUser {
            _selectedRatings = State(initialValue: [user.rating])
            _courtLocation = State(initialValue: user.homeBeach.isEmpty ? "Main Beach" : user.homeBeach)
        }
    }
    
    private var effectiveCourt: String {
        if courtLocation == CourtLocations.customOption {
            let trimmed = customCourtLocation.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? "Custom Court" : trimmed
        }
        return courtLocation
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section("MATCH INFORMATION") {
                    TextField("e.g. Sunset Doubles Clash", text: $title)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 8) {
                                    Text("Skill Level Tier")
                                        .font(.system(size: 15, weight: .semibold))
                                    
                                    HStack(spacing: 4) {
                                        Image(systemName: isLevelLocked ? "lock.fill" : "lock.open")
                                            .font(.system(size: 10))
                                        Text("Level Locked")
                                            .font(.system(size: 12, weight: .bold))
                                    }
                                    .foregroundColor(isLevelLocked ? .orange : .secondary)
                                }
                                
                                Text("Only matching tier players can join")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $isLevelLocked)
                                .labelsHidden()
                                .tint(.orange)
                        }
                        .padding(.vertical, 2)
                        
                        Divider()
                        
                        VStack(spacing: 8) {
                            ForEach(RatingTier.allCases, id: \.self) { tier in
                                tierCheckboxRow(tier: tier)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    
                    HStack {
                        Text("Max. Players")
                        Spacer()
                        TextField("4", value: $maxPlayers, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(UIColor.tertiarySystemFill))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    
                    Picker("Match Format", selection: $format) {
                        ForEach(GameFormat.allCases, id: \.self) { fmt in
                            Text(fmt.rawValue).tag(fmt)
                        }
                    }
                    
                    if format == .kingOfTheBeach {
                        VStack(alignment: .leading, spacing: 4) {
                            let courts = max(1, maxPlayers / 4)
                            HStack(spacing: 4) {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(.orange)
                                Text("King of the Court: \(courts) Court\(courts > 1 ? "s" : "") Needed (\(courts * 4) Players)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.orange)
                            }
                            if maxPlayers % 4 != 0 {
                                Text("⚠️ King of the Court requires 4 players per court (e.g. 8, 12, 16). \(maxPlayers % 4) player(s) will be on bye.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.red)
                            } else {
                                Text("✓ Players 1–4 on Court 1, 5–8 on Court 2, etc. Each court plays 3 rotating sets with individual scoring.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                
                Section("LOCATION & COURT") {
                    Picker("Beach Location", selection: $courtLocation) {
                        ForEach(CourtLocations.allOptions, id: \.self) { loc in
                            Text(loc).tag(loc)
                        }
                    }
                    
                    if courtLocation == CourtLocations.customOption {
                        TextField("Enter custom court location", text: $customCourtLocation)
                    }
                    
                    TextField("Court # (e.g. Court #1)", text: $courtNumber)
                }
                
                Section("SCHEDULED DATE & TIME") {
                    DatePicker("Game Time", selection: $scheduledDate, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section("NOTES FOR PLAYERS") {
                    TextField("Warmup instructions, ball details...", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Host New Match")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Host Match") {
                        let chosenRatings = RatingTier.allCases.filter { selectedRatings.contains($0) }
                        let primaryRating = chosenRatings.first ?? .b
                        let defaultTitle = chosenRatings.count > 1 ? "\(chosenRatings.map { $0.rawValue }.joined(separator: "/")) Match" : "\(primaryRating.rawValue) Match"
                        let finalTitle = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? defaultTitle : title.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        dataManager.createMatch(
                            title: finalTitle,
                            targetRating: primaryRating,
                            allowedRatings: chosenRatings,
                            format: format,
                            courtLocation: effectiveCourt,
                            courtNumber: courtNumber.isEmpty ? "Court #1" : courtNumber,
                            scheduledDate: scheduledDate,
                            isLevelLocked: isLevelLocked,
                            maxPlayers: maxPlayers,
                            notes: notes
                        )
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                }
            }
        }
    }
    
    @ViewBuilder
    private func tierCheckboxRow(tier: RatingTier) -> some View {
        let isChecked = selectedRatings.contains(tier)
        Button {
            if isChecked {
                if selectedRatings.count > 1 {
                    selectedRatings.remove(tier)
                }
            } else {
                selectedRatings.insert(tier)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isChecked ? .orange : Color(UIColor.tertiaryLabel))
                
                RatingBadge(rating: tier, size: .small)
                
                Text(tier.rawValue)
                    .font(.system(size: 14, weight: isChecked ? .bold : .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(tierSummary(tier))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private func tierSummary(_ tier: RatingTier) -> String {
        switch tier {
        case .novice: return "Beginner (~1100)"
        case .intermediate: return "Casual (~1350)"
        case .b: return "Solid (~1550)"
        case .a: return "Comp (~1800)"
        case .aa: return "Advanced (~2100)"
        case .open: return "Pro (~2300)"
        }
    }
}
