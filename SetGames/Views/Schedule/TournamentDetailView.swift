import SwiftUI

public struct TournamentDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var dataManager: DataManager
    let tournamentId: UUID
    
    public enum TournamentDetailSheet: Identifiable {
        case signUp
        case editTournament
        case manageCoHosts
        case scoreMatch(TournamentMatch)
        case qrCode
        case addTeam
        case editTeam(TournamentTeam)
        case editPools
        case teamInvite(TournamentTeam)
        
        public var id: String {
            switch self {
            case .signUp: return "signUp"
            case .editTournament: return "editTournament"
            case .manageCoHosts: return "manageCoHosts"
            case .scoreMatch(let match): return "scoreMatch-\(match.id.uuidString)"
            case .qrCode: return "qrCode"
            case .addTeam: return "addTeam"
            case .editTeam(let team): return "editTeam-\(team.id.uuidString)"
            case .editPools: return "editPools"
            case .teamInvite(let team): return "teamInvite-\(team.id.uuidString)"
            }
        }
    }
    
    @State private var selectedDivision: TournamentDivisionCategory = .coedNovice2v2
    @State private var selectedSubTab: SubTab = .pools
    @State private var activeSheet: TournamentDetailSheet? = nil
    @State private var showLeaveAlert: Bool = false
    @State private var showDeleteTournamentAlert: Bool = false
    @State private var teamToRemove: TournamentTeam? = nil
    @State private var showRemoveTeamAlert: Bool = false
    @State private var freeAgentToRemove: TournamentFreeAgent? = nil
    @State private var showRemoveFreeAgentAlert: Bool = false
    @State private var showRegeneratePoolsAlert: Bool = false
    @State private var showRemovePoolsAlert: Bool = false
    @State private var showClearRostersAlert: Bool = false
    @State private var selectedTeamForRoster: TournamentTeam? = nil
    
    public enum SubTab: String, CaseIterable {
        case pools = "🏊 Pools"
        case bracket = "🏆 Bracket"
        case roster = "👥 Rosters"
        case info = "📋 Info"
    }
    
    public init(dataManager: DataManager, tournamentId: UUID) {
        self.dataManager = dataManager
        self.tournamentId = tournamentId
        
        let initialTourn = dataManager.tournaments.first(where: { 
            $0.id == tournamentId || 
            ($0.rawId != nil && $0.rawId?.caseInsensitiveCompare(tournamentId.uuidString) == .orderedSame)
        })
        let defaultDiv = initialTourn?.allowedDivisions.first ?? .coedNovice2v2
        _selectedDivision = State(initialValue: defaultDiv)
    }
    
    private var tournament: Tournament? {
        dataManager.tournaments.first(where: { 
            $0.id == tournamentId || 
            ($0.rawId != nil && $0.rawId?.caseInsensitiveCompare(tournamentId.uuidString) == .orderedSame)
        })
    }
    
    private var isUserRegistered: Bool {
        guard let user = dataManager.currentUser, let t = tournament else { return false }
        return t.isPlayerRegistered(user.id)
    }
    
    public var body: some View {
        Group {
            if let t = tournament {
                let activeDivision = t.allowedDivisions.contains(selectedDivision) ? selectedDivision : (t.allowedDivisions.first ?? selectedDivision)
                ZStack(alignment: .bottom) {
                    ScrollView {
                        VStack(spacing: 16) {
                            headerCard(t: t)
                            divisionSelector(t: t, activeDivision: activeDivision)
                            
                            // SUB-TAB PICKER (Pools, Bracket, Rosters, Info)
                            Picker("View Mode", selection: $selectedSubTab) {
                                ForEach(SubTab.allCases, id: \.self) { tab in
                                    Text(tab.rawValue).tag(tab)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)
                            
                            // SCHEDULE ESTIMATE BANNER
                            if selectedSubTab == .pools || selectedSubTab == .bracket {
                                scheduleEstimateCard(t: t, division: activeDivision)
                            }
                            
                            // TAB CONTENT
                            switch selectedSubTab {
                            case .pools:
                                poolsView(t: t, division: activeDivision)
                            case .bracket:
                                bracketView(t: t, division: activeDivision)
                            case .roster:
                                rosterView(t: t, division: activeDivision)
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
                                    Text("🟢 Reg")
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
                                activeSheet = .signUp
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Sign Up for \(activeDivision.displayName)")
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
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack(spacing: 12) {
                            Button {
                                activeSheet = .qrCode
                            } label: {
                                Image(systemName: "qrcode")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            let isHostOrAdmin = (dataManager.currentUser?.isRoot == true) || t.isHostOrCoHost(dataManager.currentUser?.id)
                            let isPrimaryHostOrAdmin = (dataManager.currentUser?.isRoot == true) || (t.hostPlayerId != nil && t.hostPlayerId == dataManager.currentUser?.id)
                            if isHostOrAdmin {
                                Menu {
                                    Button {
                                        activeSheet = .editTournament
                                    } label: {
                                        Label("Edit Tournament", systemImage: "pencil")
                                    }
                                    
                                    if isPrimaryHostOrAdmin {
                                        Button {
                                            activeSheet = .manageCoHosts
                                        } label: {
                                            Label("Manage Co-Hosts", systemImage: "person.badge.shield.checkmark")
                                        }
                                        
                                        Button(role: .destructive) {
                                            showDeleteTournamentAlert = true
                                        } label: {
                                            Label("Delete Tournament", systemImage: "trash")
                                        }
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                        .font(.system(size: 17))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                }
                .sheet(item: $activeSheet) { sheet in
                    switch sheet {
                    case .signUp:
                        TournamentSignUpSheet(dataManager: dataManager, tournament: t, preselectedDivision: activeDivision)
                    case .editTournament:
                        CreateTournamentSheet(dataManager: dataManager, tournamentToEdit: t)
                    case .manageCoHosts:
                        ManageCoHostsSheet(dataManager: dataManager, tournament: t)
                    case .scoreMatch(let match):
                        TournamentScoreSheet(tournament: t, match: match, dataManager: dataManager)
                    case .qrCode:
                        TournamentQRCodeSheet(tournament: t)
                    case .addTeam:
                        ManualTeamEditSheet(dataManager: dataManager, tournament: t, preselectedDivision: activeDivision, teamToEdit: nil)
                    case .editTeam(let team):
                        ManualTeamEditSheet(dataManager: dataManager, tournament: t, preselectedDivision: team.division, teamToEdit: team)
                    case .editPools:
                        EditPoolPlaySheet(tournament: t, division: activeDivision, dataManager: dataManager)
                    case .teamInvite(let team):
                        TeamQRCodeSheet(tournament: t, team: team)
                    }
                }
                .sheet(item: $selectedTeamForRoster) { team in
                    TeamRosterSheet(team: team, tournament: t, dataManager: dataManager)
                }
                .onAppear {
                    if let first = t.allowedDivisions.first, !t.allowedDivisions.contains(selectedDivision) {
                        selectedDivision = first
                    }
                }
                .onChange(of: t.allowedDivisions) { newDivs in
                    if let first = newDivs.first, !newDivs.contains(selectedDivision) {
                        selectedDivision = first
                    }
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
                .alert("Remove Team from Tournament?", isPresented: $showRemoveTeamAlert) {
                    Button("Cancel", role: .cancel) { teamToRemove = nil }
                    Button("Remove Team", role: .destructive) {
                        if let team = teamToRemove {
                            dataManager.removeTournamentTeam(tournamentId: t.id, teamId: team.id)
                            teamToRemove = nil
                        }
                    }
                } message: {
                    if let team = teamToRemove {
                        Text("Are you sure you want to remove '\(team.teamName)' from \(t.title)?")
                    }
                }
                .alert("Remove Free Agent?", isPresented: $showRemoveFreeAgentAlert) {
                    Button("Cancel", role: .cancel) { freeAgentToRemove = nil }
                    Button("Remove", role: .destructive) {
                        if let fa = freeAgentToRemove {
                            dataManager.removeTournamentFreeAgent(tournamentId: t.id, playerId: fa.playerId)
                            freeAgentToRemove = nil
                        }
                    }
                } message: {
                    if let fa = freeAgentToRemove {
                        let pName = dataManager.player(for: fa.playerId).displayName
                        Text("Are you sure you want to remove \(pName) from the free agent pool?")
                    }
                }
            } else {
                Text("Tournament Not Found")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Header & Navigation Helpers
    @ViewBuilder
    private func headerCard(t: Tournament) -> some View {
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
            
            Text("\(t.effectiveTeamFormat.icon) \(t.effectiveTeamFormat.displayName)")
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
                
                // Host & Co-Hosts
                HStack(spacing: 6) {
                    Image(systemName: "crown.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                    let hostName = dataManager.players.first(where: { $0.id == t.hostPlayerId })?.displayName ?? "Organizer"
                    Text("Host: \(hostName)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.9))
                    
                    let coHosts = t.coHosts(from: dataManager.players)
                    if !coHosts.isEmpty {
                        Text("•")
                            .foregroundColor(.white.opacity(0.4))
                        Image(systemName: "person.2.fill")
                            .font(.caption2)
                            .foregroundColor(.cyan)
                        Text("Co-Hosts: \(coHosts.map { $0.displayName }.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundColor(.cyan)
                    }
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
    }

    @ViewBuilder
    private func divisionSelector(t: Tournament, activeDivision: TournamentDivisionCategory) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DIVISIONS")
                .font(.system(size: 11, weight: .black))
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(t.allowedDivisions) { div in
                        divisionPill(t: t, div: div, activeDivision: activeDivision)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    @ViewBuilder
    private func divisionPill(t: Tournament, div: TournamentDivisionCategory, activeDivision: TournamentDivisionCategory) -> some View {
        let count = t.teams(for: div).count
        let isSelected = activeDivision == div
        Button {
            selectedDivision = div
        } label: {
            HStack(spacing: 6) {
                Text(div.icon)
                Text(div.displayName)
                    .font(.system(size: 13, weight: .bold))
                
                Text("\(count)")
                    .font(.system(size: 10, weight: .black))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(isSelected ? Color.white.opacity(0.3) : Color.white.opacity(0.1)))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.orange : Color(red: 0.12, green: 0.14, blue: 0.19))
            .foregroundColor(isSelected ? .white : .white.opacity(0.7))
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(isSelected ? Color.orange : Color.white.opacity(0.08), lineWidth: 1)
            )
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
        let isHostOrAdmin = (dataManager.currentUser?.isRoot == true) || t.isHostOrCoHost(dataManager.currentUser?.id)
        
        VStack(spacing: 20) {
            // Generator Card (if no pools exist or host wants to re-generate)
            if !hasPools {
                if isHostOrAdmin {
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
                    VStack(spacing: 12) {
                        Image(systemName: "clock.badge.checkmark")
                            .font(.system(size: 36))
                            .foregroundColor(.orange)
                        
                        Text("Pool Play Not Yet Generated")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("The tournament host will seed and generate pool play matchups once team registration is complete.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    .background(Color(red: 0.11, green: 0.13, blue: 0.18))
                    .cornerRadius(18)
                    .padding(.horizontal)
                }
            } else {
                // Host Pools Status Dashboard
                poolStatusDashboardView(t: t, division: division, poolAMatches: poolAMatches, poolBMatches: poolBMatches)
                
                // Standings for Pool A
                poolSectionView(t: t, division: division, poolName: poolAName, matches: poolAMatches)
                
                // Standings for Pool B
                poolSectionView(t: t, division: division, poolName: poolBName, matches: poolBMatches)
                
                // Advance to Playoff Bracket Button (Host only)
                let bracketMatches = t.bracketMatches(for: division)
                if bracketMatches.isEmpty && isHostOrAdmin {
                    VStack(spacing: 8) {
                        Text("Ready for Single Elimination Playoffs?")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text(t.playoffAdvanceMode == .allTeams ? "Every team advances to the single-elimination playoff bracket seeded by pool finish!" : "The top 2 teams from each pool advance directly to the Semifinals!")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button {
                            dataManager.generatePlayoffBracket(tournamentId: t.id, division: division)
                            selectedSubTab = .bracket
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "trophy.fill")
                                Text("Generate Single Elimination Bracket")
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
                    HStack(spacing: 8) {
                        Button {
                            activeSheet = .editPools
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "pencil.and.list.clipboard")
                                Text("Edit Pools")
                            }
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Color.blue)
                            .cornerRadius(8)
                        }
                        
                        Button {
                            showRegeneratePoolsAlert = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text("Re-generate")
                            }
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Color.orange)
                            .cornerRadius(8)
                        }
                        
                        Button {
                            showRemovePoolsAlert = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "trash")
                                Text("Remove Pools")
                            }
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Color.red.opacity(0.15))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.top, 6)
                }
            }
        }
        .alert("Re-generate Pool Play?", isPresented: $showRegeneratePoolsAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Re-generate", role: .destructive) {
                _ = dataManager.generatePoolPlay(tournamentId: t.id, division: division)
            }
        } message: {
            Text("This will re-seed teams using Elo and create new round-robin matchups for \(division.displayName). Any current pool match scores will be reset.")
        }
        .alert("Remove Pool Play?", isPresented: $showRemovePoolsAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Remove Pools", role: .destructive) {
                dataManager.removePoolPlay(tournamentId: t.id, division: division)
            }
        } message: {
            Text("Are you sure you want to remove pool play for \(division.displayName)? All pool matches, standings, and scores will be deleted.")
        }
    }
    
    @ViewBuilder
    private func poolSectionView(t: Tournament, division: TournamentDivisionCategory, poolName: String, matches: [TournamentMatch]) -> some View {
        let standings = t.poolStandings(for: division, poolName: poolName)
        let playedCount = matches.filter { $0.isCompleted }.count
        let totalCount = matches.count
        let isPoolComplete = totalCount > 0 && playedCount == totalCount
        
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Text(poolName.uppercased())
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(.cyan)
                    
                    Text("(\(playedCount)/\(totalCount) Played)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(isPoolComplete ? .green : .secondary)
                }
                
                Spacer()
                
                if isPoolComplete {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                        Text("Pool Complete")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(.green)
                } else {
                    Text("All Teams Advance to Playoffs")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.green)
                }
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
                        
                        Button {
                            selectedTeamForRoster = row.team
                        } label: {
                            Text(row.team.teamName)
                                .font(.system(size: 13, weight: isTopTwo ? .bold : .medium))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .underline(pattern: .dot, color: .white.opacity(0.35))
                        }
                        .buttonStyle(.plain)
                        
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
                        TournamentMatchRowView(
                            match: match,
                            teams: t.teams,
                            players: dataManager.players,
                            onScore: {
                                activeSheet = .scoreMatch(match)
                            },
                            onSelectTeam: { team in
                                selectedTeamForRoster = team
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Schedule Estimate Card
    @ViewBuilder
    private func scheduleEstimateCard(t: Tournament, division: TournamentDivisionCategory) -> some View {
        let est = t.estimateSchedule(for: division)
        let isHostOrAdmin = (dataManager.currentUser?.isRoot == true) || t.isHostOrCoHost(dataManager.currentUser?.id)
        
        VStack(spacing: 10) {
            HStack(alignment: .center) {
                HStack(spacing: 6) {
                    Image(systemName: "clock.badge.checkmark.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 15))
                    VStack(alignment: .leading, spacing: 1) {
                        Text("ESTIMATED SCHEDULE")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.orange)
                        Text("Total: \(est.formattedDuration)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 1) {
                    Text("DONE BY")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                    Text("~\(est.formattedEndTime)")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundColor(.green)
                }
            }
            
            Divider().background(Color.white.opacity(0.1))
            
            // Breakdown chips
            HStack(spacing: 8) {
                // Pool Play
                HStack(spacing: 4) {
                    Image(systemName: "figure.volleyball")
                        .font(.caption2)
                        .foregroundColor(.cyan)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Pool Play: ~\(est.formattedPoolDuration)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                        Text("\(est.poolMatchCount) matches (\(est.roundsPool) rds • \(est.courtCount) \(est.courtCount == 1 ? "court" : "courts"))")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(Color.white.opacity(0.04))
                .cornerRadius(8)
                
                // Playoffs
                HStack(spacing: 4) {
                    Image(systemName: "trophy.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Playoffs: ~\(est.formattedPlayoffDuration)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                        Text("\(est.playoffMatchCount) matches (\(est.roundsPlayoff) rounds)")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(Color.white.opacity(0.04))
                .cornerRadius(8)
            }
            
            // Playoff Advance Mode Option (Selectable by Host, readable by all)
            HStack {
                Text("Playoff Qualification:")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if isHostOrAdmin {
                    Menu {
                        ForEach(PlayoffAdvanceMode.allCases) { mode in
                            Button {
                                dataManager.setTournamentPlayoffAdvanceMode(tournamentId: t.id, mode: mode)
                            } label: {
                                HStack {
                                    Text(mode.title)
                                    if t.playoffAdvanceMode == mode {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(t.playoffAdvanceMode.title)
                                .font(.caption2)
                                .fontWeight(.bold)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 9))
                        }
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.15))
                        .cornerRadius(6)
                    }
                } else {
                    Text(t.playoffAdvanceMode.title)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.12))
                        .cornerRadius(6)
                }
            }
        }
        .padding(12)
        .background(
            LinearGradient(
                colors: [Color(red: 0.12, green: 0.14, blue: 0.20), Color(red: 0.09, green: 0.11, blue: 0.16)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .padding(.horizontal)
    }
    
    // MARK: - Host Pools Status Dashboard
    @ViewBuilder
    private func poolStatusDashboardView(
        t: Tournament,
        division: TournamentDivisionCategory,
        poolAMatches: [TournamentMatch],
        poolBMatches: [TournamentMatch]
    ) -> some View {
        let allPoolMatches = poolAMatches + poolBMatches
        let total = allPoolMatches.count
        let played = allPoolMatches.filter { $0.isCompleted }.count
        let remaining = total - played
        let pct = total > 0 ? Double(played) / Double(total) : 0.0
        let poolAPlayed = poolAMatches.filter { $0.isCompleted }.count
        let poolBPlayed = poolBMatches.filter { $0.isCompleted }.count
        let isComplete = total > 0 && played == total
        let isHostOrAdmin = (dataManager.currentUser?.isRoot == true) || t.isHostOrCoHost(dataManager.currentUser?.id)
        
        VStack(spacing: 12) {
            // Header row with title and status badge
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.caption)
                        .foregroundColor(.cyan)
                    Text("POOLS STATUS")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.cyan)
                }
                
                Spacer()
                
                if isComplete {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 11))
                        Text("ALL PLAYED")
                            .font(.system(size: 10, weight: .black))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.green.opacity(0.2)))
                    .foregroundColor(.green)
                } else {
                    HStack(spacing: 4) {
                        Circle().fill(Color.orange).frame(width: 6, height: 6)
                        Text("IN PROGRESS")
                            .font(.system(size: 10, weight: .black))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.orange.opacity(0.2)))
                    .foregroundColor(.orange)
                }
            }
            
            // Score progress row
            HStack(alignment: .lastTextBaseline) {
                HStack(spacing: 4) {
                    Text("\(played)")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Text("/ \(total)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                    Text("Games Played")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)
                }
                
                Spacer()
                
                Text("\(Int(pct * 100))%")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(isComplete ? .green : .cyan)
            }
            
            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 10)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: isComplete ? [Color.green, Color.mint] : [Color.orange, Color.cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(pct))), height: 10)
                        .animation(.easeInOut(duration: 0.3), value: pct)
                }
            }
            .frame(height: 10)
            
            // Pools breakdown chips
            HStack(spacing: 8) {
                // Pool A chip
                HStack(spacing: 4) {
                    Text("Pool A:")
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    Text("\(poolAPlayed)/\(poolAMatches.count)")
                        .fontWeight(.black)
                        .foregroundColor(poolAPlayed == poolAMatches.count && !poolAMatches.isEmpty ? .green : .white)
                    if poolAPlayed == poolAMatches.count && !poolAMatches.isEmpty {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.green)
                    }
                }
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.05))
                .cornerRadius(8)
                
                // Pool B chip
                HStack(spacing: 4) {
                    Text("Pool B:")
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    Text("\(poolBPlayed)/\(poolBMatches.count)")
                        .fontWeight(.black)
                        .foregroundColor(poolBPlayed == poolBMatches.count && !poolBMatches.isEmpty ? .green : .white)
                    if poolBPlayed == poolBMatches.count && !poolBMatches.isEmpty {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.green)
                    }
                }
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.05))
                .cornerRadius(8)
                
                Spacer()
                
                Text(remaining > 0 ? "\(remaining) to play" : "Ready for Playoffs")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(remaining > 0 ? .orange : .green)
            }
            
            // If all pool games played and playoff bracket not yet generated
            if isComplete && t.bracketMatches(for: division).isEmpty && isHostOrAdmin {
                VStack(spacing: 8) {
                    Divider().background(Color.white.opacity(0.1))
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("All Pool Games Completed!")
                                .font(.footnote)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            Text(t.playoffAdvanceMode == .allTeams ? "Seeds are locked. Advance all teams to single elimination." : "Seeds are locked. Top 2 teams per pool advance to Semifinals.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button {
                            dataManager.generatePlayoffBracket(tournamentId: t.id, division: division)
                            selectedSubTab = .bracket
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "trophy.fill")
                                Text("Start Playoffs")
                                    .fontWeight(.bold)
                            }
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.orange)
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color(red: 0.12, green: 0.14, blue: 0.20), Color(red: 0.09, green: 0.11, blue: 0.16)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isComplete ? Color.green.opacity(0.3) : Color.cyan.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal)
    }
    
    // MARK: - Playoff Bracket Sub-View
    @ViewBuilder
    private func bracketView(t: Tournament, division: TournamentDivisionCategory) -> some View {
        let bracketMatches = t.bracketMatches(for: division)
        let isHostOrAdmin = (dataManager.currentUser?.isRoot == true) || t.isHostOrCoHost(dataManager.currentUser?.id)
        
        VStack(spacing: 16) {
            if bracketMatches.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "trophy")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    
                    Text("Playoff Bracket Not Yet Generated")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(t.playoffAdvanceMode == .allTeams ? "Complete pool play matches first. Every single team advances to the single-elimination playoff bracket!" : "Complete pool play matches first. Top 2 teams from each pool advance to the Semifinals!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    if isHostOrAdmin {
                        Button {
                            dataManager.generatePlayoffBracket(tournamentId: t.id, division: division)
                        } label: {
                            HStack {
                                Image(systemName: "sparkles")
                                Text("Generate Single Elimination Bracket")
                                    .fontWeight(.bold)
                            }
                            .font(.footnote)
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.orange)
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(Color(red: 0.11, green: 0.13, blue: 0.18))
                .cornerRadius(16)
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
                                Button {
                                    selectedTeamForRoster = champTeam
                                } label: {
                                    Text(champTeam.teamName)
                                        .font(.title2)
                                        .fontWeight(.heavy)
                                        .foregroundColor(.white)
                                        .underline(pattern: .dot, color: .orange.opacity(0.6))
                                }
                                .buttonStyle(.plain)
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
                
                // Interactive Tournament Bracket Tree Diagram
                PlayoffBracketChartView(
                    tournament: t,
                    division: division,
                    players: dataManager.players,
                    onSelectMatch: { m in
                        activeSheet = .scoreMatch(m)
                    },
                    onSelectTeam: { team in
                        selectedTeamForRoster = team
                    }
                )
                
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
                            PlayoffCleanMatchCardView(match: m, teams: t.teams, players: dataManager.players, onScore: {
                                activeSheet = .scoreMatch(m)
                            }, onSelectTeam: { team in
                                selectedTeamForRoster = team
                            })
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
                            PlayoffCleanMatchCardView(match: m, teams: t.teams, players: dataManager.players, onScore: {
                                activeSheet = .scoreMatch(m)
                            }, onSelectTeam: { team in
                                selectedTeamForRoster = team
                            })
                        }
                    }
                }
                
                // Semifinals
                let semis = bracketMatches.filter { $0.stage == "semi" || $0.stage == "semifinal" }
                if !semis.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("⚡️ SEMIFINALS (SINGLE ELIMINATION)")
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(.white.opacity(0.85))
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        ForEach(semis) { m in
                            PlayoffCleanMatchCardView(match: m, teams: t.teams, players: dataManager.players, onScore: {
                                activeSheet = .scoreMatch(m)
                            }, onSelectTeam: { team in
                                selectedTeamForRoster = team
                            })
                        }
                    }
                }
                
                // Quarterfinals
                let quarters = bracketMatches.filter { $0.stage == "quarter" || $0.stage == "quarterfinal" }
                if !quarters.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("⚔️ QUARTERFINALS (SINGLE ELIMINATION)")
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(.white.opacity(0.85))
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        ForEach(quarters) { m in
                            PlayoffCleanMatchCardView(match: m, teams: t.teams, players: dataManager.players, onScore: {
                                activeSheet = .scoreMatch(m)
                            }, onSelectTeam: { team in
                                selectedTeamForRoster = team
                            })
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
        let isHostOrAdmin = (dataManager.currentUser?.isRoot == true) || t.isHostOrCoHost(dataManager.currentUser?.id)
        
        VStack(spacing: 16) {
            // Confirmed Teams Section
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("CONFIRMED TEAMS (\(divisionTeams.count)/\(t.maxTeamsPerDivision))")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.orange)
                    Spacer()
                    if isHostOrAdmin {
                        HStack(spacing: 8) {
                            Button {
                                dataManager.addDemoTeams(tournamentId: t.id, division: division, count: 4)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "flask.fill")
                                    Text("Demo Teams")
                                }
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.cyan)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.cyan.opacity(0.15))
                                .cornerRadius(8)
                            }

                            Button {
                                activeSheet = .addTeam
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Team")
                                }
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.orange)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.orange.opacity(0.15))
                                .cornerRadius(8)
                            }
                        }
                    }
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
                            TournamentTeamRowView(
                                team: team,
                                seedNumber: team.seed ?? (index + 1),
                                players: dataManager.players,
                                onInvite: (isHostOrAdmin || (dataManager.currentUser.map { team.containsPlayer($0.id) } ?? false)) ? {
                                    activeSheet = .teamInvite(team)
                                } : nil,
                                onEdit: (isHostOrAdmin || (dataManager.currentUser.map { team.containsPlayer($0.id) } ?? false)) ? {
                                    activeSheet = .editTeam(team)
                                } : nil,
                                onRemove: isHostOrAdmin ? {
                                    teamToRemove = team
                                    showRemoveTeamAlert = true
                                } : nil
                            )
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
                            TournamentFreeAgentRowView(
                                freeAgent: fa,
                                players: dataManager.players,
                                onRemove: isHostOrAdmin ? {
                                    freeAgentToRemove = fa
                                    showRemoveFreeAgentAlert = true
                                } : nil
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .alert("Clear All Rosters?", isPresented: $showClearRostersAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear All", role: .destructive) {
                dataManager.clearTournamentDivisionRosters(tournamentId: t.id, division: division)
            }
        } message: {
            Text("Are you sure you want to remove all \(divisionTeams.count) teams and matches from \(division.displayName)?")
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
    var onInvite: (() -> Void)? = nil
    var onEdit: (() -> Void)? = nil
    var onRemove: (() -> Void)? = nil
    
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
                        Button(action: { onInvite?() }) {
                            HStack(spacing: 3) {
                                Image(systemName: "person.badge.plus")
                                    .font(.system(size: 9))
                                Text("Looking for Partner")
                            }
                            .font(.caption2)
                            .italic()
                            .foregroundColor(.orange)
                        }
                        .buttonStyle(.plain)
                        .disabled(onInvite == nil)
                    }
                }
                
                // Row 2: Player 3 & Player 4 (4v4 only)
                if team.player3Id != nil || team.player4Id != nil || team.division.isQuads {
                    HStack(spacing: 8) {
                        if let p3 = p3 {
                            playerLabel(player: p3, fallback: "Player 3")
                        } else {
                            Button(action: { onInvite?() }) {
                                HStack(spacing: 3) {
                                    Image(systemName: "person.badge.plus")
                                        .font(.system(size: 9))
                                    Text("+ Open Spot")
                                }
                                .font(.caption2)
                                .italic()
                                .foregroundColor(.orange)
                            }
                            .buttonStyle(.plain)
                            .disabled(onInvite == nil)
                        }
                        
                        Text("&")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        if let p4 = p4 {
                            playerLabel(player: p4, fallback: "Player 4")
                        } else {
                            Button(action: { onInvite?() }) {
                                HStack(spacing: 3) {
                                    Image(systemName: "person.badge.plus")
                                        .font(.system(size: 9))
                                    Text("+ Open Spot")
                                }
                                .font(.caption2)
                                .italic()
                                .foregroundColor(.orange)
                            }
                            .buttonStyle(.plain)
                            .disabled(onInvite == nil)
                        }
                    }
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                if let onInvite = onInvite {
                    Button(action: onInvite) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.cyan)
                            .padding(8)
                            .background(Color.cyan.opacity(0.12))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                
                if let onEdit = onEdit {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.orange)
                            .padding(8)
                            .background(Color.orange.opacity(0.12))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                
                if let onRemove = onRemove {
                    Button(action: onRemove) {
                        Image(systemName: "trash")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(red: 0.94, green: 0.27, blue: 0.27))
                            .padding(8)
                            .background(Color.red.opacity(0.12))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
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
    var onRemove: (() -> Void)? = nil
    
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
                
                if let onRemove = onRemove {
                    Button(action: onRemove) {
                        Image(systemName: "trash")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(red: 0.94, green: 0.27, blue: 0.27))
                            .padding(8)
                            .background(Color.red.opacity(0.12))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
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
    var players: [Player] = []
    var onScore: (() -> Void)? = nil
    var onSelectTeam: ((TournamentTeam) -> Void)? = nil
    
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
                        if let team1 = t1 {
                            Button {
                                onSelectTeam?(team1)
                            } label: {
                                Text(team1.teamName)
                                    .font(.system(size: 14, weight: match.winningTeamId == team1.id ? .heavy : .bold))
                                    .foregroundColor(match.winningTeamId == team1.id ? .green : .white)
                                    .lineLimit(1)
                                    .underline(pattern: .dot, color: .white.opacity(0.4))
                            }
                            .buttonStyle(.plain)
                        } else {
                            Text("TBD")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
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
                        if let team2 = t2 {
                            Button {
                                onSelectTeam?(team2)
                            } label: {
                                Text(team2.teamName)
                                    .font(.system(size: 14, weight: match.winningTeamId == team2.id ? .heavy : .bold))
                                    .foregroundColor(match.winningTeamId == team2.id ? .green : .white)
                                    .lineLimit(1)
                                    .underline(pattern: .dot, color: .white.opacity(0.4))
                            }
                            .buttonStyle(.plain)
                        } else {
                            Text("TBD")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
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

// MARK: - Interactive Playoff Bracket Tree View
struct PlayoffBracketChartView: View {
    let tournament: Tournament
    let division: TournamentDivisionCategory
    var players: [Player] = []
    var onSelectMatch: ((TournamentMatch) -> Void)? = nil
    var onSelectTeam: ((TournamentTeam) -> Void)? = nil
    
    private let colWidth: CGFloat = 175
    private let colGap: CGFloat = 36
    
    var body: some View {
        let bracketMatches = tournament.bracketMatches(for: division)
        let quarters = bracketMatches.filter { $0.stage == "quarter" || $0.stage == "quarterfinal" }
        let semis = bracketMatches.filter { $0.stage == "semi" || $0.stage == "semifinal" }
        let finalMatch = bracketMatches.first { $0.stage == "final" }
        
        let hasQuarters = !quarters.isEmpty
        
        if finalMatch == nil && semis.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.bar.doc.horizontal")
                            .foregroundColor(.orange)
                        Text("PLAYOFF BRACKET TREE")
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(.orange)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text("Scroll bracket")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                let totalHeight: CGFloat = hasQuarters ? 350 : 230
                let totalWidth: CGFloat = hasQuarters ? (8 + colWidth * 3 + colGap * 2 + 18) : (8 + colWidth * 2 + colGap + 18)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    ZStack(alignment: .topLeading) {
                        // Connector paths
                        BracketConnectorLines(hasQuarters: hasQuarters, colWidth: colWidth, colGap: colGap)
                            .stroke(Color.white.opacity(0.25), lineWidth: 1.5)
                            .frame(width: totalWidth, height: totalHeight)
                        
                        // Nodes
                        if hasQuarters {
                            let x0: CGFloat = 8
                            let x1: CGFloat = x0 + colWidth + colGap
                            let x2: CGFloat = x1 + colWidth + colGap
                            
                            let yQ0: CGFloat = 42
                            let yQ1: CGFloat = 126
                            let yQ2: CGFloat = 216
                            let yQ3: CGFloat = 300
                            
                            let yS0: CGFloat = (yQ0 + yQ1) / 2
                            let yS1: CGFloat = (yQ2 + yQ3) / 2
                            let yF: CGFloat = (yS0 + yS1) / 2
                            
                            // Quarters
                            if quarters.indices.contains(0) {
                                matchNodeView(match: quarters[0], title: "Quarterfinals #1 (\(quarters[0].courtNumber))", isFinal: false)
                                    .frame(width: colWidth)
                                    .position(x: x0 + colWidth / 2, y: yQ0)
                            }
                            if quarters.indices.contains(1) {
                                matchNodeView(match: quarters[1], title: "Quarterfinals #2 (\(quarters[1].courtNumber))", isFinal: false)
                                    .frame(width: colWidth)
                                    .position(x: x0 + colWidth / 2, y: yQ1)
                            }
                            if quarters.indices.contains(2) {
                                matchNodeView(match: quarters[2], title: "Quarterfinals #3 (\(quarters[2].courtNumber))", isFinal: false)
                                    .frame(width: colWidth)
                                    .position(x: x0 + colWidth / 2, y: yQ2)
                            }
                            if quarters.indices.contains(3) {
                                matchNodeView(match: quarters[3], title: "Quarterfinals #4 (\(quarters[3].courtNumber))", isFinal: false)
                                    .frame(width: colWidth)
                                    .position(x: x0 + colWidth / 2, y: yQ3)
                            }
                            
                            // Semis
                            if semis.indices.contains(0) {
                                matchNodeView(match: semis[0], title: "Semifinals #1 (\(semis[0].courtNumber))", isFinal: false)
                                    .frame(width: colWidth)
                                    .position(x: x1 + colWidth / 2, y: yS0)
                            }
                            if semis.indices.contains(1) {
                                matchNodeView(match: semis[1], title: "Semifinals #2 (\(semis[1].courtNumber))", isFinal: false)
                                    .frame(width: colWidth)
                                    .position(x: x1 + colWidth / 2, y: yS1)
                            }
                            
                            // Final
                            if let finalMatch = finalMatch {
                                matchNodeView(match: finalMatch, title: "Finals (\(finalMatch.courtNumber))", isFinal: true)
                                    .frame(width: colWidth)
                                    .position(x: x2 + colWidth / 2, y: yF)
                            }
                        } else {
                            let x0: CGFloat = 8
                            let x1: CGFloat = x0 + colWidth + colGap
                            
                            let yS0: CGFloat = 55
                            let yS1: CGFloat = 165
                            let yF: CGFloat = (yS0 + yS1) / 2
                            
                            if semis.indices.contains(0) {
                                matchNodeView(match: semis[0], title: "Semifinals #1 (\(semis[0].courtNumber))", isFinal: false)
                                    .frame(width: colWidth)
                                    .position(x: x0 + colWidth / 2, y: yS0)
                            }
                            if semis.indices.contains(1) {
                                matchNodeView(match: semis[1], title: "Semifinals #2 (\(semis[1].courtNumber))", isFinal: false)
                                    .frame(width: colWidth)
                                    .position(x: x0 + colWidth / 2, y: yS1)
                            }
                            if let finalMatch = finalMatch {
                                matchNodeView(match: finalMatch, title: "Finals (\(finalMatch.courtNumber))", isFinal: true)
                                    .frame(width: colWidth)
                                    .position(x: x1 + colWidth / 2, y: yF)
                            }
                        }
                    }
                    .frame(width: totalWidth, height: totalHeight)
                    .padding(.horizontal, 12)
                }
                .padding(.vertical, 8)
                .background(Color(red: 0.08, green: 0.10, blue: 0.14))
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
                .padding(.horizontal)
            }
        }
    }
    
    @ViewBuilder
    private func matchNodeView(match: TournamentMatch, title: String, isFinal: Bool) -> some View {
        let t1 = tournament.teams.first(where: { $0.id == match.team1Id })
        let t2 = tournament.teams.first(where: { $0.id == match.team2Id })
        let isDone = match.isCompleted
        let winner1 = isDone && match.winningTeamId == match.team1Id
        let winner2 = isDone && match.winningTeamId == match.team2Id
        
        Button {
            onSelectMatch?(match)
        } label: {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // Team 1
                HStack(spacing: 5) {
                    Text("\(t1?.seed ?? t1?.poolSeed ?? 1)")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.cyan)
                        .frame(width: 14, height: 14)
                        .background(Color.cyan.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                    
                    if let team1 = t1 {
                        Button {
                            onSelectTeam?(team1)
                        } label: {
                            Text(team1.teamName)
                                .font(.system(size: 11, weight: winner1 ? .bold : .regular))
                                .foregroundColor(winner1 ? .green : .white)
                                .lineLimit(1)
                                .underline(pattern: .dot, color: .white.opacity(0.4))
                        }
                        .buttonStyle(.plain)
                    } else {
                        Text("TBD")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer(minLength: 2)
                    
                    if let s1 = match.team1Score {
                        Text("\(s1)")
                            .font(.system(size: 11, weight: winner1 ? .heavy : .regular))
                            .foregroundColor(winner1 ? .green : .white)
                    }
                }
                
                // Team 2
                HStack(spacing: 5) {
                    Text("\(t2?.seed ?? t2?.poolSeed ?? 2)")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.cyan)
                        .frame(width: 14, height: 14)
                        .background(Color.cyan.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                    
                    if let team2 = t2 {
                        Button {
                            onSelectTeam?(team2)
                        } label: {
                            Text(team2.teamName)
                                .font(.system(size: 11, weight: winner2 ? .bold : .regular))
                                .foregroundColor(winner2 ? .green : .white)
                                .lineLimit(1)
                                .underline(pattern: .dot, color: .white.opacity(0.4))
                        }
                        .buttonStyle(.plain)
                    } else {
                        Text("TBD")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer(minLength: 2)
                    
                    if let s2 = match.team2Score {
                        Text("\(s2)")
                            .font(.system(size: 11, weight: winner2 ? .heavy : .regular))
                            .foregroundColor(winner2 ? .green : .white)
                    }
                }
                
                if isFinal {
                    Text("Winner is champion")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(.orange)
                        .padding(.top, 1)
                }
            }
            .padding(7)
            .background(Color(red: 0.12, green: 0.14, blue: 0.20))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isDone ? Color.green.opacity(0.4) : Color.white.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Orthogonal Bracket Connectors Shape
struct BracketConnectorLines: Shape {
    let hasQuarters: Bool
    let colWidth: CGFloat
    let colGap: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        if hasQuarters {
            let x0: CGFloat = 8
            let x1: CGFloat = x0 + colWidth + colGap
            let x2: CGFloat = x1 + colWidth + colGap
            
            let yQ0: CGFloat = 42
            let yQ1: CGFloat = 126
            let yQ2: CGFloat = 216
            let yQ3: CGFloat = 300
            
            let yS0: CGFloat = (yQ0 + yQ1) / 2
            let yS1: CGFloat = (yQ2 + yQ3) / 2
            let yF: CGFloat = (yS0 + yS1) / 2
            
            let midX0: CGFloat = x0 + colWidth + (colGap / 2)
            
            // Connect Q0 & Q1 to S0
            path.move(to: CGPoint(x: x0 + colWidth, y: yQ0))
            path.addLine(to: CGPoint(x: midX0, y: yQ0))
            path.addLine(to: CGPoint(x: midX0, y: yQ1))
            path.addLine(to: CGPoint(x: x0 + colWidth, y: yQ1))
            path.move(to: CGPoint(x: midX0, y: yS0))
            path.addLine(to: CGPoint(x: x1, y: yS0))
            
            // Connect Q2 & Q3 to S1
            path.move(to: CGPoint(x: x0 + colWidth, y: yQ2))
            path.addLine(to: CGPoint(x: midX0, y: yQ2))
            path.addLine(to: CGPoint(x: midX0, y: yQ3))
            path.addLine(to: CGPoint(x: x0 + colWidth, y: yQ3))
            path.move(to: CGPoint(x: midX0, y: yS1))
            path.addLine(to: CGPoint(x: x1, y: yS1))
            
            // Connect S0 & S1 to F
            let midX1: CGFloat = x1 + colWidth + (colGap / 2)
            path.move(to: CGPoint(x: x1 + colWidth, y: yS0))
            path.addLine(to: CGPoint(x: midX1, y: yS0))
            path.addLine(to: CGPoint(x: midX1, y: yS1))
            path.addLine(to: CGPoint(x: x1 + colWidth, y: yS1))
            path.move(to: CGPoint(x: midX1, y: yF))
            path.addLine(to: CGPoint(x: x2, y: yF))
        } else {
            let x0: CGFloat = 8
            let x1: CGFloat = x0 + colWidth + colGap
            
            let yS0: CGFloat = 55
            let yS1: CGFloat = 165
            let yF: CGFloat = (yS0 + yS1) / 2
            
            let midX0: CGFloat = x0 + colWidth + (colGap / 2)
            
            path.move(to: CGPoint(x: x0 + colWidth, y: yS0))
            path.addLine(to: CGPoint(x: midX0, y: yS0))
            path.addLine(to: CGPoint(x: midX0, y: yS1))
            path.addLine(to: CGPoint(x: x0 + colWidth, y: yS1))
            path.move(to: CGPoint(x: midX0, y: yF))
            path.addLine(to: CGPoint(x: x1, y: yF))
        }
        
        return path
    }
}

// MARK: - Clean Match Card View (Matching Design Reference)
struct PlayoffCleanMatchCardView: View {
    let match: TournamentMatch
    let teams: [TournamentTeam]
    var players: [Player] = []
    var onScore: (() -> Void)? = nil
    var onSelectTeam: ((TournamentTeam) -> Void)? = nil
    
    var body: some View {
        let t1 = teams.first(where: { $0.id == match.team1Id })
        let t2 = teams.first(where: { $0.id == match.team2Id })
        let isCompleted = match.isCompleted
        let winner1 = isCompleted && match.winningTeamId == match.team1Id
        let winner2 = isCompleted && match.winningTeamId == match.team2Id
        
        var roundTitle: String {
            if match.stage == "quarter" || match.stage == "quarterfinal" {
                return "Quarterfinals #\(match.matchNumber) (\(match.courtNumber))"
            } else if match.stage == "semi" || match.stage == "semifinal" {
                return "Semifinals #\(match.matchNumber) (\(match.courtNumber))"
            } else if match.stage == "final" {
                return "Finals (\(match.courtNumber))"
            } else if match.stage == "third_place" {
                return "3rd Place Consolation (\(match.courtNumber))"
            } else {
                return "\(match.stage.uppercased()) (\(match.courtNumber))"
            }
        }
        
        Button {
            onScore?()
        } label: {
            VStack(spacing: 8) {
                // Centered header
                Text(roundTitle)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .center)
                
                HStack(spacing: 12) {
                    VStack(spacing: 6) {
                        // Team 1 row
                        HStack(spacing: 12) {
                            Text(t1 != nil ? "\(t1?.seed ?? t1?.poolSeed ?? 1)" : "-")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.white.opacity(0.45))
                                .frame(width: 20, alignment: .leading)
                            
                            if let team1 = t1 {
                                Button {
                                    onSelectTeam?(team1)
                                } label: {
                                    Text(team1.teamName)
                                        .font(.system(size: 15, weight: winner1 ? .heavy : .medium))
                                        .foregroundColor(winner1 ? .white : .white.opacity(0.85))
                                        .lineLimit(1)
                                        .underline(pattern: .dot, color: .white.opacity(0.4))
                                }
                                .buttonStyle(.plain)
                            } else {
                                Text("TBD")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if let s1 = match.team1Score {
                                Text("\(s1)")
                                    .font(.system(size: 16, weight: winner1 ? .heavy : .bold))
                                    .foregroundColor(winner1 ? .white : .white.opacity(0.7))
                            }
                        }
                        
                        Divider().background(Color.white.opacity(0.08))
                        
                        // Team 2 row
                        HStack(spacing: 12) {
                            Text(t2 != nil ? "\(t2?.seed ?? t2?.poolSeed ?? 2)" : "-")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.white.opacity(0.45))
                                .frame(width: 20, alignment: .leading)
                            
                            if let team2 = t2 {
                                Button {
                                    onSelectTeam?(team2)
                                } label: {
                                    Text(team2.teamName)
                                        .font(.system(size: 15, weight: winner2 ? .heavy : .medium))
                                        .foregroundColor(winner2 ? .white : .white.opacity(0.85))
                                        .lineLimit(1)
                                        .underline(pattern: .dot, color: .white.opacity(0.4))
                                }
                                .buttonStyle(.plain)
                            } else {
                                Text("TBD")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if let s2 = match.team2Score {
                                Text("\(s2)")
                                    .font(.system(size: 16, weight: winner2 ? .heavy : .bold))
                                    .foregroundColor(winner2 ? .white : .white.opacity(0.7))
                            }
                        }
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.35))
                        .padding(.leading, 4)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(red: 0.11, green: 0.13, blue: 0.18))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }
}

// MARK: - Manage Co-Hosts Sheet
struct ManageCoHostsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var dataManager: DataManager
    let tournament: Tournament
    
    @State private var showPicker: Bool = false
    
    private var excludedCoHostIds: Set<UUID> {
        var excluded = Set(tournament.coHostPlayerIds)
        if let hostId = tournament.hostPlayerId {
            _ = excluded.insert(hostId)
        }
        return excluded
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section("Tournament Host (Owner)") {
                    if let host = dataManager.players.first(where: { $0.id == tournament.hostPlayerId }) {
                        HStack(spacing: 12) {
                            PlayerAvatarView(player: host, dimension: 40)
                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 6) {
                                    Text(host.name)
                                        .font(.headline)
                                    if !host.nickname.isEmpty && host.nickname.lowercased() != "player" && host.nickname.lowercased() != host.firstName.lowercased() {
                                        Text("\"\(host.nickname)\"")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.orange)
                                    }
                                    Text("👑 Owner")
                                        .font(.system(size: 10, weight: .black))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(Color.yellow.opacity(0.2)))
                                        .foregroundColor(.yellow)
                                }
                                HStack(spacing: 8) {
                                    if !host.phoneNumber.isEmpty {
                                        HStack(spacing: 3) {
                                            Image(systemName: "phone.fill")
                                                .font(.system(size: 9))
                                            Text(host.formattedPhoneNumber)
                                        }
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    }
                                    Text("\(host.gender.capitalized) • \(host.homeBeach)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    } else {
                        Text("Organizer")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Co-Hosts") {
                    let coHosts = tournament.coHosts(from: dataManager.players)
                    if coHosts.isEmpty {
                        Text("No co-hosts assigned. Co-hosts can manage pools, enter match scores, and run playoffs.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(coHosts) { player in
                            HStack(spacing: 12) {
                                PlayerAvatarView(player: player, dimension: 40)
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 6) {
                                        Text(player.name)
                                            .font(.headline)
                                        if !player.nickname.isEmpty && player.nickname.lowercased() != "player" && player.nickname.lowercased() != player.firstName.lowercased() {
                                            Text("\"\(player.nickname)\"")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.orange)
                                        }
                                    }
                                    HStack(spacing: 8) {
                                        if !player.phoneNumber.isEmpty {
                                            HStack(spacing: 3) {
                                                Image(systemName: "phone.fill")
                                                    .font(.system(size: 9))
                                                Text(player.formattedPhoneNumber)
                                            }
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        }
                                        Text("\(player.gender.capitalized) • \(player.homeBeach)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                                Button(role: .destructive) {
                                    dataManager.removeCoHost(tournamentId: tournament.id, playerId: player.id)
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.borderless)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    
                    Button {
                        showPicker = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "person.badge.plus")
                            Text("Add Co-Host")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.cyan)
                    }
                }
            }
            .navigationTitle("Manage Co-Hosts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showPicker) {
                CoHostPickerSheet(
                    dataManager: dataManager,
                    excludedIds: excludedCoHostIds,
                    onSelect: { player in
                        dataManager.addCoHost(tournamentId: tournament.id, playerId: player.id)
                        showPicker = false
                    }
                )
            }
        }
    }
}

// MARK: - Manual Team Add & Edit Sheet
struct ManualTeamEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var dataManager: DataManager
    let tournament: Tournament
    let preselectedDivision: TournamentDivisionCategory
    let teamToEdit: TournamentTeam?
    
    enum SlotType: String, CaseIterable, Identifiable {
        case registered = "Registered"
        case guest = "Guest"
        case none = "Open Spot"
        var id: String { rawValue }
    }
    
    @State private var teamName: String
    @State private var selectedDivision: TournamentDivisionCategory
    @State private var selectedPool: String
    
    // Player 1 (Captain)
    @State private var isP1Guest: Bool = false
    @State private var player1Id: UUID
    @State private var p1GuestName: String = ""
    
    // Player 2
    @State private var p2SlotType: SlotType = .registered
    @State private var player2Id: UUID?
    @State private var p2GuestName: String = ""
    
    // Player 3 (4v4)
    @State private var p3SlotType: SlotType = .none
    @State private var player3Id: UUID?
    @State private var p3GuestName: String = ""
    
    // Player 4 (4v4)
    @State private var p4SlotType: SlotType = .none
    @State private var player4Id: UUID?
    @State private var p4GuestName: String = ""
    
    init(dataManager: DataManager, tournament: Tournament, preselectedDivision: TournamentDivisionCategory, teamToEdit: TournamentTeam?) {
        self.dataManager = dataManager
        self.tournament = tournament
        self.preselectedDivision = preselectedDivision
        self.teamToEdit = teamToEdit
        
        let initialDiv = teamToEdit?.division ?? preselectedDivision
        _selectedDivision = State(initialValue: initialDiv)
        _teamName = State(initialValue: teamToEdit?.teamName ?? "")
        _selectedPool = State(initialValue: teamToEdit?.poolName ?? "Auto")
        
        let p1 = teamToEdit?.player1Id ?? dataManager.currentUser?.id ?? dataManager.players.first?.id ?? UUID()
        _player1Id = State(initialValue: p1)
        _player2Id = State(initialValue: teamToEdit?.player2Id)
        _player3Id = State(initialValue: teamToEdit?.player3Id)
        _player4Id = State(initialValue: teamToEdit?.player4Id)
        
        _p2SlotType = State(initialValue: (teamToEdit?.player2Id != nil) ? .registered : .none)
        _p3SlotType = State(initialValue: (teamToEdit?.player3Id != nil) ? .registered : .none)
        _p4SlotType = State(initialValue: (teamToEdit?.player4Id != nil) ? .registered : .none)
    }
    
    private var is4v4: Bool {
        selectedDivision.isQuads || tournament.teamFormat == .quads4v4
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Team Information") {
                    TextField("Team Name", text: $teamName)
                    
                    Picker("Division", selection: $selectedDivision) {
                        ForEach(tournament.allowedDivisions, id: \.self) { div in
                            Text(div.displayName).tag(div)
                        }
                    }
                    
                    Picker("Pool Assignment", selection: $selectedPool) {
                        Text("Auto / None").tag("Auto")
                        Text("Pool A").tag("Pool A")
                        Text("Pool B").tag("Pool B")
                    }
                }
                
                Section("Player 1 (Captain)") {
                    Toggle("Guest / Non-Registered Player", isOn: $isP1Guest)
                    if isP1Guest {
                        TextField("Enter captain's full name", text: $p1GuestName)
                    } else {
                        Picker("Select Player", selection: $player1Id) {
                            ForEach(dataManager.players) { p in
                                Text(p.name).tag(p.id)
                            }
                        }
                    }
                }
                
                Section("Player 2") {
                    Picker("Slot Type", selection: $p2SlotType) {
                        Text("Registered").tag(SlotType.registered)
                        Text("Guest").tag(SlotType.guest)
                        Text("Open / Looking").tag(SlotType.none)
                    }
                    .pickerStyle(.segmented)
                    
                    if p2SlotType == .registered {
                        Picker("Select Partner", selection: Binding(
                            get: { player2Id ?? UUID(uuidString: "00000000-0000-0000-0000-000000000000")! },
                            set: { player2Id = ($0.uuidString == "00000000-0000-0000-0000-000000000000") ? nil : $0 }
                        )) {
                            ForEach(dataManager.players.filter { $0.id != player1Id }) { p in
                                Text(p.name).tag(p.id)
                            }
                        }
                    } else if p2SlotType == .guest {
                        TextField("Enter partner's full name", text: $p2GuestName)
                    }
                }
                
                if is4v4 {
                    Section("Player 3") {
                        Picker("Slot Type", selection: $p3SlotType) {
                            Text("Registered").tag(SlotType.registered)
                            Text("Guest").tag(SlotType.guest)
                            Text("Open Spot").tag(SlotType.none)
                        }
                        .pickerStyle(.segmented)
                        
                        if p3SlotType == .registered {
                            Picker("Select Player 3", selection: Binding(
                                get: { player3Id ?? UUID(uuidString: "00000000-0000-0000-0000-000000000000")! },
                                set: { player3Id = ($0.uuidString == "00000000-0000-0000-0000-000000000000") ? nil : $0 }
                            )) {
                                ForEach(dataManager.players.filter { $0.id != player1Id && $0.id != player2Id }) { p in
                                    Text(p.name).tag(p.id)
                                }
                            }
                        } else if p3SlotType == .guest {
                            TextField("Enter player 3 full name", text: $p3GuestName)
                        }
                    }
                    
                    Section("Player 4") {
                        Picker("Slot Type", selection: $p4SlotType) {
                            Text("Registered").tag(SlotType.registered)
                            Text("Guest").tag(SlotType.guest)
                            Text("Open Spot").tag(SlotType.none)
                        }
                        .pickerStyle(.segmented)
                        
                        if p4SlotType == .registered {
                            Picker("Select Player 4", selection: Binding(
                                get: { player4Id ?? UUID(uuidString: "00000000-0000-0000-0000-000000000000")! },
                                set: { player4Id = ($0.uuidString == "00000000-0000-0000-0000-000000000000") ? nil : $0 }
                            )) {
                                ForEach(dataManager.players.filter { $0.id != player1Id && $0.id != player2Id && $0.id != player3Id }) { p in
                                    Text(p.name).tag(p.id)
                                }
                            }
                        } else if p4SlotType == .guest {
                            TextField("Enter player 4 full name", text: $p4GuestName)
                        }
                    }
                }
            }
            .navigationTitle(teamToEdit == nil ? "Add Team Manually" : "Edit Team & Players")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(teamToEdit == nil ? "Add Team" : "Save Changes") {
                        let pool = (selectedPool == "Auto" || selectedPool.isEmpty) ? nil : selectedPool
                        let defaultTier: RatingTier = selectedDivision.isNovice ? .novice : .intermediate
                        
                        var finalP1Id = player1Id
                        if isP1Guest && !p1GuestName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            finalP1Id = dataManager.getOrCreateGuestPlayer(name: p1GuestName, rating: defaultTier).id
                        }
                        
                        var finalP2Id = player2Id
                        if p2SlotType == .guest && !p2GuestName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            finalP2Id = dataManager.getOrCreateGuestPlayer(name: p2GuestName, rating: defaultTier).id
                        } else if p2SlotType == .none {
                            finalP2Id = nil
                        }
                        
                        var finalP3Id = player3Id
                        if p3SlotType == .guest && !p3GuestName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            finalP3Id = dataManager.getOrCreateGuestPlayer(name: p3GuestName, rating: defaultTier).id
                        } else if p3SlotType == .none {
                            finalP3Id = nil
                        }
                        
                        var finalP4Id = player4Id
                        if p4SlotType == .guest && !p4GuestName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            finalP4Id = dataManager.getOrCreateGuestPlayer(name: p4GuestName, rating: defaultTier).id
                        } else if p4SlotType == .none {
                            finalP4Id = nil
                        }
                        
                        if let existing = teamToEdit {
                            dataManager.updateTournamentTeam(
                                tournamentId: tournament.id,
                                teamId: existing.id,
                                teamName: teamName,
                                player1Id: finalP1Id,
                                player2Id: finalP2Id,
                                player3Id: finalP3Id,
                                player4Id: finalP4Id,
                                division: selectedDivision,
                                poolName: pool
                            )
                        } else {
                            dataManager.addTeamToTournament(
                                tournamentId: tournament.id,
                                teamName: teamName,
                                division: selectedDivision,
                                player1Id: finalP1Id,
                                player2Id: finalP2Id,
                                player3Id: finalP3Id,
                                player4Id: finalP4Id,
                                poolName: pool
                            )
                        }
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
}

// MARK: - Edit Pool Play Sheet
struct EditPoolPlaySheet: View {
    @Environment(\.dismiss) private var dismiss
    let tournament: Tournament
    let division: TournamentDivisionCategory
    @ObservedObject var dataManager: DataManager
    
    @State private var teamPools: [UUID: String] = [:]
    
    init(tournament: Tournament, division: TournamentDivisionCategory, dataManager: DataManager) {
        self.tournament = tournament
        self.division = division
        self.dataManager = dataManager
        
        var initial: [UUID: String] = [:]
        let teams = tournament.teams(for: division)
        for (idx, team) in teams.enumerated() {
            initial[team.id] = team.poolName ?? (idx % 2 == 0 ? "Pool A" : "Pool B")
        }
        _teamPools = State(initialValue: initial)
    }
    
    private var divisionTeams: [TournamentTeam] {
        tournament.teams(for: division)
    }
    
    private var poolACount: Int {
        teamPools.values.filter { $0 == "Pool A" }.count
    }
    
    private var poolBCount: Int {
        teamPools.values.filter { $0 == "Pool B" }.count
    }
    
    private func teamElo(_ team: TournamentTeam) -> Int {
        let pIds = team.allPlayerIds
        let teamPlayers = dataManager.players.filter { pIds.contains($0.id) }
        guard !teamPlayers.isEmpty else { return 1500 }
        let total = teamPlayers.reduce(0) { $0 + $1.eloRating }
        return total / teamPlayers.count
    }
    
    private func snakeSeed() {
        var sorted = divisionTeams
        sorted.sort { teamElo($0) > teamElo($1) }
        for (idx, team) in sorted.enumerated() {
            let isPoolA = (idx % 4 == 0 || idx % 4 == 3)
            teamPools[team.id] = isPoolA ? "Pool A" : "Pool B"
        }
    }
    
    private func swapPools() {
        for (teamId, pool) in teamPools {
            teamPools[teamId] = (pool == "Pool A") ? "Pool B" : "Pool A"
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Pool A")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.cyan)
                            Text("\(poolACount) Teams")
                                .font(.title3)
                                .fontWeight(.black)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Pool B")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                            Text("\(poolBCount) Teams")
                                .font(.title3)
                                .fontWeight(.black)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 4)
                    
                    HStack(spacing: 12) {
                        Button {
                            snakeSeed()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "wand.and.stars")
                                Text("Snake Seed")
                            }
                            .font(.caption)
                            .fontWeight(.semibold)
                        }
                        .buttonStyle(.bordered)
                        
                        Button {
                            swapPools()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.left.arrow.right")
                                Text("Swap Pools")
                            }
                            .font(.caption)
                            .fontWeight(.semibold)
                        }
                        .buttonStyle(.bordered)
                    }
                } header: {
                    Text("Pool Balance (\(division.displayName))")
                }
                
                Section("Assign Teams to Pools") {
                    ForEach(divisionTeams) { team in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(team.teamName)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                
                                let p1 = dataManager.player(for: team.player1Id).displayName
                                let p2 = team.player2Id.map { dataManager.player(for: $0).displayName }
                                Text([p1, p2].compactMap { $0 }.joined(separator: " / "))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Picker("", selection: Binding(
                                get: { teamPools[team.id] ?? "Pool A" },
                                set: { teamPools[team.id] = $0 }
                            )) {
                                Text("Pool A").tag("Pool A")
                                Text("Pool B").tag("Pool B")
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 140)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .navigationTitle("Edit Pool Play")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save & Update") {
                        dataManager.updatePoolAssignments(
                            tournamentId: tournament.id,
                            division: division,
                            assignments: teamPools
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

// MARK: - Team Roster Sheet
struct TeamRosterSheet: View {
    @Environment(\.dismiss) private var dismiss
    let team: TournamentTeam
    let tournament: Tournament
    @ObservedObject var dataManager: DataManager
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(team.teamName)
                            .font(.title2)
                            .fontWeight(.black)
                            .foregroundColor(.white)
                        HStack(spacing: 8) {
                            Text(team.division.displayName)
                                .font(.caption).fontWeight(.semibold)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Capsule().fill(Color.orange.opacity(0.2))).foregroundColor(.orange)
                            if let pool = team.poolName {
                                Text(pool)
                                    .font(.caption).fontWeight(.semibold)
                                    .padding(.horizontal, 8).padding(.vertical, 3)
                                    .background(Capsule().fill(Color.cyan.opacity(0.2))).foregroundColor(.cyan)
                            }
                            if let seed = team.seed ?? team.poolSeed {
                                Text("Seed #\(seed)").font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                Section("Roster & Players") {
                    let playerSlots: [(id: UUID?, role: String)] = [
                        (team.player1Id, "Captain"),
                        (team.player2Id, "Partner"),
                        (team.player3Id, "Player 3"),
                        (team.player4Id, "Player 4")
                    ]
                    ForEach(playerSlots.filter { $0.id != nil }, id: \.role) { slot in
                        if let pid = slot.id {
                            let player = dataManager.player(for: pid)
                            HStack(spacing: 12) {
                                PlayerAvatarView(player: player, dimension: 40)
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Text(player.displayName).font(.subheadline).fontWeight(.bold)
                                        Text(slot.role).font(.system(size: 10, weight: .bold))
                                            .padding(.horizontal, 6).padding(.vertical, 2)
                                            .background(Capsule().fill(slot.role == "Captain" ? Color.orange.opacity(0.2) : Color.white.opacity(0.1)))
                                            .foregroundColor(slot.role == "Captain" ? .orange : .white.opacity(0.8))
                                    }
                                    Text("\(player.rating.rawValue) • Elo \(player.eloRating) • \(player.homeBeach)").font(.caption2).foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                
                Section {
                    let shareURLString = "https://runwildlovestronglivefree.org/volleyballmatch/?tournamentId=\(tournament.id.uuidString)&teamId=\(team.id.uuidString)"
                    if let url = URL(string: shareURLString) {
                        ShareLink(
                            item: url,
                            subject: Text("Join \(team.teamName)"),
                            message: Text("Join my team '\(team.teamName)' for \(tournament.title)!\n\(shareURLString)")
                        ) {
                            HStack {
                                Label("Invite Teammates to Join", systemImage: "person.badge.plus")
                                    .foregroundColor(.orange)
                                    .fontWeight(.semibold)
                                Spacer()
                                Image(systemName: "square.and.arrow.up")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Team Roster")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
