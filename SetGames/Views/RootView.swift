import SwiftUI

public struct RootView: View {
    @StateObject private var dataManager = DataManager.shared
    @ObservedObject private var notificationService = NotificationService.shared
    @State private var selectedTab: Int = 0
    @State private var deepLinkedGame: SetGame? = nil
    
    public init() {}
    
    public var body: some View {
        ZStack(alignment: .top) {
            Group {
                if dataManager.currentUser == nil {
                    AuthView(dataManager: dataManager)
                } else {
                    TabView(selection: $selectedTab) {
                        ConfirmedGamesView(dataManager: dataManager)
                            .tabItem {
                                Label("Set Games", systemImage: "figure.volleyball")
                            }
                            .tag(0)
                        
                        AutoMatchmakerView(dataManager: dataManager)
                            .tabItem {
                                Label("Auto-Match", systemImage: "sparkles")
                            }
                            .tag(1)
                        
                        LaddersView(dataManager: dataManager)
                            .tabItem {
                                Label("Ladders", systemImage: "trophy.fill")
                            }
                            .tag(2)
                        
                        ProfileView(dataManager: dataManager)
                            .tabItem {
                                Label("Profile", systemImage: "person.crop.circle.fill")
                            }
                            .tag(3)
                    }
                    .tint(.orange)
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
