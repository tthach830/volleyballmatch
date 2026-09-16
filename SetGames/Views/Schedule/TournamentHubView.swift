import SwiftUI

public struct TournamentHubView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var dataManager: DataManager
    
    @State private var selectedFilter: TournamentFilter = .upcoming
    @State private var showCreateTournamentSheet: Bool = false
    @State private var tournamentToEdit: Tournament? = nil
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
            return dataManager.tournaments.filter { $0.isPlayerRegistered(uid) || $0.hostPlayerId == uid }
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
                                    let isHostOrAdmin = (dataManager.currentUser?.isRoot == true) || (tournament.hostPlayerId != nil && tournament.hostPlayerId == dataManager.currentUser?.id)
                                    if isHostOrAdmin {
                                        Button {
                                            tournamentToEdit = tournament
                                        } label: {
                                            Label("Edit Tournament", systemImage: "pencil")
                                        }
                                        
                                        Button(role: .destructive) {
                                            tournamentToDelete = tournament
                                        } label: {
                                            Label("Delete Tournament", systemImage: "trash")
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
                        showCreateTournamentSheet = true
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
            .sheet(isPresented: $showCreateTournamentSheet) {
                CreateTournamentSheet(dataManager: dataManager)
            }
            .sheet(item: $tournamentToEdit) { tourn in
                CreateTournamentSheet(dataManager: dataManager, tournamentToEdit: tourn)
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
                
                if isUserRegistered {
                    Text("🟢 Registered")
                        .font(.system(size: 10, weight: .black))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.green.opacity(0.2)))
                        .foregroundColor(.green)
                } else {
                    Text("Open")
                        .font(.system(size: 10, weight: .black))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.orange.opacity(0.2)))
                        .foregroundColor(.orange)
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
