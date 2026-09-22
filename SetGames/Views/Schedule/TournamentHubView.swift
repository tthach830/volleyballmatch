import SwiftUI

public struct TournamentHubView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var dataManager: DataManager
    
    public enum TournamentHubSheet: Identifiable {
        case create
        case edit(Tournament)
        
        public var id: String {
            switch self {
            case .create: return "create"
            case .edit(let t): return "edit-\(t.id.uuidString)"
            }
        }
    }
    
    @State private var selectedFilter: TournamentFilter = .upcoming
    @State private var activeSheet: TournamentHubSheet? = nil
    @State private var tournamentToDelete: Tournament? = nil
    @State private var selectedTournamentForDetail: Tournament? = nil
    
    public enum TournamentFilter: String, CaseIterable {
        case upcoming = "📅 Upcoming"
        case myTournaments = "🤝 My Tournaments"
        case past = "📜 Past"
    }
    
    public init(dataManager: DataManager) {
        self.dataManager = dataManager
    }
    
    private var filteredTournaments: [Tournament] {
        let currentUserId = dataManager.currentUser?.id
        let now = Date()
        
        switch selectedFilter {
        case .upcoming:
            return dataManager.tournaments.filter { $0.status != "completed" }
                .sorted { $0.date < $1.date }
        case .myTournaments:
            guard let uid = currentUserId else { return [] }
            return dataManager.tournaments.filter { $0.isPlayerRegistered(uid) || $0.isHostOrCoHost(uid) }
                .sorted { $0.date < $1.date }
        case .past:
            return dataManager.tournaments.filter { $0.status == "completed" || $0.date < now.addingTimeInterval(-86400) }
                .sorted { $0.date > $1.date }
        }
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    
                    // Filter Capsule Bar
                    HStack(spacing: 0) {
                        ForEach(Array(TournamentFilter.allCases.enumerated()), id: \.offset) { index, filter in
                            if index > 0 {
                                Rectangle()
                                    .fill(Color.white.opacity(0.18))
                                    .frame(width: 1, height: 14)
                            }
                            Button {
                                selectedFilter = filter
                            } label: {
                                Text(filter.rawValue)
                                    .font(.system(size: 13, weight: selectedFilter == filter ? .bold : .medium))
                                    .foregroundColor(selectedFilter == filter ? .white : .white.opacity(0.65))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .background(Color(red: 0.11, green: 0.13, blue: 0.17))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 0.8))
                    .padding(.horizontal)
                    .padding(.top, 4)
                    
                    // Empty State or List
                    if filteredTournaments.isEmpty {
                        VStack(spacing: 14) {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.orange.opacity(0.6))
                            Text("No Tournaments in this view")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Tap '+ Host Tournament' to organize a beach tournament!")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Button {
                                activeSheet = .create
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Host Tournament")
                                }
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.orange)
                                .clipShape(Capsule())
                            }
                            .padding(.top, 4)
                        }
                        .padding(50)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredTournaments) { tournament in
                                NavigationLink(destination: TournamentDetailView(dataManager: dataManager, tournamentId: tournament.id)) {
                                    TournamentCardView(tournament: tournament, dataManager: dataManager)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    let isHostOrAdmin = (dataManager.currentUser?.isRoot == true) || tournament.isHostOrCoHost(dataManager.currentUser?.id)
                                    let isPrimaryHostOrAdmin = (dataManager.currentUser?.isRoot == true) || (tournament.hostPlayerId != nil && tournament.hostPlayerId == dataManager.currentUser?.id)
                                    if isHostOrAdmin {
                                        Button {
                                            activeSheet = .edit(tournament)
                                        } label: {
                                            Label("Edit Tournament", systemImage: "pencil")
                                        }
                                        
                                        if isPrimaryHostOrAdmin {
                                            Button(role: .destructive) {
                                                tournamentToDelete = tournament
                                            } label: {
                                                Label("Delete Tournament", systemImage: "trash")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 30)
            }
            .background(Color(red: 0.08, green: 0.09, blue: 0.12).ignoresSafeArea())
            .navigationTitle("Beach Tournaments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        activeSheet = .create
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                            Text("Host Tournament")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.orange)
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .create:
                    CreateTournamentSheet(dataManager: dataManager)
                case .edit(let tourn):
                    CreateTournamentSheet(dataManager: dataManager, tournamentToEdit: tourn)
                }
            }
            .alert("Delete Tournament?", isPresented: Binding(
                get: { tournamentToDelete != nil },
                set: { if !$0 { tournamentToDelete = nil } }
            )) {
                Button("Cancel", role: .cancel) { tournamentToDelete = nil }
                Button("Delete", role: .destructive) {
                    if let tourn = tournamentToDelete {
                        dataManager.deleteTournament(id: tourn.id)
                        tournamentToDelete = nil
                    }
                }
            } message: {
                if let tourn = tournamentToDelete {
                    Text("Are you sure you want to delete \"\(tourn.title)\"? This cannot be undone.")
                }
            }
        }
    }
}

// Tournament Card Component
struct TournamentCardView: View {
    let tournament: Tournament
    @ObservedObject var dataManager: DataManager
    
    private var isUserRegistered: Bool {
        guard let user = dataManager.currentUser else { return false }
        return tournament.isPlayerRegistered(user.id)
    }
    
    private var isUserHost: Bool {
        guard let user = dataManager.currentUser else { return false }
        return tournament.hostPlayerId == user.id
    }
    
    private var isUserCoHost: Bool {
        guard let user = dataManager.currentUser else { return false }
        return tournament.coHostPlayerIds.contains(user.id)
    }
    
    private var poolStatusBadge: (played: Int, total: Int)? {
        let poolM = tournament.matches.filter { $0.stage == "pool" }
        guard !poolM.isEmpty else { return nil }
        return (poolM.filter { $0.isCompleted }.count, poolM.count)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // Header Row
            HStack {
                HStack(spacing: 6) {
                    Text("🏆")
                    Text(tournament.title)
                        .font(.headline)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                }
                Spacer()
                
                if isUserHost {
                    Text("👑 Host")
                        .font(.system(size: 10, weight: .black))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.yellow.opacity(0.2)))
                        .foregroundColor(.yellow)
                } else if isUserCoHost {
                    Text("👥 Co-Host")
                        .font(.system(size: 10, weight: .black))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.blue.opacity(0.2)))
                        .foregroundColor(.cyan)
                }
                
                if isUserRegistered {
                    Text("🟢 Registered")
                        .font(.system(size: 10, weight: .black))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.green.opacity(0.2)))
                        .foregroundColor(.green)
                }
                
                if let pool = poolStatusBadge {
                    Text("\(pool.played)/\(pool.total) Pools")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(pool.played == pool.total ? Color.green.opacity(0.2) : Color.orange.opacity(0.2)))
                        .foregroundColor(pool.played == pool.total ? .green : .orange)
                }
                
                Text("\(tournament.teamFormat.icon) \(tournament.teamFormat.displayName)")
                    .font(.system(size: 10, weight: .black))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.cyan.opacity(0.2)))
                    .foregroundColor(.cyan)
            }
            
            // Date & Location
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    Text(tournament.formattedDate)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.caption2)
                        .foregroundColor(.cyan)
                    Text("\(tournament.location) • \(tournament.courts.count) Courts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider().background(Color.white.opacity(0.1))
            
            // Division Badges Row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(tournament.allowedDivisions) { div in
                        HStack(spacing: 4) {
                            Text(div.icon)
                            Text(div.displayName)
                                .font(.system(size: 11, weight: .bold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.08))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                    }
                }
            }
            
            // Footer: Teams Count
            HStack {
                Text("\(tournament.teams.count) Teams Registered • \(tournament.freeAgents.count) Free Agents")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color(red: 0.12, green: 0.14, blue: 0.19), Color(red: 0.08, green: 0.10, blue: 0.15)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
}
