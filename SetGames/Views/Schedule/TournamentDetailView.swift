import SwiftUI

public struct TournamentDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var dataManager: DataManager
    let tournamentId: UUID
    
    @State private var selectedDivision: TournamentDivisionCategory = .coedNovice2v2
    @State private var selectedSubTab: SubTab = .roster
    @State private var showSignUpSheet: Bool = false
    @State private var showLeaveAlert: Bool = false
    @State private var showEditTournamentSheet: Bool = false
    @State private var showDeleteTournamentAlert: Bool = false
    @State private var editingMatch: TournamentMatch? = nil
    @State private var scoreTeam1: String = ""
    @State private var scoreTeam2: String = ""
    @State private var winningTeamNumber: Int = 1
    
    public enum SubTab: String, CaseIterable {
        case roster = "👥 Teams & Free Agents"
        case matches = "🏆 Bracket & Matches"
        case info = "📋 Format & Info"
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
                            
                            // SUB-TAB PICKER (Teams, Bracket, Info)
                            Picker("View Mode", selection: $selectedSubTab) {
                                ForEach(SubTab.allCases, id: \.self) { tab in
                                    Text(tab.rawValue).tag(tab)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)
                            
                            // TAB CONTENT
                            switch selectedSubTab {
                            case .roster:
                                rosterView(t: t, division: selectedDivision)
                            case .matches:
                                matchesView(t: t, division: selectedDivision)
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
    
    // MARK: - Matches & Bracket Sub-View
    @ViewBuilder
    private func matchesView(t: Tournament, division: TournamentDivisionCategory) -> some View {
        let matches = t.matches(for: division)
        
        VStack(spacing: 14) {
            if matches.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "trophy")
                        .font(.system(size: 40))
                        .foregroundColor(.orange.opacity(0.6))
                    Text("Bracket will be seeded once registration closes!")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Teams will be placed into matches across courts automatically.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(40)
                .background(Color(red: 0.11, green: 0.13, blue: 0.18))
                .cornerRadius(20)
                .padding(.horizontal)
            } else {
                ForEach(matches) { m in
                    TournamentMatchRowView(match: m, teams: t.teams)
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
                Text(team.teamName)
                    .font(.headline)
                    .foregroundColor(.white)
                
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
    
    var body: some View {
        let t1 = teams.first(where: { $0.id == match.team1Id })
        let t2 = teams.first(where: { $0.id == match.team2Id })
        
        VStack(spacing: 8) {
            HStack {
                Text("Round \(match.roundNumber) • Match \(match.matchNumber)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                Spacer()
                Text(match.courtNumber)
                    .font(.caption2)
                    .foregroundColor(.cyan)
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text(t1?.teamName ?? "TBD")
                        .fontWeight(match.winningTeamId == t1?.id ? .heavy : .medium)
                        .foregroundColor(match.winningTeamId == t1?.id ? .green : .white)
                }
                Spacer()
                if let s1 = match.team1Score, let s2 = match.team2Score {
                    Text("\(s1) - \(s2)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                } else {
                    Text("vs")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text(t2?.teamName ?? "TBD")
                        .fontWeight(match.winningTeamId == t2?.id ? .heavy : .medium)
                        .foregroundColor(match.winningTeamId == t2?.id ? .green : .white)
                }
            }
        }
        .padding(14)
        .background(Color(red: 0.11, green: 0.13, blue: 0.18))
        .cornerRadius(14)
        .padding(.horizontal)
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
