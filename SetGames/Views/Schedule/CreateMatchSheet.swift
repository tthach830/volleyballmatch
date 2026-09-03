import SwiftUI

public struct CreateMatchSheet: View {
    @ObservedObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var targetRating: RatingTier = .b
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
            _targetRating = State(initialValue: user.rating)
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
                    
                    Picker("Skill Level Tier", selection: $targetRating) {
                        ForEach(RatingTier.allCases, id: \.self) { tier in
                            Text(tier.rawValue).tag(tier)
                        }
                    }
                    
                    Toggle(isOn: $isLevelLocked) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Level Locked")
                                .font(.system(size: 15, weight: .semibold))
                            Text("Only \(targetRating.rawValue) players can join this match")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                    .tint(.orange)
                    
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
                        let defaultTitle = "\(targetRating.rawValue) Match"
                        let finalTitle = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? defaultTitle : title.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        dataManager.createMatch(
                            title: finalTitle,
                            targetRating: targetRating,
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
}
