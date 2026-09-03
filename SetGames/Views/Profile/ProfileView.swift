import SwiftUI

public struct ProfileView: View {
    @ObservedObject var dataManager: DataManager
    @State private var showUserSwitcher: Bool = false
    @State private var showRatingGuide: Bool = false
    @State private var showEditProfileSheet: Bool = false
    
    public init(dataManager: DataManager) {
        self.dataManager = dataManager
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                if let user = dataManager.currentUser {
                    VStack(spacing: 20) {
                        // User Profile Header
                        VStack(spacing: 12) {
                            PlayerAvatarView(player: user, dimension: 76)
                            
                            VStack(spacing: 4) {
                                Text(user.name)
                                    .font(.system(size: 22, weight: .bold))
                                
                                Text("@\(user.nickname)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.orange)
                                
                                if !user.phoneNumber.isEmpty {
                                    Text("📱 \(user.phoneNumber)")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                
                                if user.isRoot {
                                    HStack(spacing: 3) {
                                        Text("👑 Root Admin")
                                    }
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.purple)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.purple.opacity(0.15))
                                    .clipShape(Capsule())
                                }
                            }
                            
                            HStack(spacing: 10) {
                                RatingBadge(rating: user.rating, size: .regular)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                        .font(.system(size: 11))
                                    Text("\(user.formattedStarRating) (\(user.starRatingCount))")
                                        .font(.system(size: 12, weight: .bold))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.yellow.opacity(0.15))
                                .clipShape(Capsule())
                                
                                Text("•")
                                    .foregroundColor(.secondary)
                                
                                Label(user.homeBeach, systemImage: "mappin")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            
                            if user.isFlaker {
                                HStack(spacing: 6) {
                                    Text("F")
                                        .font(.system(size: 11, weight: .black))
                                        .foregroundColor(.white)
                                        .frame(width: 18, height: 18)
                                        .background(Color.red)
                                        .clipShape(Circle())
                                    Text("Flaker: -1.0 Rating Penalty (Backed out 3x)")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.red)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.red.opacity(0.12))
                                .clipShape(Capsule())
                            }
                            
                            Text("\"\(user.bio)\"")
                                .font(.system(size: 13, weight: .regular))
                                .italic()
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Button {
                                showEditProfileSheet = true
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "pencil.line")
                                    Text("Edit Profile")
                                }
                                .font(.system(size: 13, weight: .bold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 7)
                                .background(Color.orange.opacity(0.12))
                                .foregroundColor(.orange)
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 2)
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .padding(.horizontal)
                        
                        // "The Popular Kids" Highlight Banner
                        NavigationLink {
                            PartnerHistoryView(dataManager: dataManager, player: user)
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(Color.purple.opacity(0.15))
                                        .frame(width: 48, height: 48)
                                    Image(systemName: "person.3.sequence.fill")
                                        .foregroundColor(.purple)
                                        .font(.system(size: 20))
                                }
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack {
                                        Text(user.popularKidsTitle)
                                            .font(.system(size: 14, weight: .black))
                                            .foregroundColor(.purple)
                                        Spacer()
                                        Text("\(user.uniqueConnectionsCount) Players")
                                            .font(.system(size: 16, weight: .black, design: .rounded))
                                            .foregroundColor(.primary)
                                    }
                                    
                                    Text("Tap to explore your beach volleyball network")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.secondary)
                            }
                            .padding(14)
                            .background(Color.purple.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.purple.opacity(0.25), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                        
                        // Performance & Record Grid
                        VStack(alignment: .leading, spacing: 12) {
                            Text("RECORD & PERFORMANCE")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                StatCard(
                                    title: "Win / Loss",
                                    value: user.formattedRecord,
                                    subtitle: "Total: \(user.totalMatches) games",
                                    icon: "trophy.fill",
                                    tintColor: .orange
                                )
                                
                                StatCard(
                                    title: "Win Rate",
                                    value: user.winRateFormatted,
                                    subtitle: user.streakFormatted,
                                    icon: "chart.line.uptrend.xyaxis",
                                    tintColor: .green
                                )
                                
                                StatCard(
                                    title: "Elo Rating",
                                    value: "\(user.eloRating)",
                                    subtitle: "Tier: \(user.rating.rawValue)",
                                    icon: "star.circle.fill",
                                    tintColor: user.rating.badgeColor
                                )
                                
                                StatCard(
                                    title: "Point Diff",
                                    value: user.pointDifferential >= 0 ? "+\(user.pointDifferential)" : "\(user.pointDifferential)",
                                    subtitle: "\(user.pointsScored) scored • \(user.pointsAllowed) allowed",
                                    icon: "plusminus.circle.fill",
                                    tintColor: .blue
                                )
                            }
                            .padding(.horizontal)
                        }
                        
                        // Account & Demo Actions
                        VStack(spacing: 12) {
                            Button {
                                showUserSwitcher = true
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                    Text("Switch Active Profile (Demo Mode)")
                                }
                                .font(.system(size: 14, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .foregroundColor(.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            
                            Button {
                                dataManager.logOut()
                            } label: {
                                Text("Log Out / Sign Up New Player")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                    }
                    .padding(.bottom, 30)
                } else {
                    VStack(spacing: 12) {
                        Text("No active user session")
                        Button("Sign Up") {
                            // Handled by RootView
                        }
                    }
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Player Profile")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showEditProfileSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "pencil")
                            Text("Edit")
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.orange)
                    }
                }
            }
            .sheet(isPresented: $showEditProfileSheet) {
                EditProfileSheet(dataManager: dataManager)
            }
            .sheet(isPresented: $showUserSwitcher) {
                UserSwitcherView(dataManager: dataManager)
            }
        }
    }
}
