import SwiftUI

public struct EditMatchSheet: View {
    @ObservedObject var dataManager: DataManager
    let game: SetGame
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String
    @State private var targetRating: RatingTier
    @State private var format: GameFormat
    @State private var maxPlayers: Int
    @State private var courtLocation: String
    @State private var customCourtLocation: String = ""
    @State private var courtNumber: String
    @State private var scheduledDate: Date
    @State private var isLevelLocked: Bool
    @State private var notes: String
    @State private var alertMessage: String? = nil
    @State private var showAlert: Bool = false
    
    public init(dataManager: DataManager, game: SetGame) {
        self.dataManager = dataManager
        self.game = game
        _title = State(initialValue: game.title)
        _targetRating = State(initialValue: game.targetRating)
        _format = State(initialValue: game.format)
        _maxPlayers = State(initialValue: game.maxPlayers)
        _courtLocation = State(initialValue: game.courtLocation)
        _courtNumber = State(initialValue: game.courtNumber)
        _scheduledDate = State(initialValue: game.scheduledDate)
        _isLevelLocked = State(initialValue: game.isLevelLocked)
        _notes = State(initialValue: game.notes)
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
                    TextField("Match Title", text: $title)
                    
                    Picker("Skill Level Tier", selection: $targetRating) {
                        ForEach(RatingTier.allCases, id: \.self) { tier in
                            Text(tier.rawValue).tag(tier)
                        }
                    }
                    
                    Toggle(isOn: $isLevelLocked) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Level Locked")
                                .font(.system(size: 15, weight: .semibold))
                            Text("Only players rated \(targetRating.rawValue) can join this match")
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
                    
                    TextField("Court Number (e.g. Court #2)", text: $courtNumber)
                }
                
                Section("DATE & TIME") {
                    DatePicker("Game Time", selection: $scheduledDate, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section("MATCH DETAILS & NOTES") {
                    TextField("Rules, ball preference, warmup notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...5)
                }
            }
            .navigationTitle("Edit Match Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let res = dataManager.updateGamePreferences(
                            gameId: game.id,
                            title: title,
                            targetRating: targetRating,
                            format: format,
                            maxPlayers: maxPlayers,
                            scheduledDate: scheduledDate,
                            courtLocation: effectiveCourt,
                            courtNumber: courtNumber.isEmpty ? "Court #1" : courtNumber,
                            isLevelLocked: isLevelLocked,
                            notes: notes
                        )
                        if res.success {
                            dismiss()
                        } else {
                            alertMessage = res.message
                            showAlert = true
                        }
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                }
            }
            .alert("Update Preferences", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage ?? "")
            }
        }
    }
}
