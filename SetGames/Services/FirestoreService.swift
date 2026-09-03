import Foundation
import Combine
import FirebaseFirestore

public class FirestoreService: ObservableObject {
    public static let shared = FirestoreService()
    
    private let db = Firestore.firestore()
    private var playersListener: ListenerRegistration?
    private var gamesListener: ListenerRegistration?
    private var slotsListener: ListenerRegistration?
    
    private init() {
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings()
        db.settings = settings
    }
    
    deinit {
        stopListening()
    }
    
    private func sanitizeForJSON(_ value: Any) -> Any {
        if let timestamp = value as? Timestamp {
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return iso.string(from: timestamp.dateValue())
        } else if let date = value as? Date {
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return iso.string(from: date)
        } else if let dict = value as? [String: Any] {
            return dict.mapValues { sanitizeForJSON($0) }
        } else if let array = value as? [Any] {
            return array.map { sanitizeForJSON($0) }
        } else {
            return value
        }
    }
    
    public func startListening(
        onPlayersUpdate: @escaping ([Player]) -> Void,
        onGamesUpdate: @escaping ([SetGame]) -> Void,
        onSlotsUpdate: @escaping ([AvailabilitySlot]) -> Void
    ) {
        // Real-time listener for Players
        playersListener = db.collection("players").addSnapshotListener { [weak self] snapshot, error in
            guard let self = self, let documents = snapshot?.documents, error == nil else { return }
            let decoder = JSONDecoder()
            let players: [Player] = documents.compactMap { doc in
                do {
                    let safeDict = self.sanitizeForJSON(doc.data())
                    let data = try JSONSerialization.data(withJSONObject: safeDict)
                    return try decoder.decode(Player.self, from: data)
                } catch {
                    print("⚠️ Error decoding player \(doc.documentID): \(error)")
                    return nil
                }
            }
            if !players.isEmpty {
                DispatchQueue.main.async {
                    onPlayersUpdate(players)
                }
            }
        }
        
        // Real-time listener for Set Games
        gamesListener = db.collection("games").addSnapshotListener { [weak self] snapshot, error in
            guard let self = self, let documents = snapshot?.documents, error == nil else { return }
            let decoder = JSONDecoder()
            let games: [SetGame] = documents.compactMap { doc in
                do {
                    var safeDict = (self.sanitizeForJSON(doc.data()) as? [String: Any]) ?? [:]
                    if safeDict["id"] == nil {
                        safeDict["id"] = doc.documentID
                    }
                    let data = try JSONSerialization.data(withJSONObject: safeDict)
                    return try decoder.decode(SetGame.self, from: data)
                } catch {
                    print("⚠️ Error decoding game \(doc.documentID): \(error)")
                    return nil
                }
            }
            DispatchQueue.main.async {
                onGamesUpdate(games)
            }
        }
        
        // Real-time listener for Availability
        slotsListener = db.collection("availabilitySlots").addSnapshotListener { [weak self] snapshot, error in
            guard let self = self, let documents = snapshot?.documents, error == nil else { return }
            let decoder = JSONDecoder()
            let slots: [AvailabilitySlot] = documents.compactMap { doc in
                do {
                    let safeDict = self.sanitizeForJSON(doc.data())
                    let data = try JSONSerialization.data(withJSONObject: safeDict)
                    return try decoder.decode(AvailabilitySlot.self, from: data)
                } catch {
                    print("⚠️ Error decoding slot \(doc.documentID): \(error)")
                    return nil
                }
            }
            if !slots.isEmpty {
                DispatchQueue.main.async {
                    onSlotsUpdate(slots)
                }
            }
        }
    }
    
    public func stopListening() {
        playersListener?.remove()
        gamesListener?.remove()
        slotsListener?.remove()
    }
    
    // MARK: - Save Operations to Cloud Firestore
    
    public func savePlayer(_ player: Player) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(player),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
        
        db.collection("players").document(player.id.uuidString).setData(dict, merge: true)
    }
    
    public func saveGame(_ game: SetGame) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(game),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
        
        let docId = game.rawId ?? game.id.uuidString
        db.collection("games").document(docId).setData(dict, merge: true)
    }
    
    public func deleteGame(id: UUID, rawId: String? = nil) {
        let docId = rawId ?? id.uuidString
        db.collection("games").document(docId).delete { error in
            if let error = error {
                print("Error deleting game from Firestore: \(error.localizedDescription)")
            }
        }
    }
    
    public func saveAvailabilitySlot(_ slot: AvailabilitySlot) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(slot),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
        
        db.collection("availabilitySlots").document(slot.id.uuidString).setData(dict, merge: true)
    }
    
    public func seedInitialCommunityIfEmpty(initialPlayers: [Player], initialGames: [SetGame], initialSlots: [AvailabilitySlot]) {
        db.collection("players").limit(to: 1).getDocuments { snapshot, error in
            if let count = snapshot?.documents.count, count == 0 {
                for p in initialPlayers {
                    self.savePlayer(p)
                }
                for g in initialGames {
                    self.saveGame(g)
                }
                for s in initialSlots {
                    self.saveAvailabilitySlot(s)
                }
            }
        }
    }
}
