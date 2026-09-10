import Foundation

public class StatsManager {
    public static let shared = StatsManager()
    
    public init() {}
    
    /// Deduplicates players sharing the same phone number or normalized name, retaining the most active profile
    public func deduplicatePlayers(_ players: [Player]) -> [Player] {
        var grouped: [String: Player] = [:]
        
        for player in players {
            let phoneDigits = player.phoneNumber.filter { $0.isNumber }
            let key: String
            if phoneDigits.count >= 7 {
                key = "phone:\(phoneDigits)"
            } else {
                let trimmedName = player.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                if !trimmedName.isEmpty {
                    key = "name:\(trimmedName)"
                } else {
                    key = "id:\(player.id.uuidString.lowercased())"
                }
            }
            
            if let existing = grouped[key] {
                let existingMatches = existing.totalMatches
                let newMatches = player.totalMatches
                if newMatches > existingMatches {
                    grouped[key] = player
                } else if newMatches == existingMatches && player.eloRating > existing.eloRating {
                    grouped[key] = player
                } else if newMatches == existingMatches && !player.phoneNumber.isEmpty && existing.phoneNumber.isEmpty {
                    grouped[key] = player
                }
            } else {
                grouped[key] = player
            }
        }
        
        return Array(grouped.values)
    }
    
    /// Generates top competitive ladder ranked by Elo rating, then Win Rate and Wins
    public func topPlayersLadder(from players: [Player], filterTier: RatingTier? = nil) -> [Player] {
        let deduped = deduplicatePlayers(players)
        var filtered = deduped.filter { !$0.isStatsHidden }
        if let tier = filterTier {
            filtered = filtered.filter { $0.rating == tier }
        }
        
        return filtered.sorted { p1, p2 in
            if p1.eloRating != p2.eloRating {
                return p1.eloRating > p2.eloRating
            }
            if p1.winRate != p2.winRate {
                return p1.winRate > p2.winRate
            }
            return p1.wins > p2.wins
        }
    }
    
    /// Recalculates and merges unique partner and opponent IDs dynamically from all scheduled and past matches
    public func recalculateConnections(players: [Player], games: [SetGame]) -> [Player] {
        guard !games.isEmpty else { return players }
        var updated = players
        for i in 0..<updated.count {
            let pid = updated[i].id
            var partners = Set(updated[i].uniquePartnerIds)
            var opponents = Set(updated[i].uniqueOpponentIds)
            
            for g in games {
                let isGameCompleted = g.status == .completed
                let subMatches = !g.subMatches.isEmpty ? g.subMatches : [SubMatch(courtNumber: g.courtNumber, team1PlayerIds: g.team1PlayerIds, team2PlayerIds: g.team2PlayerIds, isCompleted: isGameCompleted)]
                for m in subMatches {
                    let hasScores = (m.team1Score != nil && m.team2Score != nil && (m.team1Score! > 0 || m.team2Score! > 0))
                    guard m.isCompleted || isGameCompleted || hasScores else { continue }
                    
                    let t1 = Set(m.team1PlayerIds)
                    let t2 = Set(m.team2PlayerIds)
                    if t1.contains(pid) {
                        for p in t1 where p != pid { partners.insert(p) }
                        for o in t2 { opponents.insert(o) }
                    } else if t2.contains(pid) {
                        for p in t2 where p != pid { partners.insert(p) }
                        for o in t1 { opponents.insert(o) }
                    }
                }
            }
            updated[i].uniquePartnerIds = Array(partners)
            updated[i].uniqueOpponentIds = Array(opponents)
        }
        return updated
    }
    
    /// Generates "The Popular Kids" ladder ranked by unique players played with
    public func popularKidsLadder(from players: [Player], games: [SetGame] = []) -> [Player] {
        let connectedPlayers = games.isEmpty ? players : recalculateConnections(players: players, games: games)
        let deduped = deduplicatePlayers(connectedPlayers)
        let visiblePlayers = deduped.filter { !$0.isStatsHidden }
        return visiblePlayers.sorted { p1, p2 in
            let c1 = p1.uniqueConnectionsCount
            let c2 = p2.uniqueConnectionsCount
            if c1 != c2 {
                return c1 > c2
            }
            // Tie break by total matches played
            return p1.totalMatches > p2.totalMatches
        }
    }
    
    /// Updates player stats after a match result is entered
    public func applyMatchResult(
        game: inout SetGame,
        winningTeam: Int,
        setScores: [SetScore],
        players: inout [Player]
    ) {
        game.status = .completed
        game.winningTeam = winningTeam
        game.setScores = setScores
        
        let team1Ids = Set(game.team1PlayerIds)
        let team2Ids = Set(game.team2PlayerIds)
        
        // Sum points
        let team1Points = setScores.reduce(0) { $0 + $1.team1Score }
        let team2Points = setScores.reduce(0) { $0 + $1.team2Score }
        
        for i in 0..<players.count {
            let pid = players[i].id
            let isTeam1 = team1Ids.contains(pid)
            let isTeam2 = team2Ids.contains(pid)
            
            guard isTeam1 || isTeam2 else { continue }
            
            let won = (isTeam1 && winningTeam == 1) || (isTeam2 && winningTeam == 2)
            
            if won {
                players[i].wins += 1
                players[i].streak = max(1, players[i].streak + 1)
                players[i].eloRating += 24
                players[i].recentForm.append(true)
            } else {
                players[i].losses += 1
                players[i].streak = min(-1, players[i].streak - 1)
                players[i].eloRating = max(800, players[i].eloRating - 20)
                players[i].recentForm.append(false)
            }
            
            if players[i].recentForm.count > 5 {
                players[i].recentForm.removeFirst()
            }
            
            if isTeam1 {
                players[i].pointsScored += team1Points
                players[i].pointsAllowed += team2Points
                // Teammates and opponents tracking for "The Popular Kids"
                for partnerId in team1Ids where partnerId != pid {
                    if !players[i].uniquePartnerIds.contains(partnerId) {
                        players[i].uniquePartnerIds.append(partnerId)
                    }
                }
                for oppId in team2Ids {
                    if !players[i].uniqueOpponentIds.contains(oppId) {
                        players[i].uniqueOpponentIds.append(oppId)
                    }
                }
            } else {
                players[i].pointsScored += team2Points
                players[i].pointsAllowed += team1Points
                for partnerId in team2Ids where partnerId != pid {
                    if !players[i].uniquePartnerIds.contains(partnerId) {
                        players[i].uniquePartnerIds.append(partnerId)
                    }
                }
                for oppId in team1Ids {
                    if !players[i].uniqueOpponentIds.contains(oppId) {
                        players[i].uniqueOpponentIds.append(oppId)
                    }
                }
            }
        }
    }
    
    /// Updates player career stats when an individual sub-match is scored
    public func applySubMatchResult(
        subMatch: inout SubMatch,
        players: inout [Player]
    ) {
        guard let s1 = subMatch.team1Score, let s2 = subMatch.team2Score, subMatch.isCompleted else { return }
        let winningTeam = s1 > s2 ? 1 : 2
        
        // If stats were already applied with the same winner, do not duplicate
        if subMatch.appliedStatsWinner == winningTeam {
            return
        }
        
        // If stats were previously applied with a DIFFERENT winner, revert previous stats first
        if let prevWinner = subMatch.appliedStatsWinner, prevWinner != winningTeam {
            revertSubMatchResult(subMatch: subMatch, previousWinningTeam: prevWinner, players: &players)
        }
        
        let team1Ids = Set(subMatch.team1PlayerIds)
        let team2Ids = Set(subMatch.team2PlayerIds)
        
        for i in 0..<players.count {
            let pid = players[i].id
            let isTeam1 = team1Ids.contains(pid)
            let isTeam2 = team2Ids.contains(pid)
            guard isTeam1 || isTeam2 else { continue }
            
            let won = (isTeam1 && winningTeam == 1) || (isTeam2 && winningTeam == 2)
            let myScore = isTeam1 ? s1 : s2
            let oppScore = isTeam1 ? s2 : s1
            
            if won {
                players[i].wins += 1
                players[i].streak = max(1, players[i].streak + 1)
                players[i].eloRating += 24
                players[i].recentForm.append(true)
            } else {
                players[i].losses += 1
                players[i].streak = min(-1, players[i].streak - 1)
                players[i].eloRating = max(800, players[i].eloRating - 20)
                players[i].recentForm.append(false)
            }
            
            if players[i].recentForm.count > 5 {
                players[i].recentForm.removeFirst()
            }
            
            players[i].pointsScored += myScore
            players[i].pointsAllowed += oppScore
            players[i].consecutiveBackouts = 0 // Clear flaker backout streak
            
            let myTeam = isTeam1 ? team1Ids : team2Ids
            let oppTeam = isTeam1 ? team2Ids : team1Ids
            for partnerId in myTeam where partnerId != pid {
                if !players[i].uniquePartnerIds.contains(partnerId) {
                    players[i].uniquePartnerIds.append(partnerId)
                }
            }
            for oppId in oppTeam {
                if !players[i].uniqueOpponentIds.contains(oppId) {
                    players[i].uniqueOpponentIds.append(oppId)
                }
            }
        }
        
        subMatch.appliedStatsWinner = winningTeam
    }
    
    /// Reverts previously applied sub-match stats if a match score is corrected
    public func revertSubMatchResult(
        subMatch: SubMatch,
        previousWinningTeam: Int,
        players: inout [Player]
    ) {
        guard let s1 = subMatch.team1Score, let s2 = subMatch.team2Score else { return }
        let team1Ids = Set(subMatch.team1PlayerIds)
        let team2Ids = Set(subMatch.team2PlayerIds)
        
        for i in 0..<players.count {
            let pid = players[i].id
            let isTeam1 = team1Ids.contains(pid)
            let isTeam2 = team2Ids.contains(pid)
            guard isTeam1 || isTeam2 else { continue }
            
            let prevWon = (isTeam1 && previousWinningTeam == 1) || (isTeam2 && previousWinningTeam == 2)
            let myScore = isTeam1 ? s1 : s2
            let oppScore = isTeam1 ? s2 : s1
            
            if prevWon {
                players[i].wins = max(0, players[i].wins - 1)
                players[i].eloRating = max(800, players[i].eloRating - 24)
            } else {
                players[i].losses = max(0, players[i].losses - 1)
                players[i].eloRating += 20
            }
            players[i].pointsScored = max(0, players[i].pointsScored - myScore)
            players[i].pointsAllowed = max(0, players[i].pointsAllowed - oppScore)
            if !players[i].recentForm.isEmpty {
                players[i].recentForm.removeLast()
            }
        }
    }
}
