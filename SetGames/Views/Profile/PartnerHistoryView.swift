import SwiftUI

public struct PartnerHistoryView: View {
    @ObservedObject var dataManager: DataManager
    let player: Player
    
    public init(dataManager: DataManager, player: Player) {
        self.dataManager = dataManager
        self.player = player
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                // Popular Kids Network Header
                VStack(spacing: 8) {
                    Text(player.popularKidsTitle)
                        .font(.system(size: 14, weight: .bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.15))
                        .foregroundColor(.purple)
                        .clipShape(Capsule())
                    
                    Text("\(player.uniqueConnectionsCount) Unique Players")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Played with or against across all scheduled set games")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                
                // Partners Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("FREQUENT TEAMMATES")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    let partnerPlayers = player.uniquePartnerIds.compactMap { pid in
                        dataManager.players.first(where: { $0.id == pid })
                    }
                    
                    if partnerPlayers.isEmpty {
                        Text("No recorded teammates yet. Join an auto-matched set game!")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(partnerPlayers) { p in
                            connectionRow(p, relation: "Teammate")
                        }
                    }
                }
                
                // Opponents Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("FREQUENT OPPONENTS")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    let opponentPlayers = player.uniqueOpponentIds.compactMap { pid in
                        dataManager.players.first(where: { $0.id == pid })
                    }
                    
                    if opponentPlayers.isEmpty {
                        Text("No recorded opponents yet.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(opponentPlayers) { p in
                            connectionRow(p, relation: "Opponent")
                        }
                    }
                }
            }
            .padding(.bottom, 30)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Volleyball Network")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func connectionRow(_ p: Player, relation: String) -> some View {
        HStack(spacing: 12) {
            PlayerAvatarView(player: p, dimension: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(p.name)
                    .font(.system(size: 15, weight: .bold))
                HStack(spacing: 6) {
                    RatingBadge(rating: p.rating, size: .small)
                    Text("• \(relation)")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(p.formattedRecord)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
    }
}
