import Foundation

public struct MatchResult {
    public var matchedPlayers: [Player]
    public var team1: [Player]
    public var team2: [Player]
    public var averageTier: RatingTier
    public var scheduledDate: Date
    public var courtName: String
    public var matchingMethod: String
}

public class MatchmakingEngine {
    public static let shared = MatchmakingEngine()
    
    public init() {}
    
    /// Finds a balanced 4-player game among available players and slots
    public func findAutoMatches(
        slots: [AvailabilitySlot],
        players: [Player],
        targetTier: RatingTier? = nil,
        preferredBeach: String? = nil
    ) -> [MatchResult] {
        var results: [MatchResult] = []
        let playerLookup = Dictionary(players.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        
        // Group slots by beach and date
        let cal = Calendar.current
        var slotsByDayBeach: [String: [AvailabilitySlot]] = [:]
        
        for slot in slots where !slot.isMatched {
            let dayKey = cal.startOfDay(for: slot.date).description
            let beachKey = slot.preferredBeach
            let groupKey = "\(dayKey)_\(beachKey)"
            slotsByDayBeach[groupKey, default: []].append(slot)
        }
        
        for (_, groupSlots) in slotsByDayBeach {
            // Need at least 4 available slots
            guard groupSlots.count >= 4 else { continue }
            
            // Sort by tier compatibility
            let sortedSlots = groupSlots.sorted {
                let p1 = playerLookup[$0.playerId]
                let p2 = playerLookup[$1.playerId]
                return (p1?.rating.levelScore ?? 0) < (p2?.rating.levelScore ?? 0)
            }
            
            // Slide window of 4
            var index = 0
            while index + 3 < sortedSlots.count {
                let candidateSlots = Array(sortedSlots[index..<index+4])
                let candidatePlayers = candidateSlots.compactMap { playerLookup[$0.playerId] }
                
                if candidatePlayers.count == 4 {
                    // Check rating parity: difference between highest and lowest <= 2 tiers
                    let scores = candidatePlayers.map { $0.rating.levelScore }
                    let minScore = scores.min() ?? 0
                    let maxScore = scores.max() ?? 0
                    
                    if maxScore - minScore <= 2 {
                        // Balance teams: 1st & 4th vs 2nd & 3rd sorted by Elo
                        let sortedByElo = candidatePlayers.sorted { $0.eloRating > $1.eloRating }
                        let team1 = [sortedByElo[0], sortedByElo[3]]
                        let team2 = [sortedByElo[1], sortedByElo[2]]
                        
                        let avgLevel = Int(round(Double(scores.reduce(0, +)) / 4.0))
                        let matchedTier = RatingTier.allCases.first(where: { $0.levelScore == avgLevel }) ?? .b
                        
                        let match = MatchResult(
                            matchedPlayers: candidatePlayers,
                            team1: team1,
                            team2: team2,
                            averageTier: matchedTier,
                            scheduledDate: candidateSlots[0].startTime,
                            courtName: "\(candidateSlots[0].preferredBeach) - Court #\(Int.random(in: 1...6))",
                            matchingMethod: "Smart Availability Matcher"
                        )
                        results.append(match)
                        index += 4
                        continue
                    }
                }
                index += 1
            }
        }
        
        return results
    }
    
    /// Calculates compatibility score (0 - 100%) between a player and an existing open game
    public func calculateCompatibility(player: Player, game: SetGame) -> Int {
        // Tier difference penalty
        let tierDiff = game.effectiveAllowedRatings.map { abs(player.rating.levelScore - $0.levelScore) }.min() ?? 0
        var score = 100
        
        if tierDiff == 0 {
            score = 98
        } else if tierDiff == 1 {
            score = 82
        } else if tierDiff == 2 {
            score = 55
        } else {
            score = 25
        }
        
        // Bonus if spots are urgently open
        if game.spotsRemaining == 1 {
            score = min(100, score + 2)
        }
        
        return score
    }
}
