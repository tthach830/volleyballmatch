import SwiftUI

public struct RecordScoreSheet: View {
    @ObservedObject var dataManager: DataManager
    let game: SetGame
    @Environment(\.dismiss) private var dismiss
    
    @State private var set1T1: Int = 21
    @State private var set1T2: Int = 18
    @State private var set2T1: Int = 19
    @State private var set2T2: Int = 21
    @State private var set3T1: Int = 15
    @State private var set3T2: Int = 12
    @State private var playThreeSets: Bool = true
    
    public init(dataManager: DataManager, game: SetGame) {
        self.dataManager = dataManager
        self.game = game
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                // Match Header
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(game.title)
                            .font(.system(size: 17, weight: .bold))
                        HStack {
                            Text(game.courtLocation)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(game.courtNumber)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // Teams Display
                Section("Teams") {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("TEAM 1")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.orange)
                            ForEach(team1Players) { p in
                                Text(p.name)
                                    .font(.system(size: 14, weight: .medium))
                            }
                        }
                        Spacer()
                        Text("VS")
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(.secondary)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("TEAM 2")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.blue)
                            ForEach(team2Players) { p in
                                Text(p.name)
                                    .font(.system(size: 14, weight: .medium))
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }
                
                // Set 1
                Section("Set 1 Score (to 21)") {
                    HStack {
                        Text("Team 1: \(set1T1)")
                            .font(.system(size: 15, weight: .bold))
                        Spacer()
                        Stepper("", value: $set1T1, in: 0...40)
                    }
                    HStack {
                        Text("Team 2: \(set1T2)")
                            .font(.system(size: 15, weight: .bold))
                        Spacer()
                        Stepper("", value: $set1T2, in: 0...40)
                    }
                }
                
                // Set 2
                Section("Set 2 Score (to 21)") {
                    HStack {
                        Text("Team 1: \(set2T1)")
                            .font(.system(size: 15, weight: .bold))
                        Spacer()
                        Stepper("", value: $set2T1, in: 0...40)
                    }
                    HStack {
                        Text("Team 2: \(set2T2)")
                            .font(.system(size: 15, weight: .bold))
                        Spacer()
                        Stepper("", value: $set2T2, in: 0...40)
                    }
                }
                
                // Set 3 (Tiebreaker)
                Section {
                    Toggle("Required 3rd Set Tiebreaker", isOn: $playThreeSets)
                    
                    if playThreeSets {
                        HStack {
                            Text("Team 1: \(set3T1)")
                                .font(.system(size: 15, weight: .bold))
                            Spacer()
                            Stepper("", value: $set3T1, in: 0...25)
                        }
                        HStack {
                            Text("Team 2: \(set3T2)")
                                .font(.system(size: 15, weight: .bold))
                            Spacer()
                            Stepper("", value: $set3T2, in: 0...25)
                        }
                    }
                } header: {
                    Text("Set 3 Tiebreaker (to 15)")
                }
            }
            .navigationTitle("Record Match Score")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save Result") {
                        var scores = [
                            SetScore(setNumber: 1, team1Score: set1T1, team2Score: set1T2),
                            SetScore(setNumber: 2, team1Score: set2T1, team2Score: set2T2)
                        ]
                        if playThreeSets {
                            scores.append(SetScore(setNumber: 3, team1Score: set3T1, team2Score: set3T2))
                        }
                        
                        let t1Wins = scores.filter { $0.team1Score > $0.team2Score }.count
                        let t2Wins = scores.filter { $0.team2Score > $0.team1Score }.count
                        let winner = t1Wins >= t2Wins ? 1 : 2
                        
                        dataManager.recordScore(
                            gameId: game.id,
                            winningTeam: winner,
                            setScores: scores
                        )
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                }
            }
        }
    }
    
    private var team1Players: [Player] {
        game.team1PlayerIds.compactMap { pid in
            dataManager.players.first(where: { $0.id == pid })
        }
    }
    
    private var team2Players: [Player] {
        game.team2PlayerIds.compactMap { pid in
            dataManager.players.first(where: { $0.id == pid })
        }
    }
}
