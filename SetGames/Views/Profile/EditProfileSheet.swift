import SwiftUI

public struct EditProfileSheet: View {
    @ObservedObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var nickname: String = ""
    @State private var avatarEmoji: String = "slug"
    @State private var rating: RatingTier = .b
    @State private var homeBeach: String = "Main Beach"
    @State private var phoneNumber: String = ""
    @State private var bio: String = ""
    @State private var isStatsHidden: Bool = false
    
    private let availableAvatars: [String] = [
        "slug", "🐎", "🦈", "🏐", "⚡️", "👑", "🌊", "🐋", "🔥", "🦦", "🦅", "🦁"
    ]
    
    private let availableBeaches: [String] = [
        "Main Beach", "Harbor Beach", "4th Street", "Seabright Beach"
    ]
    
    public init(dataManager: DataManager) {
        self.dataManager = dataManager
    }
    
    private func isAvatarSelected(_ avatar: String) -> Bool {
        if avatarEmoji == avatar { return true }
        if (avatar == "slug" || avatar == "🍌") && (avatarEmoji == "slug" || avatarEmoji == "🍌" || avatarEmoji.lowercased().contains("slug")) {
            return true
        }
        if (avatar == "🐎" || avatar == "mustang") && (avatarEmoji == "🐎" || avatarEmoji == "mustang") {
            return true
        }
        return false
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                // Section 1: Avatar Selection
                Section {
                    VStack(alignment: .center, spacing: 14) {
                        // Current Avatar Preview
                        HStack {
                            Spacer()
                            ZStack {
                                Circle()
                                    .fill(Color.orange.opacity(0.12))
                                    .frame(width: 84, height: 84)
                                
                                CourtAvatarIconView(avatarKey: avatarEmoji, size: 68)
                            }
                            .overlay(
                                Circle()
                                    .stroke(Color.orange, lineWidth: 2.5)
                            )
                            Spacer()
                        }
                        .padding(.top, 4)
                        
                        Text("Select Beach Mascot Avatar")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        // Horizontal Avatar Picker
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(availableAvatars, id: \.self) { avatar in
                                    let isSelected = isAvatarSelected(avatar)
                                    Button {
                                        avatarEmoji = avatar
                                    } label: {
                                        ZStack {
                                            Circle()
                                                .fill(isSelected ? Color.orange.opacity(0.2) : Color(UIColor.systemGray6))
                                                .frame(width: 48, height: 48)
                                                .overlay(
                                                    Circle()
                                                        .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 2)
                                                )
                                            
                                            CourtAvatarIconView(avatarKey: avatar, size: 36)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("PLAYER MASCOT")
                }
                
                // Section 2: Player Identity
                Section {
                    HStack {
                        Text("Full Name")
                            .frame(width: 90, alignment: .leading)
                            .foregroundColor(.secondary)
                        TextField("Kai Rodriguez", text: $name)
                    }
                    
                    HStack {
                        Text("Nickname")
                            .frame(width: 90, alignment: .leading)
                            .foregroundColor(.secondary)
                        TextField("The Jet", text: $nickname)
                    }
                    
                    HStack {
                        Text("Phone")
                            .frame(width: 90, alignment: .leading)
                            .foregroundColor(.secondary)
                        TextField("831-555-0101", text: $phoneNumber)
                            .keyboardType(.phonePad)
                    }
                } header: {
                    Text("PERSONAL DETAILS")
                }
                
                // Section 3: Skill & Court Preferences
                Section {
                    Picker("Rating Tier", selection: $rating) {
                        ForEach(RatingTier.allCases) { tier in
                            HStack {
                                Text(tier.rawValue)
                                Spacer()
                                Text(tier.shortCode)
                                    .foregroundColor(.secondary)
                            }
                            .tag(tier)
                        }
                    }
                    
                    Picker("Home Beach", selection: $homeBeach) {
                        ForEach(availableBeaches, id: \.self) { beach in
                            Text(beach).tag(beach)
                        }
                    }
                } header: {
                    Text("SKILL & LOCATION")
                }
                
                // Section 4: Bio / Playstyle
                Section {
                    TextField("Tell other players about your style (e.g. setter, blocker, cut-shots)...", text: $bio, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("BIO & PLAY STYLE")
                }
                
                // Section 5: Privacy & Leaderboard Visibility
                Section {
                    Toggle(isOn: $isStatsHidden) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Hide Stats from Ladders & Public")
                                .font(.system(size: 15, weight: .medium))
                            Text("Excludes your profile and win records from the competitive ladder and public view.")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("PRIVACY SETTINGS")
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProfile()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                loadCurrentUserData()
            }
        }
    }
    
    private func loadCurrentUserData() {
        guard let user = dataManager.currentUser else { return }
        name = user.name
        nickname = user.nickname
        avatarEmoji = user.avatarEmoji
        rating = user.rating
        homeBeach = user.homeBeach
        phoneNumber = user.phoneNumber
        bio = user.bio
        isStatsHidden = user.isStatsHidden
    }
    
    private func saveProfile() {
        dataManager.updateCurrentUserProfile(
            name: name,
            nickname: nickname,
            avatarEmoji: avatarEmoji,
            rating: rating,
            homeBeach: homeBeach,
            phoneNumber: phoneNumber,
            bio: bio,
            isStatsHidden: isStatsHidden
        )
        dismiss()
    }
}
