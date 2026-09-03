import SwiftUI

public struct SignUpView: View {
    @ObservedObject var dataManager: DataManager
    
    @State private var name: String = ""
    @State private var nickname: String = ""
    @State private var selectedRating: RatingTier = .intermediate
    @State private var selectedBeach: String = "Main Beach"
    @State private var customBeachName: String = ""
    @State private var selectedEmoji: String = "slug" // Banana Slug!
    @State private var showRatingGuide: Bool = false
    @State private var showUserSwitcher: Bool = false
    
    private let avatars = CourtAvatar.availableAvatars
    
    private var effectiveBeach: String {
        if selectedBeach == CourtLocations.customOption {
            let trimmed = customBeachName.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? "Custom Court" : trimmed
        }
        return selectedBeach
    }
    
    public init(dataManager: DataManager) {
        self.dataManager = dataManager
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Brand
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.orange, Color.yellow],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                                .shadow(color: Color.orange.opacity(0.3), radius: 10, y: 5)
                            
                            CourtAvatarIconView(avatarKey: selectedEmoji, size: 52)
                        }
                        .padding(.top, 10)
                        
                        Text("Volleyball Match")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Automated Set Games • Ladders • Community")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    // Form Card
                    VStack(alignment: .leading, spacing: 18) {
                        // Full Name & Nickname
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("FULL NAME")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.secondary)
                                
                                TextField("Alex Morgan", text: $name)
                                    .padding(12)
                                    .background(Color(UIColor.secondarySystemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("NICKNAME")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.secondary)
                                
                                TextField("Slugger", text: $nickname)
                                    .padding(12)
                                    .background(Color(UIColor.secondarySystemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                        
                        // Avatar Picker (Banana Slug, Shark, Otter, Orca, etc.)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("SELECT COURT AVATAR")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(avatars) { item in
                                        Button {
                                            selectedEmoji = item.emoji
                                        } label: {
                                            VStack(spacing: 4) {
                                                ZStack {
                                                    Circle()
                                                        .fill(selectedEmoji == item.emoji ? Color.orange.opacity(0.2) : Color(UIColor.secondarySystemGroupedBackground))
                                                        .frame(width: 52, height: 52)
                                                        .overlay(
                                                            Circle()
                                                                .stroke(selectedEmoji == item.emoji ? Color.orange : Color.clear, lineWidth: 2.5)
                                                        )
                                                    
                                                    CourtAvatarIconView(avatarKey: item.emoji, size: 38)
                                                }
                                                
                                                Text(item.name)
                                                    .font(.system(size: 10, weight: selectedEmoji == item.emoji ? .bold : .medium))
                                                    .foregroundColor(selectedEmoji == item.emoji ? .orange : .secondary)
                                                    .lineLimit(1)
                                            }
                                            .frame(width: 64)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        
                        // Rating Tier Selection (Crucial User Requirement)
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("YOUR SKILL LEVEL")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Button {
                                    showRatingGuide = true
                                } label: {
                                    HStack(spacing: 3) {
                                        Image(systemName: "questionmark.circle.fill")
                                        Text("Rating Guide")
                                    }
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.orange)
                                }
                            }
                            
                            // Horizontal grid of rating buttons
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(RatingTier.allCases) { tier in
                                    Button {
                                        selectedRating = tier
                                    } label: {
                                        VStack(spacing: 4) {
                                            Image(systemName: tier.iconName)
                                                .font(.system(size: 16))
                                                .foregroundColor(selectedRating == tier ? .white : tier.badgeColor)
                                            
                                            Text(tier.rawValue)
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundColor(selectedRating == tier ? .white : .primary)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(selectedRating == tier ? tier.badgeColor : Color(UIColor.secondarySystemGroupedBackground))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(tier.badgeColor.opacity(0.3), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            
                            // Selected tier brief summary
                            Text(selectedRating.description)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                        
                        // Home Beach Courts (Main Beach, Harbor, 4th Street, etc.)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("HOME BEACH COURT")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                            
                            Picker("Home Beach", selection: $selectedBeach) {
                                ForEach(CourtLocations.allOptions, id: \.self) { court in
                                    Text(court).tag(court)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            
                            // Custom Court Name input
                            if selectedBeach == CourtLocations.customOption {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("CUSTOM COURT NAME")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.orange)
                                    
                                    HStack {
                                        Image(systemName: "mappin.circle.fill")
                                            .foregroundColor(.orange)
                                        TextField("e.g. Seabright Beach, 26th Ave", text: $customBeachName)
                                    }
                                    .padding(12)
                                    .background(Color(UIColor.secondarySystemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.orange.opacity(0.4), lineWidth: 1)
                                    )
                                }
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                    }
                    .padding(18)
                    .background(Color(UIColor.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.black.opacity(0.04), radius: 8, y: 3)
                    .padding(.horizontal)
                    
                    // Submit Sign Up Button
                    VStack(spacing: 12) {
                        Button {
                            let finalName = name.isEmpty ? "Jordan Beach" : name
                            let finalNickname = nickname.isEmpty ? "Slugger" : nickname
                            
                            dataManager.signUp(
                                name: finalName,
                                nickname: finalNickname,
                                rating: selectedRating,
                                homeBeach: effectiveBeach,
                                avatarEmoji: selectedEmoji
                            )
                        } label: {
                            HStack {
                                Image(systemName: "figure.volleyball")
                                    .font(.system(size: 16, weight: .bold))
                                Text("Join & Find Set Games")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [Color.orange, Color(red: 0.95, green: 0.4, blue: 0.1)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: Color.orange.opacity(0.3), radius: 6, y: 3)
                        }
                        
                        // Switcher button for testing/demoing
                        Button {
                            showUserSwitcher = true
                        } label: {
                            Text("Switch to Demo Player Profile")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .sheet(isPresented: $showRatingGuide) {
                RatingGuideSheet(selectedTier: $selectedRating)
            }
            .sheet(isPresented: $showUserSwitcher) {
                UserSwitcherView(dataManager: dataManager)
            }
        }
    }
}
