import SwiftUI

public struct LaddersView: View {
    @ObservedObject var dataManager: DataManager
    @State private var selectedTab: LadderTab = .popularKids
    
    public enum LadderTab: String, CaseIterable {
        case topPlayers = "🏆 Top Players"
        case popularKids = "👑 Popular Kids"
    }
    
    public init(dataManager: DataManager) {
        self.dataManager = dataManager
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Picker("Ladder Type", selection: $selectedTab) {
                        ForEach(LadderTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    if selectedTab == .topPlayers {
                        TopPlayersLadderView(dataManager: dataManager)
                    } else {
                        PopularKidsLadderView(dataManager: dataManager)
                    }
                }
                .padding(.bottom, 30)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Beach Ladders")
        }
    }
}
