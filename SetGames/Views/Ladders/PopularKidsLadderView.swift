import SwiftUI

public struct PopularKidsLadderView: View {
    @ObservedObject var dataManager: DataManager
    
    public init(dataManager: DataManager) {
        self.dataManager = dataManager
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            // Explain the ladder
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("👑 THE POPULAR KIDS LADDER")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.purple)
                    
                    Spacer()
                    
                    Image(systemName: "person.3.fill")
                        .foregroundColor(.purple)
                }
                
                Text("Who plays with the most different people?")
                    .font(.system(size: 16, weight: .bold))
                
                Text("Ranked by the number of unique teammates and opponents played with. These are the community connectors who make beach volleyball fun and welcoming for everyone!")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(14)
            .background(Color.purple.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal)
            
            let popularKids = StatsManager.shared.popularKidsLadder(from: dataManager.players)
            
            LazyVStack(spacing: 10) {
                ForEach(Array(popularKids.enumerated()), id: \.element.id) { index, player in
                    HStack(spacing: 12) {
                        // Rank
                        ZStack {
                            if index == 0 {
                                Text("👑")
                                    .font(.system(size: 24))
                            } else if index == 1 {
                                Text("🌟")
                                    .font(.system(size: 22))
                            } else if index == 2 {
                                Text("🤝")
                                    .font(.system(size: 20))
                            } else {
                                Text("#\(index + 1)")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(width: 32)
                        
                        PlayerAvatarView(player: player, dimension: 44)
                        
                        // Name & Community Title
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(player.name)
                                    .font(.system(size: 15, weight: .bold))
                                
                                if player.id == dataManager.currentUser?.id {
                                    Text("YOU")
                                        .font(.system(size: 9, weight: .black))
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 1.5)
                                        .background(Color.purple.opacity(0.2))
                                        .foregroundColor(.purple)
                                        .clipShape(Capsule())
                                }
                            }
                            
                            Text(player.popularKidsTitle)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.purple)
                            
                            HStack(spacing: 6) {
                                RatingBadge(rating: player.rating, size: .small)
                                
                                Text("\(player.totalMatches) games total")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        // Unique Connections Count
                        VStack(alignment: .trailing, spacing: 2) {
                            HStack(spacing: 3) {
                                Image(systemName: "person.2.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.purple)
                                Text("\(player.uniqueConnectionsCount)")
                                    .font(.system(size: 20, weight: .black, design: .rounded))
                                    .foregroundColor(.primary)
                            }
                            
                            Text("different players")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(index == 0 ? Color.purple.opacity(0.08) : Color(UIColor.secondarySystemGroupedBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(index == 0 ? Color.purple.opacity(0.3) : Color.clear, lineWidth: 1.5)
                    )
                    .padding(.horizontal)
                }
            }
        }
    }
}
