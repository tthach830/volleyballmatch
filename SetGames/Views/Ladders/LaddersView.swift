import SwiftUI

public struct LaddersView: View {
    @ObservedObject var dataManager: DataManager
    @State private var selectedTab: LadderTab = .popularKids
    @State private var selectedTimeframe: StatsManager.LadderTimeframe = .month
    @State private var showAuthSheet: Bool = false
    
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
                    // Header row: Beach Ladders + Month / Year checkboxes
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .center, spacing: 12) {
                            Text("Beach Ladders")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            // Month checkbox
                            Button {
                                if selectedTimeframe == .month {
                                    selectedTimeframe = .allTime
                                } else {
                                    selectedTimeframe = .month
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: selectedTimeframe == .month ? "checkmark.square.fill" : "square")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(selectedTimeframe == .month ? .orange : .secondary)
                                    Text("Month")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(selectedTimeframe == .month ? .primary : .secondary)
                                }
                            }
                            .buttonStyle(.plain)
                            
                            // Year checkbox
                            Button {
                                if selectedTimeframe == .year {
                                    selectedTimeframe = .allTime
                                } else {
                                    selectedTimeframe = .year
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: selectedTimeframe == .year ? "checkmark.square.fill" : "square")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(selectedTimeframe == .year ? .orange : .secondary)
                                    Text("Year")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(selectedTimeframe == .year ? .primary : .secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Text(subtitleText)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    Picker("Ladder Type", selection: $selectedTab) {
                        ForEach(LadderTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    if selectedTab == .topPlayers {
                        TopPlayersLadderView(dataManager: dataManager, timeframe: selectedTimeframe)
                    } else {
                        PopularKidsLadderView(dataManager: dataManager, timeframe: selectedTimeframe)
                    }
                }
                .padding(.bottom, 30)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if dataManager.currentUser == nil {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showAuthSheet = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "person.crop.circle.badge.plus")
                                Text("Log In")
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.orange)
                        }
                    }
                }
            }
            .sheet(isPresented: $showAuthSheet) {
                AuthView(dataManager: dataManager)
            }
        }
    }
    
    private var subtitleText: String {
        switch selectedTimeframe {
        case .month:
            return "Last 30 days rankings and social catalysts on the sand"
        case .year:
            return "Past year rankings and social catalysts on the sand"
        case .allTime:
            return "All-time rankings and social catalysts on the sand"
        }
    }
}
