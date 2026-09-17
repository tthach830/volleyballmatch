import SwiftUI

public struct TournamentDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var dataManager: DataManager
    let tournamentId: UUID
    
    @State private var selectedDivision: TournamentDivisionCategory = .coedNovice2v2
    @State private var selectedSubTab: SubTab = .pools
    @State private var showSignUpSheet: Bool = false
    @State private var showLeaveAlert: Bool = false
    @State private var showEditTournamentSheet: Bool = false
    @State private var showDeleteTournamentAlert: Bool = false
    @State private var scoringMatch: TournamentMatch? = nil
    
    public enum SubTab: String, CaseIterable {
        case pools = "🏊 Pools"
        case bracket = "🏆 Bracket"
        case roster = "👥 Rosters"
        case info = "📋 Info"
    }
    
    public init(dataManager: DataManager, tournamentId: UUID) {
        self.dataManager = dataManager
        self.tournamentId = tournamentId
    }
    
    private var tournament: Tournament? {
        dataManager.tournaments.first(where: { $0.id == tournamentId })
    }
    
    private var isUserRegistered: Bool {
        guard let user = dataManager.currentUser, let t = tournament else { return false }
        return t.isPlayerRegistered(user.id)
    }
    
    public var body: some View {
        Group {
            if let t = tournament {
                ZStack(alignment: .bottom) {
                    ScrollView {
                        VStack(spacing: 16) {
                            
                            // Top Header Card
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("BEACH TOURNAMENT")
                                        .font(.system(size: 11, weight: .black))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Capsule().fill(Color.orange.opacity(0.2)))
                                        .foregroundColor(.orange)
                                    
                                    Spacer()
                                    
                                    Text(t.status.uppercased().replacingOccurrences(of: "_", with: " "))
                                        .font(.system(size: 10, weight: .black))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Capsule().fill(Color.green.opacity(0.2)))
                                        .foregroundColor(.green)
                                }
                                
                                Text("\(t.teamFormat.icon) \(t.teamFormat.displayName)")
                                    .font(.system(size: 10, weight: .black))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(Color.cyan.opacity(0.2)))
                                    .foregroundColor(.cyan)
                                
                                Text(t.title)
                                    .font(.system(size: 24, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "calendar")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                        Text(t.formattedDate)
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                    
                                    HStack(spacing: 6) {
                                        Image(systemName: "mappin.and.ellipse")
                                            .font(.caption)
                                            .foregroundColor(.cyan)
                                        Text("\(t.location) • \(t.courts.joined(separator: ", "))")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                }
                            }
                            .padding(18)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 0.14, green: 0.16, blue: 0.22), Color(red: 0.08, green: 0.10, blue: 0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(20)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
                            .padding(.horizontal)
                            
                            // DIVISION SELECTOR PILLS
                            VStack(alignment: .leading, spacing: 8) {
                                Text("DIVISIONS")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(t.allowedDivisions) { div in
                                            Button {
                                                selectedDivision = div
                                            } label: {
                                                HStack(spacing: 6) {
                                                    Text(div.icon)
                                                    Text(div.displayName)
                                                        .font(.system(size: 13, weight: .bold))
                                                    
                                                    // Team count badge
                                                    let count = t.teams(for: div).count
                                                    Text("\(count)")
                                                        .font(.system(size: 10, weight: .black))
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(Capsule().fill(selectedDivision == div ? Color.white.opacity(0.3) : Color.white.opacity(0.1)))
                                                }
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(selectedDivision == div ? Color.orange : Color(red: 0.12, green: 0.14, blue: 0.19))
                                                .foregroundColor(selectedDivision == div ? .white : .white.opacity(0.7))
                                                .clipShape(Capsule())
                                                .overlay(
                                                    Capsule().stroke(selectedDivision == div ? Color.orange : Color.white.opacity(0.08), lineWidth: 1)
                                                )
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            
                            // SUB-TAB PICKER (Pools, Bracket, Rosters, Info)
                            Picker("View Mode", selection: $selectedSubTab) {
                                ForEach(SubTab.allCases, id: \.self) { tab in
                                    Text(tab.rawValue).tag(tab)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)
                            
                            // TAB CONTENT
                            switch selectedSubTab {
                            case .pools:
                                poolsView(t: t, division: selectedDivision)
                            case .bracket:
                                bracketView(t: t, division: selectedDivision)
                            case .roster:
                                rosterView(t: t, division: selectedDivision)
                            case .info:
                                infoView(t: t)
                            }
                        }
                        .padding(.bottom, 90)
                    }
                    .background(Color(red: 0.08, green: 0.09, blue: 0.12).ignoresSafeArea())
                    
                    // BOTTOM STICKY ACTION BAR
                    VStack {
                        if isUserRegistered {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("🟢 Registered")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)
                                    Text("You are active in this tournament")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                }
                                Spacer()
                                Button("Leave") {
                                    showLeaveAlert = true
                                }
                                .font(.footnote)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.red.opacity(0.15))
                                .clipShape(Capsule())
                            }
                            .padding(14)
                            .background(Color(red: 0.11, green: 0.13, blue: 0.18))
                            .cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
                            .padding(.horizontal)
                        } else {
                            Button {
                                showSignUpSheet = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Sign Up for \(selectedDivision.displayName)")
                                        .fontWeight(.heavy)
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.orange)
                                .clipShape(Capsule())
                                .shadow(color: Color.orange.opacity(0.4), radius: 8, y: 4)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 12)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.08, green: 0.09, blue: 0.12).opacity(0), Color(red: 0.08, green: 0.09, blue: 0.12)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .navigationTitle(t.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    let isHostOrAdmin = (dataManager.currentUser?.isRoot == true) || (t.hostPlayerId != nil && t.hostPlayerId == dataManager.currentUser?.id)
                    if isHostOrAdmin {
                        ToolbarItem(placement: .topBarTrailing) {
                            Menu {
                                Button {
                                    showEditTournamentSheet = true
                                } label: {
                                    Label("Edit Tournament", systemImage: "pencil")
                                }
                                
                                Button(role: .destructive) {
                                    showDeleteTournamentAlert = true
                                } label: {
                                    Label("Delete Tournament", systemImage: "trash")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .font(.system(size: 17))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                .sheet(isPresented: $showSignUpSheet) {
                    TournamentSignUpSheet(dataManager: dataManager, tournament: t, preselectedDivision: selectedDivision)
                }
                .sheet(isPresented: $showEditTournamentSheet) {
                    CreateTournamentSheet(dataManager: dataManager, tournamentToEdit: t)
                }
                .sheet(item: $scoringMatch) { match in
                    TournamentScoreSheet(tournament: t, match: match, dataManager: dataManager)
                }
                .alert("Leave Tournament?", isPresented: $showLeaveAlert) {
                    Button("Cancel", role: .cancel) {}
                    Button("Confirm Leave", role: .destructive) {
                        if let user = dataManager.currentUser {
                            dataManager.leaveTournament(tournamentId: t.id, playerId: user.id)
                        }
                    }
                } message: {
                    Text("Are you sure you want to unregister from this tournament?")
                }
                .alert("Delete Tournament?", isPresented: $showDeleteTournamentAlert) {
                    Button("Cancel", role: .cancel) {}
                    Button("Delete", role: .destructive) {
                        dataManager.deleteTournament(id: t.id)
                        dismiss()
                    }
                } message: {
                    Text("Are you sure you want to permanently delete \"\(t.title)\"? This cannot be undone.")
                }
            } else {
                Text("Tournament Not Found")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Pools Sub-View (Auto Seeding & Standings)
    @ViewBuilder
    private func poolsView(t: Tournament, division: TournamentDivisionCategory) -> some View {
        let poolAName = "Pool A"
        let poolBName = "Pool B"
        let poolAMatches = t.poolMatches(for: division, poolName: poolAName)
        let poolBMatches = t.poolMatches(for: division, poolName: poolBName)
        let hasPools = !poolAMatches.isEmpty || !poolBMatches.isEmpty
        let divisionTeams = t.teams(for: division)
        let isHostOrAdmin = (dataManager.currentUser?.isRoot == true) || (t.hostPlayerId != nil && t.hostPlayerId == dataManager.currentUser?.id)
        
        VStack(spacing: 20) {
            // Generator Card (if no pools exist or host wants to re-generate)
            if !hasPools {
                VStack(spacing: 12) {
                    Image(systemName: "arrow.triangle.branch")
                        .font(.system(size: 36))
                        .foregroundColor(.cyan)
                    
                    Text("Auto Pool Play Generator")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Divides the \(divisionTeams.count) registered teams into Pool A & Pool B using Elo snake-seeding and creates all round-robin matchups.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button {
                        dataManager.generatePoolPlay(tournamentId: t.id, division: division)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "wand.and.stars")
                            Text("Generate Pools (Snake Seeding)")
                                .fontWeight(.bold)
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(divisionTeams.count >= 4 ? Color.cyan : Color.gray.opacity(0.4))
                        .cornerRadius(12)
                    }
                    .disabled(divisionTeams.count < 4)
                    
                    if divisionTeams.count < 4 {
                        Text("At least 4 teams required to seed pool play.")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        
                        Button {
                            dataManager.addDemoTeams(tournamentId: t.id, division: division)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "bolt.fill")
                                Text("Quick-Add 4 Demo Teams")
                            }
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.cyan)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.cyan.opacity(0.12))
                            .cornerRadius(8)
                        }
                        .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(Color(red: 0.11, green: 0.13, blue: 0.18))
                .cornerRadius(18)
                .padding(.horizontal)
            } else {
                // Standings for Pool A
                poolSectionView(t: t, division: division, poolName: poolAName, matches: poolAMatches)
                
                // Standings for Pool B
                poolSectionView(t: t, division: division, poolName: poolBName, matches: poolBMatches)
                
                // Advance to Playoff Bracket Button
                let bracketMatches = t.bracketMatches(for: division)
                if bracketMatches.isEmpty {
                    VStack(spacing: 10) {
                        Text("Ready for the Playoffs?")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("Advance top 2 from each pool to Semifinals (A1 vs B2, B1 vs A2).")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Button {
                            dataManager.generatePlayoffBracket(tournamentId: t.id, division: division)
                            selectedSubTab = .bracket
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "trophy.fill")
                                Text("Generate Playoff Bracket")
                                    .fontWeight(.bold)
                            }
                            .font(.footnote)
                            .foregroundColor(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(Color.orange)
                            .cornerRadius(10)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(Color(red: 0.12, green: 0.15, blue: 0.22))
                    .cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.orange.opacity(0.3), lineWidth: 1))
                    .padding(.horizontal)
                }
                
                if isHostOrAdmin {
                    Button("Regenerate Pools") {
                        dataManager.generatePoolPlay(tournamentId: t.id, division: division)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
        }
    }
    
    @ViewBuilder
    private func poolSectionView(t: Tournament, division: TournamentDivisionCategory, poolName: String, matches: [TournamentMatch]) -> some View {
        let standings = t.poolStandings(for: division, poolName: poolName)
        
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(poolName.uppercased())
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(.cyan)
                Spacer()
                Text("Top 2 Advance")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            // Standings Table Card
            VStack(spacing: 0) {
                // Table Header
                HStack {
                    Text("#")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.secondary)
                        .frame(width: 24, alignment: .leading)
                    Text("TEAM")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("MP")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.secondary)
                        .frame(width: 28, alignment: .center)
                    Text("W-L")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.secondary)
                        .frame(width: 40, alignment: .center)
                    Text("+/-")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.secondary)
                        .frame(width: 36, alignment: .trailing)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.04))
                
                Divider().background(Color.white.opacity(0.08))
                
                // Table Rows
                ForEach(Array(standings.enumerated()), id: \.element.id) { index, row in
                    let isTopTwo = index < 2
                    HStack {
                        HStack(spacing: 4) {
                            Text("\(index + 1)")
                                .font(.system(size: 12, weight: isTopTwo ? .black : .regular))
                                .foregroundColor(isTopTwo ? .green : .white.opacity(0.8))
                            if isTopTwo {
                                Circle().fill(Color.green).frame(width: 4, height: 4)
                            }
                        }
                        .frame(width: 24, alignment: .leading)
                        
                        Text(row.team.teamName)
                            .font(.system(size: 13, weight: isTopTwo ? .bold : .medium))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text("\(row.matchesPlayed)")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 28, alignment: .center)
                        
                        Text("\(row.wins)-\(row.losses)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(row.wins > 0 ? .green : .white.opacity(0.7))
                            .frame(width: 40, alignment: .center)
                        
                        Text(row.pointDifferential >= 0 ? "+\(row.pointDifferential)" : "\(row.pointDifferential)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(row.pointDifferential >= 0 ? .green : .red.opacity(0.8))
                            .frame(width: 36, alignment: .trailing)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    
                    if index < standings.count - 1 {
                        Divider().background(Color.white.opacity(0.04))
                    }
                }
            }
            .background(Color(red: 0.11, green: 0.13, blue: 0.18))
            .cornerRadius(14)
            .padding(.horizontal)
            
            // Matches in this pool
            if !matches.isEmpty {
                VStack(spacing: 8) {
                    ForEach(matches) { match in
                        TournamentMatchRowView(match: match, teams: t.teams) {
                            scoringMatch = match
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Playoff Bracket Sub-View
    @ViewBuilder
    private func bracketView(t: Tournament, division: TournamentDivisionCategory) -> some View {
        let bracketMatches = t.bracketMatches(for: division)
        let isHostOrAdmin = (dataManager.currentUser?.isRoot == true) || (t.hostPlayerId != nil && t.hostPlayerId == dataManager.currentUser?.id)
        
        VStack(spacing: 16) {
            if bracketMatches.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "trophy")
                        .font(.system(size: 40))
                        .foregroundColor(.orange.opacity(0.6))
                    Text("Playoff Bracket Not Yet Generated")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Complete pool play matches first, then generate the single elimination bracket!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button {
                        dataManager.generatePlayoffBracket(tournamentId: t.id, division: division)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "wand.and.stars")
                            Text("Generate Bracket From Pool Standings")
                                .fontWeight(.bold)
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(Color.orange)
                        .cornerRadius(12)
                    }
                }
                .padding(32)
                .frame(maxWidth: .infinity)
                .background(Color(red: 0.11, green: 0.13, blue: 0.18))
                .cornerRadius(20)
                .padding(.horizontal)
            } else {
                // Champion Trophy Banner if final completed
                let finalMatch = bracketMatches.first(where: { $0.stage == "final" })
                if let champId = finalMatch?.winningTeamId, let champTeam = t.teams.first(where: { $0.id == champId }) {
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Text("🏆")
                                .font(.title)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("DIVISION CHAMPION")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundColor(.orange)
                                Text(champTeam.teamName)
                                    .font(.title2)
                                    .fontWeight(.heavy)
                                    .foregroundColor(.white)
                            }
                            Spacer()
                        }
                    }
                    .padding(16)
                    .background(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.25), Color(red: 0.14, green: 0.12, blue: 0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.orange.opacity(0.5), lineWidth: 1.5))
                    .padding(.horizontal)
                }
                
                // Championship Final
                let finals = bracketMatches.filter { $0.stage == "final" }
                if !finals.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("🥇 CHAMPIONSHIP FINAL")
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(.orange)
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        ForEach(finals) { m in
                            TournamentMatchRowView(match: m, teams: t.teams) {
                                scoringMatch = m
                            }
                        }
                    }
                }
                
                // 3rd Place Match
                let thirdPlace = bracketMatches.filter { $0.stage == "third_place" }
                if !thirdPlace.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("🥉 3RD PLACE CONSOLATION")
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(.cyan)
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        ForEach(thirdPlace) { m in
                            TournamentMatchRowView(match: m, teams: t.teams) {
                                scoringMatch = m
                            }
                        }
                    }
                }
                
                // Semifinals
                let semis = bracketMatches.filter { $0.stage == "semi" }
                if !semis.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("⚡️ SEMIFINALS")
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(.white.opacity(0.8))
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        ForEach(semis) { m in
                            TournamentMatchRowView(match: m, teams: t.teams) {
                                scoringMatch = m
                            }
                        }
                    }
                }
                
                if isHostOrAdmin {
                    Button("Regenerate Playoff Bracket") {
                        dataManager.generatePlayoffBracket(tournamentId: t.id, division: division)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
                }
            }
        }
    }
    
    // MARK: - Roster / Teams Sub-View
    @ViewBuilder
    private func rosterView(t: Tournament, division: TournamentDivisionCategory) -> some View {
        let divisionTeams = t.teams(for: division)
        let divisionFreeAgents = t.freeAgents(for: division)
        
        VStack(spacing: 16) {
            // Confirmed Teams Section
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("CONFIRMED TEAMS (\(divisionTeams.count)/\(t.maxTeamsPerDivision))")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.orange)
                    Spacer()
                }
                .padding(.horizontal)
                
                if divisionTeams.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "person.2.slash")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No teams registered for \(division.displayName) yet")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(30)
                    .background(Color(red: 0.11, green: 0.13, blue: 0.18))
                    .cornerRadius(16)
                    .padding(.horizontal)
                } else {
                    VStack(spacing: 8) {
                        ForEach(Array(divisionTeams.enumerated()), id: \.element.id) { index, team in
                            TournamentTeamRowView(team: team, seedNumber: team.seed ?? (index + 1), players: dataManager.players)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // Free Agent Pool Section
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("FREE AGENTS (\(divisionFreeAgents.count))")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.cyan)
                    Spacer()
                }
                .padding(.horizontal)
                
                if divisionFreeAgents.isEmpty {
                    Text("No free agents waiting in this division.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                } else {
                    VStack(spacing: 8) {
                        ForEach(divisionFreeAgents) { fa in
                            TournamentFreeAgentRowView(freeAgent: fa, players: dataManager.players)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - Info & Rules Sub-View
    @ViewBuilder
    private func infoView(t: Tournament) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("TOURNAMENT NOTES & FORMAT")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.orange)
                Text(t.notes)
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.9))
                    .lineSpacing(3)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(red: 0.11, green: 0.13, blue: 0.18))
            .cornerRadius(14)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("STANDARD BEACH RULES")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.cyan)
                
                RuleBulletPoint(text: "Rally scoring to 21 points (win by 2, cap at 23).")
                RuleBulletPoint(text: "Switch sides every 7 points to equalize sun & wind conditions.")
                RuleBulletPoint(text: "No open-hand tips (roll shots, knuckles, or cut-shots only).")
                RuleBulletPoint(text: "Coed division: 1 male & 1 female player per team.")
                RuleBulletPoint(text: "Pool play: Round-robin within Pool A and Pool B.")
                RuleBulletPoint(text: "Playoffs: Top 2 from each pool advance (A1 vs B2, B1 vs A2).")
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(red: 0.11, green: 0.13, blue: 0.18))
            .cornerRadius(14)
        }
        .padding(.horizontal)
    }
}

// MARK: - Sub-Components
struct TournamentTeamRowView: View {
    let team: TournamentTeam
    let seedNumber: Int
    let players: [Player]
    
    var body: some View {
        let p1 = players.first(where: { $0.id == team.player1Id })
        let p2 = team.player2Id.flatMap { id in players.first(where: { $0.id == id }) }
        let p3 = team.player3Id.flatMap { id in players.first(where: { $0.id == id }) }
        let p4 = team.player4Id.flatMap { id in players.first(where: { $0.id == id }) }
        
        HStack(spacing: 12) {
            Text("#\(seedNumber)")
                .font(.system(size: 13, weight: .black))
                .foregroundColor(.orange)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(team.teamName)
                        .font(.headline)
                        .foregroundColor(.white)
                    if let pool = team.poolName {
                        Text(pool)
                            .font(.system(size: 10, weight: .black))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.cyan.opacity(0.2)))
                            .foregroundColor(.cyan)
                    }
                }
                
                // Row 1: Player 1 & Player 2
                HStack(spacing: 8) {
                    playerLabel(player: p1, fallback: "Player 1")
                    
                    Text("&")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if let p2 = p2 {
                        playerLabel(player: p2, fallback: "Player 2")
                    } else {
                        Text("Looking for Partner")
                            .font(.caption2)
                            .italic()
                            .foregroundColor(.orange)
                    }
                }
                
                // Row 2: Player 3 & Player 4 (4v4 only)
                if team.player3Id != nil || team.player4Id != nil {
                    HStack(spacing: 8) {
                        if let p3 = p3 {
                            playerLabel(player: p3, fallback: "Player 3")
                        } else if team.player3Id != nil {
                            Text("+ Open Spot")
                                .font(.caption2)
                                .italic()
                                .foregroundColor(.orange)
                        }
                        
                        if team.player4Id != nil || team.player3Id != nil {
                            Text("&")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        if let p4 = p4 {
                            playerLabel(player: p4, fallback: "Player 4")
                        } else {
                            Text("+ Open Spot")
                                .font(.caption2)
                                .italic()
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color(red: 0.11, green: 0.13, blue: 0.18))
        .cornerRadius(14)
    }
    
    @ViewBuilder
    private func playerLabel(player: Player?, fallback: String) -> some View {
        if let p = player {
            HStack(spacing: 4) {
                PlayerAvatarView(player: p, dimension: 20, showBadge: false)
                Text(p.displayName)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.85))
            }
        } else {
            Text(fallback)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.85))
        }
    }
}

struct TournamentFreeAgentRowView: View {
    let freeAgent: TournamentFreeAgent
    let players: [Player]
    
    var body: some View {
        if let p = players.first(where: { $0.id == freeAgent.playerId }) {
            HStack(spacing: 12) {
                PlayerAvatarView(player: p, dimension: 36, showBadge: false)
                VStack(alignment: .leading, spacing: 2) {
                    Text(p.displayName)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    if !freeAgent.notes.isEmpty {
                        Text("\"\(freeAgent.notes)\"")
                            .font(.caption2)
                            .italic()
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                Spacer()
                RatingBadge(rating: p.rating)
            }
            .padding(10)
            .background(Color(red: 0.11, green: 0.13, blue: 0.18))
            .cornerRadius(12)
        }
    }
}

struct TournamentMatchRowView: View {
    let match: TournamentMatch
    let teams: [TournamentTeam]
    var onScore: (() -> Void)? = nil
    
    var body: some View {
        let t1 = teams.first(where: { $0.id == match.team1Id })
        let t2 = teams.first(where: { $0.id == match.team2Id })
        let isFinal = match.status == "completed"
        
        VStack(spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    if let pool = match.poolName {
                        Text(pool.uppercased())
                            .font(.system(size: 9, weight: .black))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.cyan.opacity(0.2)))
                            .foregroundColor(.cyan)
                    } else if match.stage != "pool" {
                        Text(match.stage.uppercased().replacingOccurrences(of: "_", with: " "))
                            .font(.system(size: 9, weight: .black))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.orange.opacity(0.2)))
                            .foregroundColor(.orange)
                    }
                    
                    Text("Match \(match.matchNumber)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.caption2)
                    Text(match.courtNumber)
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white.opacity(0.7))
            }
            
            HStack(spacing: 14) {
                // Team 1
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(t1?.teamName ?? "TBD")
                            .font(.system(size: 14, weight: match.winningTeamId == t1?.id ? .heavy : .medium))
                            .foregroundColor(match.winningTeamId == t1?.id ? .green : (t1 != nil ? .white : .secondary))
                            .lineLimit(1)
                        if match.winningTeamId == t1?.id {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                    }
                }
                
                Spacer()
                
                // Score Box / Button
                if let s1 = match.team1Score, let s2 = match.team2Score {
                    HStack(spacing: 6) {
                        Text("\(s1)")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundColor(match.winningTeamId == t1?.id ? .green : .white)
                        Text("-")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("\(s2)")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundColor(match.winningTeamId == t2?.id ? .green : .white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(8)
                } else {
                    Text("vs")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Team 2
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        if match.winningTeamId == t2?.id {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                        Text(t2?.teamName ?? "TBD")
                            .font(.system(size: 14, weight: match.winningTeamId == t2?.id ? .heavy : .medium))
                            .foregroundColor(match.winningTeamId == t2?.id ? .green : (t2 != nil ? .white : .secondary))
                            .lineLimit(1)
                    }
                }
            }
            
            // Score submission action button
            if let onScore = onScore, t1 != nil && t2 != nil {
                Divider().background(Color.white.opacity(0.06))
                
                Button(action: onScore) {
                    HStack(spacing: 6) {
                        Image(systemName: isFinal ? "pencil.circle" : "plus.circle")
                        Text(isFinal ? "Edit Score" : "Report Score")
                            .fontWeight(.bold)
                    }
                    .font(.caption)
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(12)
        .background(Color(red: 0.11, green: 0.13, blue: 0.18))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isFinal ? Color.green.opacity(0.2) : Color.white.opacity(0.06), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}

// MARK: - Tournament Match Scoring Sheet
struct TournamentScoreSheet: View {
    @Environment(\.dismiss) private var dismiss
    let tournament: Tournament
    let match: TournamentMatch
    let dataManager: DataManager
    
    @State private var team1Score: Int
    @State private var team2Score: Int
    @State private var errorMessage: String? = nil
    
    init(tournament: Tournament, match: TournamentMatch, dataManager: DataManager) {
        self.tournament = tournament
        self.match = match
        self.dataManager = dataManager
        _team1Score = State(initialValue: match.team1Score ?? 21)
        _team2Score = State(initialValue: match.team2Score ?? 19)
    }
    
    var body: some View {
        let t1 = tournament.teams.first(where: { $0.id == match.team1Id })
        let t2 = tournament.teams.first(where: { $0.id == match.team2Id })
        let t1Name = t1?.teamName ?? "Team 1"
        let t2Name = t2?.teamName ?? "Team 2"
        let winnerName: String? = team1Score > team2Score ? t1Name : (team2Score > team1Score ? t2Name : nil)
        
        NavigationView {
            ZStack {
                Color(red: 0.08, green: 0.09, blue: 0.12).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Details
                        VStack(spacing: 6) {
                            Text(match.courtNumber.uppercased())
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(.cyan)
                            
                            Text("Official Score Report")
                                .font(.title3)
                                .fontWeight(.black)
                                .foregroundColor(.white)
                            
                            if let pool = match.poolName {
                                Text("\(pool) • Match #\(match.matchNumber)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("\(match.stage.capitalized) • Match #\(match.matchNumber)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.top, 10)
                        
                        // Head-to-Head Score Steppers
                        VStack(spacing: 16) {
                            // Team 1 Stepper
                            scoreStepperRow(teamName: t1Name, score: $team1Score, isLeading: team1Score > team2Score)
                            
                            Divider().background(Color.white.opacity(0.1))
                            
                            // Team 2 Stepper
                            scoreStepperRow(teamName: t2Name, score: $team2Score, isLeading: team2Score > team1Score)
                        }
                        .padding(18)
                        .background(Color(red: 0.12, green: 0.14, blue: 0.20))
                        .cornerRadius(18)
                        .padding(.horizontal)
                        
                        // Quick Presets
                        VStack(alignment: .leading, spacing: 10) {
                            Text("QUICK PRESETS")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 8) {
                                presetButton(s1: 21, s2: 19)
                                presetButton(s1: 21, s2: 17)
                                presetButton(s1: 21, s2: 15)
                                presetButton(s1: 21, s2: 12)
                                presetButton(s1: 15, s2: 13)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Winner Indicator Box
                        if let winner = winnerName {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.green)
                                Text("Projected Winner: ")
                                    .foregroundColor(.secondary)
                                + Text(winner)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                            .font(.footnote)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.green.opacity(0.12))
                            .cornerRadius(12)
                        } else {
                            Text("Scores cannot be tied in volleyball.")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        if let err = errorMessage {
                            Text(err)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        // Submit Button
                        Button {
                            guard team1Score != team2Score else {
                                errorMessage = "Ties are not allowed. One team must win."
                                return
                            }
                            dataManager.submitTournamentMatchScore(
                                tournamentId: tournament.id,
                                matchId: match.id,
                                team1Score: team1Score,
                                team2Score: team2Score
                            )
                            dismiss()
                        } label: {
                            Text("Submit Official Score")
                                .font(.headline)
                                .fontWeight(.heavy)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(team1Score != team2Score ? Color.orange : Color.gray.opacity(0.4))
                                .cornerRadius(14)
                        }
                        .disabled(team1Score == team2Score)
                        .padding(.horizontal)
                        .padding(.top, 10)
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.orange)
                }
            }
        }
    }
    
    @ViewBuilder
    private func scoreStepperRow(teamName: String, score: Binding<Int>, isLeading: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(teamName)
                    .font(.headline)
                    .foregroundColor(isLeading ? .green : .white)
                    .lineLimit(1)
                Text(isLeading ? "Winning" : "")
                    .font(.caption2)
                    .foregroundColor(.green)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button {
                    if score.wrappedValue > 0 { score.wrappedValue -= 1 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                
                Text("\(score.wrappedValue)")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .frame(width: 44)
                
                Button {
                    if score.wrappedValue < 99 { score.wrappedValue += 1 }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                }
            }
        }
    }
    
    @ViewBuilder
    private func presetButton(s1: Int, s2: Int) -> some View {
        Button {
            team1Score = s1
            team2Score = s2
        } label: {
            Text("\(s1)-\(s2)")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.08))
                .cornerRadius(8)
        }
    }
}

struct RuleBulletPoint: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•")
                .foregroundColor(.orange)
            Text(text)
                .font(.caption)
                .foregroundColor(.white.opacity(0.85))
        }
    }
}
