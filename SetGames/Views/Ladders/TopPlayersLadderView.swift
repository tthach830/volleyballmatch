import SwiftUI

public struct TopPlayersLadderView: View {
    @ObservedObject var dataManager: DataManager
    @State private var selectedTierFilter: RatingTier? = nil
    
    public init(dataManager: DataManager) {
        self.dataManager = dataManager
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            // Tier Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button {
                        selectedTierFilter = nil
                    } label: {
                        Text("All Tiers")
                            .font(.system(size: 12, weight: .bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedTierFilter == nil ? Color.orange : Color(UIColor.secondarySystemGroupedBackground))
                            .foregroundColor(selectedTierFilter == nil ? .white : .primary)
                            .clipShape(Capsule())
                    }
                    
                    ForEach(RatingTier.allCases) { tier in
                        Button {
                            selectedTierFilter = tier
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: tier.iconName)
                                    .font(.system(size: 11))
                                Text(tier.rawValue)
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedTierFilter == tier ? tier.badgeColor : Color(UIColor.secondarySystemGroupedBackground))
                            .foregroundColor(selectedTierFilter == tier ? .white : .primary)
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Ladder List
            let rankedPlayers = StatsManager.shared.topPlayersLadder(from: dataManager.players, filterTier: selectedTierFilter)
            
            if rankedPlayers.isEmpty {
                VStack(spacing: 8) {
                    Text("No players in this rating tier yet.")
                        .foregroundColor(.secondary)
                }
                .padding(40)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(Array(rankedPlayers.enumerated()), id: \.element.id) { index, player in
                        HStack(spacing: 12) {
                            // Rank number / medal
                            ZStack {
                                if index == 0 {
                                    Text("🥇")
                                        .font(.system(size: 22))
                                } else if index == 1 {
                                    Text("🥈")
                                        .font(.system(size: 22))
                                } else if index == 2 {
                                    Text("🥉")
                                        .font(.system(size: 22))
                                } else {
                                    Text("#\(index + 1)")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(width: 32)
                            
                            // Player Avatar
                            PlayerAvatarView(player: player, dimension: 44)
                            
                            // Name & Beach
                            VStack(alignment: .leading, spacing: 3) {
                                HStack {
                                    Text(player.name)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.primary)
                                    
                                    if player.id == dataManager.currentUser?.id {
                                        Text("YOU")
                                            .font(.system(size: 9, weight: .black))
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 1.5)
                                            .background(Color.orange.opacity(0.2))
                                            .foregroundColor(.orange)
                                            .clipShape(Capsule())
                                    }
                                }
                                
                                HStack(spacing: 6) {
                                    RatingBadge(rating: player.rating, size: .small)
                                    
                                    Text(player.homeBeach)
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            
                            Spacer()
                            
                            // Win / Loss & Win Rate
                            VStack(alignment: .trailing, spacing: 3) {
                                Text(player.winRateFormatted)
                                    .font(.system(size: 15, weight: .black, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                Text(player.formattedRecord)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 2) {
                                    ForEach(Array(player.recentForm.suffix(4).enumerated()), id: \.offset) { _, won in
                                        Circle()
                                            .fill(won ? Color.green : Color.red.opacity(0.8))
                                            .frame(width: 6, height: 6)
                                    }
                                }
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(player.id == dataManager.currentUser?.id ? Color.orange.opacity(0.08) : Color(UIColor.secondarySystemGroupedBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(player.id == dataManager.currentUser?.id ? Color.orange.opacity(0.4) : Color.clear, lineWidth: 1.5)
                        )
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
}
