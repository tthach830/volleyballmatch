import SwiftUI

public struct RootView: View {
    @StateObject private var dataManager = DataManager.shared
    @ObservedObject private var notificationService = NotificationService.shared
    @State private var selectedTab: Int = DataManager.shared.currentUser == nil ? 2 : 0
    @State private var deepLinkedGame: SetGame? = nil
    
    public init() {}
    
    public var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $selectedTab) {
                // Tab 0: Set Games (Gated for non-logged-in users)
                Group {
                    if dataManager.currentUser != nil {
                        ConfirmedGamesView(dataManager: dataManager)
                    } else {
                        AuthGateView(
                            title: "Set Games",
                            icon: "figure.volleyball",
                            subtitle: "Log in or create an account to view upcoming matches, teams, and court details.",
                            dataManager: dataManager
                        )
                    }
                }
                .tabItem {
                    Label("Set Games", systemImage: "figure.volleyball")
                }
                .tag(0)
                
                // Tab 1: Auto-Match (Gated for non-logged-in users)
                Group {
                    if dataManager.currentUser != nil {
                        AutoMatchmakerView(dataManager: dataManager)
                    } else {
                        AuthGateView(
                            title: "Auto-Match",
                            icon: "sparkles",
                            subtitle: "Log in to post your availability windows and join instant pickup games.",
                            dataManager: dataManager
                        )
                    }
                }
                .tabItem {
                    Label("Auto-Match", systemImage: "sparkles")
                }
                .tag(1)
                
                // Tab 2: Ladders (Always Accessible!)
                LaddersView(dataManager: dataManager)
                    .tabItem {
                        Label("Ladders", systemImage: "trophy.fill")
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
                    selectedTab = 2
                }
            }
            .onChange(of: dataManager.currentUser) { newUser in
                if newUser != nil {
                    selectedTab = 0
                } else {
                    selectedTab = 2
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
        .onOpenURL { url in
            handleIncomingURL(url)
        }
    }
    
    private func handleIncomingURL(_ url: URL) {
        guard dataManager.currentUser != nil else { return }
        // Supported formats:
        // setgames://game?id=<uuid>
        // https://volleyballmatch-13d66.web.app/?gameId=<uuid>
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return }
        let targetId = components.queryItems?.first(where: { 
            let name = $0.name.lowercased()
            return name == "id" || name == "gameid" || name == "join"
        })?.value
        
        guard let idString = targetId?.trimmingCharacters(in: .whitespacesAndNewlines), !idString.isEmpty else { return }
        
        if let targetGame = dataManager.games.first(where: { 
            $0.id.uuidString.lowercased() == idString.lowercased() || $0.rawId == idString 
        }) {
            selectedTab = 0
            deepLinkedGame = targetGame
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
