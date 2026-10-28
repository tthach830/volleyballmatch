import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

public struct GameQRCodeSheet: View {
    let game: SetGame
    @Environment(\.dismiss) private var dismiss
    @State private var copiedToClipboard: Bool = false
    
    public static func formatShareTitle(for game: SetGame) -> String {
        formatShareTitle(for: game.scheduledDate)
    }
    
    public static func formatShareTitle(for date: Date) -> String {
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE"
        dayFormatter.locale = Locale(identifier: "en_US")
        let shortDay = dayFormatter.string(from: date)
        
        let cal = Calendar.current
        let hour24 = cal.component(.hour, from: date)
        let minute = cal.component(.minute, from: date)
        let hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12
        let ampm = hour24 < 12 ? "AM" : "PM"
        let timeStr = minute == 0 ? "\(hour12)\(ampm)" : String(format: "%d:%02d%@", hour12, minute, ampm)
        
        return "Join vb \(shortDay) at \(timeStr)"
    }
    
    private var shareTitle: String {
        Self.formatShareTitle(for: game)
    }
    
    private var shareURLString: String {
        "https://runwildlovestronglivefree.org/volleyballmatch/?gameId=\(game.id.uuidString)"
    }
    
    public init(game: SetGame) {
        self.game = game
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Game summary card
                    VStack(spacing: 6) {
                        Text(shareTitle)
                            .font(.system(size: 20, weight: .bold))
                            .multilineTextAlignment(.center)
                        
                        HStack(spacing: 6) {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundColor(.orange)
                            Text(game.courtLocation)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                            Text(game.formattedDate)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 12)
                    
                    // QR Code Card
                    VStack(spacing: 16) {
                        if let qrImage = generateQRCodeImage(from: shareURLString) {
                            Image(uiImage: qrImage)
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 220, height: 220)
                                .padding(16)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
                        } else {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 220, height: 220)
                                .overlay(Text("Unable to generate QR code").font(.caption).foregroundColor(.secondary))
                        }
                        
                        // Instructions
                        VStack(spacing: 6) {
                            Text("Point your camera to join")
                                .font(.system(size: 16, weight: .bold))
                            
                            Text("iPhone users will open the Volleyball Match app. Non-iOS (Android/Web) users will be directed to the web link.")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                    }
                    
                    // Direct Share & Copy Controls
                    VStack(spacing: 10) {
                        // Copy Link Button
                        Button {
                            if let url = URL(string: shareURLString) {
                                UIPasteboard.general.items = [
                                    [
                                        "public.plain-text": "\(shareTitle)\n\(shareURLString)",
                                        "public.url": url
                                    ]
                                ]
                            } else {
                                UIPasteboard.general.string = "\(shareTitle)\n\(shareURLString)"
                            }
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                            withAnimation {
                                copiedToClipboard = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                withAnimation {
                                    copiedToClipboard = false
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: copiedToClipboard ? "checkmark" : "doc.on.doc")
                                Text(copiedToClipboard ? "Link Copied!" : "Copy Share Link")
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(copiedToClipboard ? Color.green.opacity(0.15) : Color(UIColor.secondarySystemFill))
                            .foregroundColor(copiedToClipboard ? .green : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Native iOS Share Sheet
                        if let url = URL(string: shareURLString) {
                            ShareLink(
                                item: url,
                                subject: Text(shareTitle),
                                message: Text("\(shareTitle)\n\(shareURLString)")
                            ) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Share Game Link...")
                                }
                                .font(.system(size: 15, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Direct URL preview
                    Text(shareURLString)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .padding(.horizontal, 30)
                        .padding(.bottom, 20)
                }
            }
            .navigationTitle("Game QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func generateQRCodeImage(from string: String) -> UIImage? {
        let data = Data(string.utf8)
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        
        guard let outputImage = filter.outputImage else { return nil }
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: transform)
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Tournament QR Code Sheet
public struct TournamentQRCodeSheet: View {
    let tournament: Tournament
    @Environment(\.dismiss) private var dismiss
    @State private var copiedToClipboard: Bool = false
    
    public static func formatShareTitle(for tournament: Tournament) -> String {
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE"
        dayFormatter.locale = Locale(identifier: "en_US")
        let shortDay = dayFormatter.string(from: tournament.date)
        
        let cal = Calendar.current
        let hour24 = cal.component(.hour, from: tournament.date)
        let minute = cal.component(.minute, from: tournament.date)
        let hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12
        let ampm = hour24 < 12 ? "AM" : "PM"
        let timeStr = minute == 0 ? "\(hour12)\(ampm)" : String(format: "%d:%02d%@", hour12, minute, ampm)
        
        return "Join \(tournament.title) \(shortDay) at \(timeStr)"
    }
    
    private var shareTitle: String {
        Self.formatShareTitle(for: tournament)
    }
    
    private var shareURLString: String {
        "https://runwildlovestronglivefree.org/volleyballmatch/?tournamentId=\(tournament.id.uuidString)"
    }
    
    public init(tournament: Tournament) {
        self.tournament = tournament
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Tournament summary card
                    VStack(spacing: 6) {
                        Text(shareTitle)
                            .font(.system(size: 20, weight: .bold))
                            .multilineTextAlignment(.center)
                        
                        HStack(spacing: 6) {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundColor(.cyan)
                            Text("\(tournament.location) • \(tournament.courts.joined(separator: ", "))")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .foregroundColor(.orange)
                            Text(tournament.formattedDate)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 12)
                    
                    // QR Code Card
                    VStack(spacing: 16) {
                        if let qrImage = generateQRCodeImage(from: shareURLString) {
                            Image(uiImage: qrImage)
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 220, height: 220)
                                .padding(16)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
                        } else {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 220, height: 220)
                                .overlay(Text("Unable to generate QR code").font(.caption).foregroundColor(.secondary))
                        }
                        
                        // Instructions
                        VStack(spacing: 6) {
                            Text("Point your camera to join")
                                .font(.system(size: 16, weight: .bold))
                            
                            Text("iPhone users will open the Volleyball Match app. Non-iOS (Android/Web) users will be directed to the web link.")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                    }
                    
                    // Direct Share & Copy Controls
                    VStack(spacing: 10) {
                        // Copy Link Button
                        Button {
                            if let url = URL(string: shareURLString) {
                                UIPasteboard.general.items = [
                                    [
                                        "public.plain-text": "\(shareTitle)\n\(shareURLString)",
                                        "public.url": url
                                    ]
                                ]
                            } else {
                                UIPasteboard.general.string = "\(shareTitle)\n\(shareURLString)"
                            }
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                            withAnimation {
                                copiedToClipboard = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                withAnimation {
                                    copiedToClipboard = false
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: copiedToClipboard ? "checkmark" : "doc.on.doc")
                                Text(copiedToClipboard ? "Link Copied!" : "Copy Share Link")
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(copiedToClipboard ? Color.green.opacity(0.15) : Color(UIColor.secondarySystemFill))
                            .foregroundColor(copiedToClipboard ? .green : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Native iOS Share Sheet
                        if let url = URL(string: shareURLString) {
                            ShareLink(
                                item: url,
                                subject: Text(shareTitle),
                                message: Text("\(shareTitle)\n\(shareURLString)")
                            ) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Share Tournament Link...")
                                }
                                .font(.system(size: 15, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Direct URL preview
                    Text(shareURLString)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .padding(.horizontal, 30)
                        .padding(.bottom, 20)
                }
            }
            .navigationTitle("Tournament QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func generateQRCodeImage(from string: String) -> UIImage? {
        let data = Data(string.utf8)
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        
        guard let outputImage = filter.outputImage else { return nil }
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: transform)
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Team QR Code & Invite Sheet
public struct TeamQRCodeSheet: View {
    let tournament: Tournament
    let team: TournamentTeam
    @Environment(\.dismiss) private var dismiss
    @State private var copiedToClipboard: Bool = false
    
    private var shareTitle: String {
        "Join \(team.teamName) (\(team.division.displayName))"
    }
    
    private var shareURLString: String {
        "https://runwildlovestronglivefree.org/volleyballmatch/?tournamentId=\(tournament.id.uuidString)&teamId=\(team.id.uuidString)"
    }
    
    public init(tournament: Tournament, team: TournamentTeam) {
        self.tournament = tournament
        self.team = team
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Team summary card
                    VStack(spacing: 6) {
                        Text(team.teamName)
                            .font(.system(size: 22, weight: .bold))
                            .multilineTextAlignment(.center)
                        
                        Text(tournament.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.orange)
                        
                        HStack(spacing: 6) {
                            Text(team.division.displayName)
                                .font(.system(size: 13, weight: .medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.orange.opacity(0.15)))
                                .foregroundColor(.orange)
                            if let pool = team.poolName {
                                Text(pool)
                                    .font(.system(size: 13, weight: .medium))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(Color.cyan.opacity(0.15)))
                                    .foregroundColor(.cyan)
                            }
                        }
                    }
                    .padding(.top, 12)
                    
                    // QR Code Card
                    VStack(spacing: 16) {
                        if let qrImage = generateQRCodeImage(from: shareURLString) {
                            Image(uiImage: qrImage)
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 220, height: 220)
                                .padding(16)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
                        } else {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 220, height: 220)
                                .overlay(Text("Unable to generate QR code").font(.caption).foregroundColor(.secondary))
                        }
                        
                        // Instructions
                        VStack(spacing: 6) {
                            Text("Team Invite Link")
                                .font(.system(size: 16, weight: .bold))
                            
                            Text("One link for your entire team. Share this single link or QR code with your partner and teammates. When they open it, they can join or sign up to automatically fill the open spots on your team!")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    // Actions
                    VStack(spacing: 12) {
                        // Native iOS ShareLink
                        if let shareURL = URL(string: shareURLString) {
                            ShareLink(
                                item: shareURL,
                                subject: Text("Join \(team.teamName)"),
                                message: Text("Join my team '\(team.teamName)' for \(tournament.title)! Click the link or scan the QR code to join:")
                            ) {
                                Label("Share Team Invite Link", systemImage: "square.and.arrow.up")
                                    .font(.system(size: 16, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.orange)
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        
                        // Copy Link button
                        Button(action: {
                            UIPasteboard.general.string = shareURLString
                            copiedToClipboard = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                copiedToClipboard = false
                            }
                        }) {
                            Label(
                                copiedToClipboard ? "Invite Link Copied!" : "Copy Invite Link",
                                systemImage: copiedToClipboard ? "checkmark" : "doc.on.doc"
                            )
                            .font(.system(size: 15, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(UIColor.secondarySystemBackground))
                            .foregroundColor(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Direct URL preview
                    Text(shareURLString)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .padding(.horizontal, 30)
                        .padding(.bottom, 20)
                }
            }
            .navigationTitle("Team Invite")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func generateQRCodeImage(from string: String) -> UIImage? {
        let data = Data(string.utf8)
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        
        guard let outputImage = filter.outputImage else { return nil }
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: transform)
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Game Player Picker Sheet (Host / Admin manual player addition)
public struct GamePlayerPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var dataManager: DataManager
    let game: SetGame
    let onPlayerSelected: (Player) -> Void
    
    @State private var searchQuery: String = ""
    
    private var eligiblePlayers: [Player] {
        let currentInGame = Set(game.allPlayerIds)
        return dataManager.players.filter { p in
            guard !currentInGame.contains(p.id) else { return false }
            if !searchQuery.isEmpty {
                let matches = p.name.localizedCaseInsensitiveContains(searchQuery) ||
                              p.nickname.localizedCaseInsensitiveContains(searchQuery)
                if !matches { return false }
            }
            return true
        }
    }
    
    public init(dataManager: DataManager, game: SetGame, onPlayerSelected: @escaping (Player) -> Void) {
        self.dataManager = dataManager
        self.game = game
        self.onPlayerSelected = onPlayerSelected
    }
    
    private func formattedPlayerName(_ player: Player) -> String {
        let rawName = player.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = rawName.split(separator: " ").map(String.init)
        let firstName = parts.first ?? (rawName.isEmpty ? "Player" : rawName)
        let rawNick = player.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanNick = rawNick.replacingOccurrences(of: "^\\((.*)\\)$", with: "$1", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanNick.isEmpty && cleanNick.caseInsensitiveCompare("Player") != .orderedSame && cleanNick.caseInsensitiveCompare(firstName) != .orderedSame {
            return "\(firstName)(\(cleanNick))"
        } else {
            return rawName.isEmpty ? "Player" : rawName
        }
    }
    
    public var body: some View {
        NavigationStack {
            List {
                if !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !eligiblePlayers.contains(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) {
                        Section("Add Guest Player") {
                            Button {
                                let guest = dataManager.getOrCreateGuestPlayer(name: trimmed, rating: .intermediate)
                                onPlayerSelected(guest)
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "person.badge.plus")
                                        .font(.title3)
                                        .foregroundColor(.orange)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Add \"\(trimmed)\"")
                                            .font(.headline)
                                            .foregroundColor(.orange)
                                        Text("Add as unregistered / guest player")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.orange)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }
                
                Section("Players (\(eligiblePlayers.count))") {
                    ForEach(eligiblePlayers) { player in
                        Button {
                            onPlayerSelected(player)
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                PlayerAvatarView(player: player, dimension: 42)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(formattedPlayerName(player))
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    HStack(spacing: 6) {
                                        Text(player.rating.rawValue)
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(player.rating.badgeColor)
                                        Text("•")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        Text(player.homeBeach.isEmpty ? "Main Beach" : player.homeBeach)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                        Text("•")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        Text("Elo: \(player.eloRating)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                                RatingBadge(rating: player.rating)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .searchable(text: $searchQuery, prompt: "Search player by name or nickname...")
            .navigationTitle("Add Player to Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
