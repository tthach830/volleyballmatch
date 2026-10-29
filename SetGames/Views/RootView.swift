import SwiftUI

public struct RootView: View {
    @StateObject private var dataManager = DataManager.shared
    @ObservedObject private var notificationService = NotificationService.shared
    @State private var selectedTab: Int = DataManager.shared.currentUser == nil ? 1 : 0
    @State private var deepLinkedGame: SetGame? = nil
    @State private var deepLinkedTournament: Tournament? = nil
    @State private var pendingDeepLinkURL: URL? = nil
    @State private var pendingJoinTeamInfo: (tournamentId: UUID, teamId: UUID)? = nil
    @State private var showResetPasswordSheet: Bool = false
    @State private var resetPasswordPhone: String = "4087869405"
    
    public init() {}
    
    public var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $selectedTab) {
                // Tab 0: Games (Gated for non-logged-in users)
                Group {
                    if dataManager.currentUser != nil {
                        ConfirmedGamesView(dataManager: dataManager)
                    } else {
                        AuthGateView(
                            title: "Games",
                            icon: "figure.volleyball",
                            subtitle: "Log in or create an account to view upcoming matches, teams, and court details.",
                            dataManager: dataManager
                        )
                    }
                }
                .tabItem {
                    Label("Games", systemImage: "figure.volleyball")
                }
                .tag(0)
                
                // Tab 1: Ladders (Always Accessible!)
                LaddersView(dataManager: dataManager)
                    .tabItem {
                        Label("Ladders", systemImage: "trophy.fill")
                    }
                    .tag(1)
                
                // Tab 2: Volleyball? (Weekly Weather Forecast & Suitability)
                VolleyballWeatherView(dataManager: dataManager)
                    .tabItem {
                        Label("Volleyball?", systemImage: "sun.max.fill")
                    }
                    .tag(2)
                
                // Tab 3: Profile (Gated for non-logged-in users)
                Group {
                    if dataManager.currentUser != nil {
                        ProfileView(dataManager: dataManager)
                    } else {
                        AuthGateView(
                            title: "Profile",
                            icon: "person.crop.circle.fill",
                            subtitle: "Log in or sign up to view your volleyball record, Elo stats, and connections.",
                            dataManager: dataManager
                        )
                    }
                }
                .tabItem {
                    Label(dataManager.currentUser != nil ? "Profile" : "Log In", systemImage: "person.crop.circle.fill")
                }
                .tag(3)
            }
            .tint(.orange)
            .onAppear {
                if dataManager.currentUser == nil {
                    selectedTab = 1
                }
                logTabScreen(selectedTab)
            }
            .onChange(of: selectedTab) { _, newTab in
                logTabScreen(newTab)
            }
            .onChange(of: dataManager.currentUser?.id) { oldId, newId in
                if oldId == nil && newId != nil {
                    // Fresh login: navigate to Set Games
                    selectedTab = 0
                    if let pending = pendingJoinTeamInfo, let user = dataManager.currentUser {
                        let res = dataManager.joinTournamentTeam(tournamentId: pending.tournamentId, teamId: pending.teamId, playerId: user.id)
                        if !res.success {
                            dataManager.postNotification(title: "Team Invite", message: res.message, type: .tournament)
                        }
                        if let targetTournament = dataManager.tournaments.first(where: { $0.id == pending.tournamentId }) {
                            deepLinkedTournament = targetTournament
                        }
                        pendingJoinTeamInfo = nil
                    }
                } else if oldId != nil && newId == nil {
                    // Logged out: fallback to Ladders
                    selectedTab = 1
                }
            }
            
            .onChange(of: dataManager.tournaments.count) { _, count in
                if count > 0, let pendingURL = pendingDeepLinkURL {
                    handleIncomingURL(pendingURL)
                }
            }
            .onChange(of: dataManager.games.count) { _, count in
                if count > 0, let pendingURL = pendingDeepLinkURL {
                    handleIncomingURL(pendingURL)
                }
            }
            
            if notificationService.showToast, let toast = notificationService.latestToast {
                NotificationToastView(notification: toast) {
                    withAnimation {
                        notificationService.showToast = false
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(999)
                .padding(.top, 8)
            }
        }
        .sheet(item: $deepLinkedGame) { game in
            NavigationStack {
                GameDetailView(dataManager: dataManager, gameId: game.id)
            }
        }
        .sheet(item: $deepLinkedTournament) { tournament in
            NavigationStack {
                TournamentDetailView(dataManager: dataManager, tournamentId: tournament.id)
            }
        }
        .sheet(isPresented: $showResetPasswordSheet) {
            ForgotPasswordSheet(dataManager: dataManager, initialPhone: resetPasswordPhone)
        }
        .onOpenURL { url in
            handleIncomingURL(url)
        }
    }
    
    private func handleIncomingURL(_ url: URL) {
        // Supported formats:
        // setgames://game?id=<uuid>
        // setgames://tournament?id=<uuid>&teamId=<uuid>
        // setgames://resetPassword?phone=<phone>
        // https://volleyballmatch-13d66.web.app/?gameId=<uuid>
        // https://volleyballmatch-13d66.web.app/?tournamentId=<uuid>&teamId=<uuid>
        // https://runwildlovestronglivefree.org/volleyballmatch/?resetPhone=<phone>
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return }
        
        let resetPhoneParam = components.queryItems?.first(where: {
            let name = $0.name.lowercased()
            return name == "resetphone" || name == "forgotphone" || name == "reset" || (url.host?.lowercased() == "resetpassword" && name == "phone")
        })?.value
        
        if let phone = resetPhoneParam?.trimmingCharacters(in: .whitespacesAndNewlines), !phone.isEmpty {
            resetPasswordPhone = phone
            showResetPasswordSheet = true
            return
        }
        
        let tournamentIdParam = components.queryItems?.first(where: {
            let name = $0.name.lowercased()
            return name == "tournamentid" || name == "tournid"
        })?.value
        
        let teamIdParam = components.queryItems?.first(where: {
            let name = $0.name.lowercased()
            return name == "teamid" || name == "team" || name == "jointeam"
        })?.value
        
        if let tournIdString = tournamentIdParam?.trimmingCharacters(in: .whitespacesAndNewlines), !tournIdString.isEmpty {
            if let targetTournament = dataManager.tournaments.first(where: {
                $0.id.uuidString.lowercased() == tournIdString.lowercased() ||
                ($0.rawId != nil && $0.rawId?.caseInsensitiveCompare(tournIdString) == .orderedSame)
            }) {
                pendingDeepLinkURL = nil
                selectedTab = 0
                deepLinkedTournament = targetTournament
                handleTeamJoinIfPresent(tournament: targetTournament, teamIdParam: teamIdParam)
                return
            } else {
                pendingDeepLinkURL = url
                return
            }
        }
        
        let isTournamentHost = url.host?.lowercased() == "tournament" || url.path.lowercased().contains("tournament")
        let targetId = components.queryItems?.first(where: { 
            let name = $0.name.lowercased()
            return name == "id" || name == "gameid" || name == "join"
        })?.value
        
        guard let idString = targetId?.trimmingCharacters(in: .whitespacesAndNewlines), !idString.isEmpty else { return }
        
        if isTournamentHost {
            if let targetTournament = dataManager.tournaments.first(where: {
                $0.id.uuidString.lowercased() == idString.lowercased() ||
                ($0.rawId != nil && $0.rawId?.caseInsensitiveCompare(idString) == .orderedSame)
            }) {
                pendingDeepLinkURL = nil
                selectedTab = 0
                deepLinkedTournament = targetTournament
                handleTeamJoinIfPresent(tournament: targetTournament, teamIdParam: teamIdParam)
                return
            } else {
                pendingDeepLinkURL = url
                return
            }
        }
        
        if let targetGame = dataManager.games.first(where: { 
            $0.id.uuidString.lowercased() == idString.lowercased() || $0.rawId == idString 
        }) {
            pendingDeepLinkURL = nil
            selectedTab = 0
            deepLinkedGame = targetGame
        } else if let targetTournament = dataManager.tournaments.first(where: {
            $0.id.uuidString.lowercased() == idString.lowercased() ||
            ($0.rawId != nil && $0.rawId?.caseInsensitiveCompare(idString) == .orderedSame)
        }) {
            pendingDeepLinkURL = nil
            selectedTab = 0
            deepLinkedTournament = targetTournament
            handleTeamJoinIfPresent(tournament: targetTournament, teamIdParam: teamIdParam)
        } else {
            pendingDeepLinkURL = url
        }
    }
    
    private func handleTeamJoinIfPresent(tournament: Tournament, teamIdParam: String?) {
        guard let rawTeamId = teamIdParam?.trimmingCharacters(in: .whitespacesAndNewlines), !rawTeamId.isEmpty else { return }
        let matchedTeam = tournament.teams.first(where: {
            $0.id.uuidString.lowercased() == rawTeamId.lowercased() ||
            $0.teamName.caseInsensitiveCompare(rawTeamId) == .orderedSame
        })
        guard let targetTeam = matchedTeam else { return }
        
        if let user = dataManager.currentUser {
            let result = dataManager.joinTournamentTeam(tournamentId: tournament.id, teamId: targetTeam.id, playerId: user.id)
            if !result.success {
                dataManager.postNotification(
                    title: "Team Invite",
                    message: result.message,
                    type: .tournament
                )
            }
            pendingJoinTeamInfo = nil
        } else {
            pendingJoinTeamInfo = (tournamentId: tournament.id, teamId: targetTeam.id)
            dataManager.postNotification(
                title: "Join \(targetTeam.teamName)! 🏐",
                message: "Sign up or log in to join \(targetTeam.teamName)!",
                type: .tournament
            )
            selectedTab = 3 // Direct user to Profile / Auth tab
        }
    }
    
    private func logTabScreen(_ tab: Int) {
        let screens = ["Games", "Ladders", "Volleyball?", "Profile"]
        if tab >= 0 && tab < screens.count {
            AnalyticsService.shared.logScreenView(screenName: screens[tab])
        }
    }
}

public struct AuthGateView: View {
    @ObservedObject var dataManager: DataManager
    let title: String
    let icon: String
    let subtitle: String
    @State private var showAuthSheet: Bool = false
    
    public init(title: String, icon: String, subtitle: String, dataManager: DataManager) {
        self.title = title
        self.icon = icon
        self.subtitle = subtitle
        self.dataManager = dataManager
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.12))
                        .frame(width: 96, height: 96)
                    
                    Image(systemName: icon)
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundColor(.orange)
                    
                    Image(systemName: "lock.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.orange)
                        .clipShape(Circle())
                        .offset(x: 30, y: 30)
                }
                
                VStack(spacing: 8) {
                    Text("Log In to Access \(title)")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                VStack(spacing: 12) {
                    Button {
                        showAuthSheet = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "person.crop.circle.badge.plus")
                            Text("Log In / Sign Up")
                        }
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: Color.orange.opacity(0.35), radius: 8, y: 4)
                    }
                    .padding(.horizontal, 36)
                    
                    Text("Beach Ladders are free to browse without logging in.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showAuthSheet) {
                AuthView(dataManager: dataManager)
            }
        }
    }
}
