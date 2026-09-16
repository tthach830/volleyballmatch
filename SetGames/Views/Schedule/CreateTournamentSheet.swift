import SwiftUI

public struct CreateTournamentSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var dataManager: DataManager
    let tournamentToEdit: Tournament?
    
    @State private var title: String
    @State private var location: String
    @State private var selectedDate: Date
    @State private var courtsString: String
    @State private var maxTeamsPerDivision: Int
    @State private var selectedDivisions: Set<TournamentDivisionCategory>
    @State private var notes: String
    @State private var selectedTeamFormat: TournamentTeamFormat
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    public init(dataManager: DataManager, tournamentToEdit: Tournament? = nil) {
        self.dataManager = dataManager
        self.tournamentToEdit = tournamentToEdit
        
        if let t = tournamentToEdit {
            _title = State(initialValue: t.title)
            _location = State(initialValue: t.location)
            _selectedDate = State(initialValue: t.date)
            _courtsString = State(initialValue: t.courts.joined(separator: ", "))
            _maxTeamsPerDivision = State(initialValue: t.maxTeamsPerDivision)
            _selectedDivisions = State(initialValue: Set(t.allowedDivisions))
            _notes = State(initialValue: t.notes)
            _selectedTeamFormat = State(initialValue: t.teamFormat)
        } else {
            _title = State(initialValue: "")
            _location = State(initialValue: "Main Beach")
            _selectedDate = State(initialValue: Date().addingTimeInterval(86400 * 3))
            _courtsString = State(initialValue: "Court #1, Court #2, Court #3, Court #4")
            _maxTeamsPerDivision = State(initialValue: 8)
            _selectedDivisions = State(initialValue: Set(TournamentDivisionCategory.allCases))
            _notes = State(initialValue: "Double elimination beach doubles tournament. Rally score to 21, switch sides every 7 points.")
            _selectedTeamFormat = State(initialValue: .doubles2v2)
        }
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section("Tournament Info") {
                    TextField("Tournament Title (e.g. Santa Cruz Beach Open)", text: $title)
                    
                    Picker("Beach Location", selection: $location) {
                        Text("Main Beach (Santa Cruz)").tag("Main Beach")
                        Text("Harbor Beach (Santa Cruz)").tag("Harbor Beach")
                        Text("Capitola Beach").tag("Capitola Beach")
                        Text("Twin Lakes Beach").tag("Twin Lakes Beach")
                        Text("Manhattan Beach Pier").tag("Manhattan Beach Pier")
                        Text("Hermosa Beach 22nd St").tag("Hermosa Beach 22nd St")
                    }
                    
                    DatePicker("Date & Start Time", selection: $selectedDate, in: Date()...)
                    
                    TextField("Courts (comma-separated)", text: $courtsString)
                    
                    Stepper("Max Teams per Division: \(maxTeamsPerDivision)", value: $maxTeamsPerDivision, in: 4...32, step: 4)
                }
                

                Section("Divisions Offered") {
                    ForEach(TournamentDivisionCategory.allCases) { div in
                        Toggle(isOn: Binding(
                            get: { selectedDivisions.contains(div) },
                            set: { isSelected in
                                if isSelected {
                                    selectedDivisions.insert(div)
                                } else {
                                    selectedDivisions.remove(div)
                                }
                            }
                        )) {
                            HStack {
                                Text(div.icon)
                                Text(div.displayName)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }
                
                Section("Format & Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle(tournamentToEdit != nil ? "Edit Tournament" : "Host New Tournament")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(tournamentToEdit != nil ? "Save" : "Create") {
                        saveTournament()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                }
            }
            .alert("Notice", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func saveTournament() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTitle.isEmpty {
            alertMessage = "Please enter a title for the tournament."
            showAlert = true
            return
        }
        
        if selectedDivisions.isEmpty {
            alertMessage = "Please select at least one division."
            showAlert = true
            return
        }
        
        let courts = courtsString.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        if let existing = tournamentToEdit {
            let result = dataManager.updateTournament(
                id: existing.id,
                title: trimmedTitle,
                date: selectedDate,
                location: location,
                courts: courts.isEmpty ? ["Court #1", "Court #2"] : courts,
                allowedDivisions: Array(selectedDivisions),
                maxTeamsPerDivision: maxTeamsPerDivision,
                notes: notes,
                teamFormat: selectedTeamFormat
            )
            if !result.success {
                alertMessage = result.message
                showAlert = true
                return
            }
        } else {
            dataManager.createTournament(
                title: trimmedTitle,
                date: selectedDate,
                location: location,
                courts: courts.isEmpty ? ["Court #1", "Court #2"] : courts,
                allowedDivisions: Array(selectedDivisions),
                maxTeamsPerDivision: maxTeamsPerDivision,
                notes: notes,
                teamFormat: selectedTeamFormat
            )
        }
        
        dismiss()
    }
}
