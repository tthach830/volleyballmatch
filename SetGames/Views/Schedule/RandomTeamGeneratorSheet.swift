import SwiftUI

public enum TournamentFormatMode: String, CaseIterable, Identifiable {
    case kingOfTheCourt = "👑 King of the Court"
    case socialMixer = "🎲 Continuous Mixer"
    
    public var id: String { rawValue }
}

public struct PoolPlayer: Identifiable, Hashable {
    public let id: UUID
    public var name: String
    
    public init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

public struct GeneratedMatch: Identifiable, Hashable {
    public let id: UUID = UUID()
    public var matchNumber: Int
    public var courtNumber: String = "Court #1"
    public var team1Player1: PoolPlayer
    public var team1Player2: PoolPlayer
    public var team2Player1: PoolPlayer
    public var team2Player2: PoolPlayer
    public var restingPlayers: [PoolPlayer] = []
    public var team1Score: String = ""
    public var team2Score: String = ""
    public var isCompleted: Bool = false
    
    public var team1Title: String { "\(team1Player1.name) & \(team1Player2.name)" }
    public var team2Title: String { "\(team2Player1.name) & \(team2Player2.name)" }
}

public struct KingPlayerStanding: Identifiable, Hashable {
    public let id: UUID
    public var name: String
    public var courtNumber: Int
    public var wins: Int = 0
    public var losses: Int = 0
    public var pointsFor: Int = 0
    public var pointsAgainst: Int = 0
    
    public var pointDifferential: Int { pointsFor - pointsAgainst }
    public var formattedRecord: String { "\(wins)W - \(losses)L" }
}

public struct GeneratedMatchRow: View {
    @Binding var match: GeneratedMatch
    var onScoreChanged: (() -> Void)? = nil
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    Text("SET \(match.matchNumber)")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.orange)
                    Text("•")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text(match.courtNumber)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                Spacer()
                if match.isCompleted {
                    Text("SCORED ✓")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.green)
                }
            }
            
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Team 1")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                    Text(match.team1Title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("VS")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Team 2")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                    Text(match.team2Title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            
            // Resting players
            if !match.restingPlayers.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "pause.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text("Resting / Bye: \(match.restingPlayers.map { $0.name }.joined(separator: ", "))")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            // Score Input
            HStack(spacing: 10) {
                TextField("T1 Pts", text: $match.team1Score)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 65)
                    .onChange(of: match.team1Score) { _ in
                        updateCompletion()
                    }
                
                Text("–")
                    .font(.headline)
                
                TextField("T2 Pts", text: $match.team2Score)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 65)
                    .onChange(of: match.team2Score) { _ in
                        updateCompletion()
                    }
                
                Spacer()
                
                if !match.team1Score.isEmpty && !match.team2Score.isEmpty {
                    Button("Done") {
                        match.isCompleted = true
                        onScoreChanged?()
                    }
                    .font(.system(size: 12, weight: .bold))
                    .buttonStyle(.bordered)
                    .tint(.green)
                }
            }
        }
        .padding(.vertical, 6)
    }
    
    private func updateCompletion() {
        if !match.team1Score.isEmpty && !match.team2Score.isEmpty {
            match.isCompleted = true
        } else {
            match.isCompleted = false
        }
        onScoreChanged?()
    }
}

public struct RandomTeamGeneratorSheet: View {
    @ObservedObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var mode: TournamentFormatMode = .kingOfTheCourt
    @State private var playersList: [PoolPlayer] = []
    @State private var newPlayerName: String = ""
    @State private var numberOfGames: Int = 4
    @State private var courtLocation: String = "Main Beach"
    @State private var courtNumber: String = "Court #1"
    @State private var generatedMatches: [GeneratedMatch] = []
    @State private var alertMessage: String? = nil
    @State private var showAlert: Bool = false
    
    private let initialGameId: UUID?
    
    public init(dataManager: DataManager, initialGameId: UUID? = nil, initialPlayers: [Player]? = nil, initialBeach: String? = nil, initialFormat: GameFormat? = nil) {
        self.dataManager = dataManager
        self.initialGameId = initialGameId
        if let fmt = initialFormat, fmt == .kingOfTheBeach {
            _mode = State(initialValue: .kingOfTheCourt)
        } else {
            _mode = State(initialValue: .kingOfTheCourt)
        }
        
        if let players = initialPlayers, !players.isEmpty {
            var seenNamesCount: [String: Int] = [:]
            let pool = players.map { p -> PoolPlayer in
                let baseName = p.nickname.isEmpty ? p.name : p.nickname
                seenNamesCount[baseName, default: 0] += 1
                let displayName = (seenNamesCount[baseName]! > 1) ? "\(baseName) (\(seenNamesCount[baseName]!))" : baseName
                return PoolPlayer(id: p.id, name: displayName)
            }
            _playersList = State(initialValue: pool)
            let suggested = max(4, pool.count)
            _numberOfGames = State(initialValue: suggested)
        } else {
            _playersList = State(initialValue: [
                PoolPlayer(name: "Player 1"),
                PoolPlayer(name: "Player 2"),
                PoolPlayer(name: "Player 3"),
                PoolPlayer(name: "Player 4")
            ])
            _numberOfGames = State(initialValue: 4)
        }
        if let beach = initialBeach {
            _courtLocation = State(initialValue: beach)
        }
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                // Mode Selector
                Section {
                    Picker("Format", selection: $mode) {
                        ForEach(TournamentFormatMode.allCases) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    if mode == .kingOfTheCourt {
                        let courtCount = playersList.count / 4
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "crown.fill").foregroundColor(.orange)
                                Text("King of the Court: 4 Players Per Court")
                                    .font(.system(size: 13, weight: .bold))
                            }
                            if courtCount >= 1 {
                                Text("\(courtCount) Court\(courtCount > 1 ? "s" : "") Needed for \(courtCount * 4) players.")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.orange)
                                Text("Player 1–4 on Court 1, Player 5–8 on Court 2, etc. Individual points and records are tracked per player.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            if playersList.count % 4 != 0 {
                                Text("⚠️ \(playersList.count % 4) player(s) on bye/alternates. Add \(4 - (playersList.count % 4)) more player(s) for a full court.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.vertical, 2)
                    } else {
                        Text("Continuous social rotations across all \(playersList.count) players with an equitable resting queue.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Section 1: Player Pool
                Section {
                    ForEach($playersList) { $player in
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(Color.orange.opacity(0.15))
                                    .frame(width: 24, height: 24)
                                if let idx = playersList.firstIndex(where: { $0.id == player.id }) {
                                    Text("\(idx + 1)")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.orange)
                                }
                            }
                            
                            TextField("Player Name", text: $player.name)
                            
                            // Court assignment badge preview
                            if let idx = playersList.firstIndex(where: { $0.id == player.id }) {
                                let cNum = (idx / 4) + 1
                                Text("Court \(cNum)")
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.1))
                                    .foregroundColor(.orange)
                                    .clipShape(Capsule())
                            }
                            
                            if playersList.count > 4 {
                                Button {
                                    playersList.removeAll(where: { $0.id == player.id })
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 13))
                                        .foregroundColor(.red.opacity(0.8))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // Add new player row
                    HStack {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(.orange)
                        TextField("Add another player...", text: $newPlayerName)
                            .onSubmit {
                                addPlayer()
                            }
                        
                        if !newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Button("Add") {
                                addPlayer()
                            }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.orange)
                        }
                    }
                } header: {
                    HStack {
                        Text("PLAYERS POOL (\(playersList.count) PLAYERS)")
                        Spacer()
                        if playersList.count >= 4 {
                            Text("Ready")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.green)
                        } else {
                            Text("Need 4+ players")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // Section 2: Generation Settings
                Section("SETTINGS & GENERATION") {
                    if mode == .socialMixer {
                        Stepper("Number of Matches: \(numberOfGames)", value: $numberOfGames, in: 1...30)
                    }
                    
                    Picker("Beach Location", selection: $courtLocation) {
                        ForEach(CourtLocations.allOptions, id: \.self) { loc in
                            Text(loc).tag(loc)
                        }
                    }
                    
                    Button {
                        if mode == .kingOfTheCourt {
                            generateKingOfTheCourt()
                        } else {
                            generateMixerRotations()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Image(systemName: mode == .kingOfTheCourt ? "crown.fill" : "dice.fill")
                            if mode == .kingOfTheCourt {
                                let c = playersList.count / 4
                                Text("Generate King of the Court (\(c) Court\(c > 1 ? "s" : ""))")
                                    .fontWeight(.bold)
                            } else {
                                Text("Generate Matches for All \(playersList.count) Players")
                                    .fontWeight(.bold)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .disabled(playersList.count < 4)
                }
                
                // Section 3: Generated Tournament Matches & Leaderboards
                if !generatedMatches.isEmpty {
                    if mode == .kingOfTheCourt {
                        kingOfTheCourtResultsSection
                    } else {
                        socialMixerResultsSection
                    }
                    
                    Section {
                        Button {
                            saveAllMatchesToSchedule()
                        } label: {
                            HStack {
                                Spacer()
                                Image(systemName: "calendar.badge.plus")
                                Text(initialGameId != nil ? "Save Matches to This Game (\(generatedMatches.count))" : "Save All \(generatedMatches.count) Sets to Schedule")
                                    .fontWeight(.bold)
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                }
            }
            .navigationTitle(mode == .kingOfTheCourt ? "King of the Court" : "Random Team Rotations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert("Schedule Created", isPresented: $showAlert) {
                Button("OK") { dismiss() }
            } message: {
                Text(alertMessage ?? "")
            }
        }
    }
    
    // MARK: - King of the Court Results Section
    
    private var kingOfTheCourtResultsSection: some View {
        let courtCount = playersList.count / 4
        return ForEach(1...courtCount, id: \.self) { courtNum in
            let courtMatchesIndices = generatedMatches.indices.filter {
                generatedMatches[$0].courtNumber == "Court #\(courtNum)"
            }
            let courtMatches = courtMatchesIndices.map { generatedMatches[$0] }
            let courtPlayers = Array(playersList[((courtNum - 1) * 4) ..< min(courtNum * 4, playersList.count)])
            let standings = calculateStandings(for: courtPlayers, matches: courtMatches)
            
            Section {
                // Court Individual Leaderboard Card
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill").foregroundColor(.orange)
                            Text("COURT #\(courtNum) INDIVIDUAL STANDINGS")
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(.orange)
                        }
                        Spacer()
                        if let leader = standings.first, leader.wins > 0 {
                            Text("Leader: \(leader.name) 👑")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.orange)
                        }
                    }
                    
                    // Table Header
                    HStack {
                        Text("RANK / PLAYER")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("W-L")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                            .frame(width: 45, alignment: .trailing)
                        Text("PTS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                            .frame(width: 35, alignment: .trailing)
                        Text("DIFF")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                            .frame(width: 45, alignment: .trailing)
                    }
                    .padding(.horizontal, 6)
                    
                    Divider()
                    
                    // Standings Rows
                    ForEach(Array(standings.enumerated()), id: \.element.id) { rankIdx, player in
                        HStack {
                            HStack(spacing: 6) {
                                if rankIdx == 0 {
                                    Text("👑 1st")
                                        .font(.system(size: 11, weight: .black))
                                        .foregroundColor(.orange)
                                } else if rankIdx == 1 {
                                    Text("🥈 2nd")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.secondary)
                                } else if rankIdx == 2 {
                                    Text("🥉 3rd")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("4th")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.secondary)
                                }
                                Text(player.name)
                                    .font(.system(size: 12, weight: rankIdx == 0 ? .bold : .medium))
                                    .foregroundColor(rankIdx == 0 ? .primary : .secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Text(player.formattedRecord)
                                .font(.system(size: 11, weight: .semibold))
                                .frame(width: 45, alignment: .trailing)
                            Text("\(player.pointsFor)")
                                .font(.system(size: 11, weight: .bold))
                                .frame(width: 35, alignment: .trailing)
                            Text("\(player.pointDifferential > 0 ? "+" : "")\(player.pointDifferential)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(player.pointDifferential > 0 ? .green : (player.pointDifferential < 0 ? .red : .secondary))
                                .frame(width: 45, alignment: .trailing)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(rankIdx == 0 ? Color.orange.opacity(0.08) : Color.clear)
                        .cornerRadius(6)
                    }
                }
                .padding(8)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                
                // Matches on this court
                ForEach(courtMatchesIndices, id: \.self) { idx in
                    GeneratedMatchRow(match: $generatedMatches[idx])
                }
            } header: {
                Text("COURT #\(courtNum) (PLAYERS \( (courtNum - 1) * 4 + 1 )–\( min(courtNum * 4, playersList.count) ))")
            }
        }
    }
    
    // MARK: - Social Mixer Results Section
    
    private var socialMixerResultsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                Text("Matches rotate through all \(playersList.count) players giving everyone court time with balanced partners.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            ForEach($generatedMatches) { $match in
                GeneratedMatchRow(match: $match)
            }
            
            Button {
                addExtraMixerMatch()
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Another Rotation Match")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(.orange)
            }
        } header: {
            Text("GENERATED MATCHUPS (\(generatedMatches.count) MATCHES)")
        }
    }
    
    private func addPlayer() {
        let trimmed = newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        playersList.append(PoolPlayer(name: trimmed))
        newPlayerName = ""
    }
    
    // MARK: - King of the Court Generator
    
    private func generateKingOfTheCourt() {
        let cleanPlayers = playersList.filter { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard cleanPlayers.count >= 4 else {
            alertMessage = "King of the Court requires at least 4 players (4 per court). Please add more players."
            showAlert = true
            return
        }
        
        let courtCount = cleanPlayers.count / 4
        var allMatches: [GeneratedMatch] = []
        var globalMatchIdx = 1
        
        for c in 0..<courtCount {
            let courtPlayers = Array(cleanPlayers[c*4 ..< (c+1)*4])
            let cNum = c + 1
            
            // Set 1: P1 & P2 vs P3 & P4
            let s1 = GeneratedMatch(
                matchNumber: globalMatchIdx,
                courtNumber: "Court #\(cNum)",
                team1Player1: courtPlayers[0],
                team1Player2: courtPlayers[1],
                team2Player1: courtPlayers[2],
                team2Player2: courtPlayers[3]
            )
            globalMatchIdx += 1
            
            // Set 2: P1 & P3 vs P2 & P4
            let s2 = GeneratedMatch(
                matchNumber: globalMatchIdx,
                courtNumber: "Court #\(cNum)",
                team1Player1: courtPlayers[0],
                team1Player2: courtPlayers[2],
                team2Player1: courtPlayers[1],
                team2Player2: courtPlayers[3]
            )
            globalMatchIdx += 1
            
            // Set 3: P1 & P4 vs P2 & P3
            let s3 = GeneratedMatch(
                matchNumber: globalMatchIdx,
                courtNumber: "Court #\(cNum)",
                team1Player1: courtPlayers[0],
                team1Player2: courtPlayers[3],
                team2Player1: courtPlayers[1],
                team2Player2: courtPlayers[2]
            )
            globalMatchIdx += 1
            
            allMatches.append(contentsOf: [s1, s2, s3])
        }
        
        self.generatedMatches = allMatches
    }
    
    // MARK: - Individual Standings Calculation
    
    private func calculateStandings(for players: [PoolPlayer], matches: [GeneratedMatch]) -> [KingPlayerStanding] {
        var standings: [UUID: KingPlayerStanding] = [:]
        for p in players {
            standings[p.id] = KingPlayerStanding(id: p.id, name: p.name, courtNumber: 1)
        }
        
        for m in matches {
            guard let s1 = Int(m.team1Score), let s2 = Int(m.team2Score) else { continue }
            let t1Won = s1 > s2
            let t2Won = s2 > s1
            
            for p in [m.team1Player1, m.team1Player2] {
                standings[p.id]?.pointsFor += s1
                standings[p.id]?.pointsAgainst += s2
                if t1Won { standings[p.id]?.wins += 1 }
                else if t2Won { standings[p.id]?.losses += 1 }
            }
            for p in [m.team2Player1, m.team2Player2] {
                standings[p.id]?.pointsFor += s2
                standings[p.id]?.pointsAgainst += s1
                if t2Won { standings[p.id]?.wins += 1 }
                else if t1Won { standings[p.id]?.losses += 1 }
            }
        }
        
        return standings.values.sorted {
            if $0.wins != $1.wins { return $0.wins > $1.wins }
            if $0.pointDifferential != $1.pointDifferential { return $0.pointDifferential > $1.pointDifferential }
            return $0.pointsFor > $1.pointsFor
        }
    }
    
    // MARK: - Continuous Social Mixer Generator
    
    private func generateMixerRotations() {
        let cleanPlayers = playersList.filter { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard cleanPlayers.count >= 4 else { return }
        
        var playCounts: [UUID: Int] = [:]
        var partnerHistory: [UUID: Set<UUID>] = [:]
        for p in cleanPlayers {
            playCounts[p.id] = 0
            partnerHistory[p.id] = []
        }
        
        var matches: [GeneratedMatch] = []
        
        for i in 0..<numberOfGames {
            let sorted = cleanPlayers.shuffled().sorted { (playCounts[$0.id] ?? 0) < (playCounts[$1.id] ?? 0) }
            let picked = Array(sorted.prefix(4))
            let byes = Array(sorted.dropFirst(4))
            
            guard picked.count == 4 else { break }
            
            let splits = [
                ((picked[0], picked[1]), (picked[2], picked[3])),
                ((picked[0], picked[2]), (picked[1], picked[3])),
                ((picked[0], picked[3]), (picked[1], picked[2]))
            ]
            
            let bestSplit = splits.min { s1, s2 in
                let r1 = (partnerHistory[s1.0.0.id]?.contains(s1.0.1.id) == true ? 1 : 0) +
                         (partnerHistory[s1.1.0.id]?.contains(s1.1.1.id) == true ? 1 : 0)
                let r2 = (partnerHistory[s2.0.0.id]?.contains(s2.0.1.id) == true ? 1 : 0) +
                         (partnerHistory[s2.1.0.id]?.contains(s2.1.1.id) == true ? 1 : 0)
                return r1 < r2
            } ?? splits[0]
            
            var t1 = bestSplit.0
            var t2 = bestSplit.1
            if Bool.random() {
                let temp = t1
                t1 = t2
                t2 = temp
            }
            
            for p in picked {
                playCounts[p.id, default: 0] += 1
            }
            partnerHistory[t1.0.id]?.insert(t1.1.id)
            partnerHistory[t1.1.id]?.insert(t1.0.id)
            partnerHistory[t2.0.id]?.insert(t2.1.id)
            partnerHistory[t2.1.id]?.insert(t2.0.id)
            
            matches.append(GeneratedMatch(
                matchNumber: i + 1,
                courtNumber: "Court #1",
                team1Player1: t1.0,
                team1Player2: t1.1,
                team2Player1: t2.0,
                team2Player2: t2.1,
                restingPlayers: byes
            ))
        }
        
        self.generatedMatches = matches
    }
    
    private func addExtraMixerMatch() {
        let cleanPlayers = playersList.filter { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard cleanPlayers.count >= 4 else { return }
        
        var playCounts: [UUID: Int] = [:]
        for p in cleanPlayers { playCounts[p.id] = 0 }
        for m in generatedMatches {
            playCounts[m.team1Player1.id, default: 0] += 1
            playCounts[m.team1Player2.id, default: 0] += 1
            playCounts[m.team2Player1.id, default: 0] += 1
            playCounts[m.team2Player2.id, default: 0] += 1
        }
        
        let sorted = cleanPlayers.shuffled().sorted { (playCounts[$0.id] ?? 0) < (playCounts[$1.id] ?? 0) }
        let picked = Array(sorted.prefix(4))
        let byes = Array(sorted.dropFirst(4))
        
        guard picked.count == 4 else { return }
        
        let newMatch = GeneratedMatch(
            matchNumber: generatedMatches.count + 1,
            courtNumber: "Court #1",
            team1Player1: picked[0],
            team1Player2: picked[1],
            team2Player1: picked[2],
            team2Player2: picked[3],
            restingPlayers: byes
        )
        generatedMatches.append(newMatch)
    }
    
    private func saveAllMatchesToSchedule() {
        if let gId = initialGameId {
            let subMatches: [SubMatch] = generatedMatches.map { m in
                let s1 = Int(m.team1Score)
                let s2 = Int(m.team2Score)
                let isComp = (s1 != nil && s2 != nil)
                let win = isComp ? ((s1! > s2!) ? 1 : 2) : nil
                return SubMatch(
                    matchNumber: m.matchNumber,
                    courtNumber: m.courtNumber,
                    setNumber: m.matchNumber,
                    team1PlayerIds: [m.team1Player1.id, m.team1Player2.id],
                    team2PlayerIds: [m.team2Player1.id, m.team2Player2.id],
                    restingPlayerIds: m.restingPlayers.map { $0.id },
                    team1Score: s1,
                    team2Score: s2,
                    isCompleted: isComp,
                    winningTeam: win
                )
            }
            dataManager.saveSubMatches(gameId: gId, matches: subMatches)
            alertMessage = "Successfully saved \(subMatches.count) matches to this game!"
            showAlert = true
            return
        }
        
        let cal = Calendar.current
        let today = Date()
        
        for (idx, m) in generatedMatches.enumerated() {
            let t1Id1 = m.team1Player1.id
            let t1Id2 = m.team1Player2.id
            let t2Id1 = m.team2Player1.id
            let t2Id2 = m.team2Player2.id
            
            var setScores: [SetScore] = []
            var isComp = m.isCompleted
            var winner: Int? = nil
            
            if let s1 = Int(m.team1Score), let s2 = Int(m.team2Score) {
                setScores.append(SetScore(setNumber: 1, team1Score: s1, team2Score: s2))
                isComp = true
                winner = s1 > s2 ? 1 : 2
            }
            
            let gameDate = cal.date(byAdding: .minute, value: idx * 30, to: today) ?? today
            let titlePrefix = mode == .kingOfTheCourt ? "King of Court (\(m.courtNumber)) - Set \(m.matchNumber)" : "Round Robin Match #\(m.matchNumber)"
            
            let newGame = SetGame(
                title: titlePrefix,
                targetRating: dataManager.currentUser?.rating ?? .b,
                format: mode == .kingOfTheCourt ? .kingOfTheBeach : .singleSet21,
                status: isComp ? .completed : .scheduled,
                scheduledDate: gameDate,
                courtLocation: courtLocation,
                courtNumber: m.courtNumber,
                team1PlayerIds: [t1Id1, t1Id2],
                team2PlayerIds: [t2Id1, t2Id2],
                setScores: setScores,
                winningTeam: winner,
                isAutoMatched: false,
                matchedOptionName: mode.rawValue,
                notes: "\(m.team1Title) vs \(m.team2Title) • \(m.courtNumber)",
                hostPlayerId: dataManager.currentUser?.id ?? t1Id1,
                isLevelLocked: false
            )
            
            dataManager.games.insert(newGame, at: 0)
            dataManager.saveToDisk()
            FirestoreService.shared.saveGame(newGame)
        }
        
        alertMessage = "Successfully created \(generatedMatches.count) sets across \(playersList.count / 4) court(s) in your Set Games schedule!"
        showAlert = true
    }
}
