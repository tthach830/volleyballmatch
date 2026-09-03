import SwiftUI

public struct AuthView: View {
    @ObservedObject var dataManager: DataManager
    
    @State private var authMode: Int = 0 // 0 = Log In, 1 = New Player
    
    // Log In State
    @State private var loginPhone: String = ""
    @State private var loginPassword: String = ""
    @State private var isLoginPasswordVisible: Bool = false
    @State private var loginErrorMessage: String? = nil
    
    // New Player State
    @State private var signUpPhone: String = ""
    @State private var signUpPassword: String = ""
    @State private var isSignUpPasswordVisible: Bool = false
    @State private var name: String = ""
    @State private var nickname: String = ""
    @State private var selectedRating: RatingTier = .intermediate
    @State private var selectedBeach: String = "Main Beach"
    @State private var customBeachName: String = ""
    @State private var selectedEmoji: String = "slug"
    @State private var signUpErrorMessage: String? = nil
    @State private var showRatingGuide: Bool = false
    
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
                VStack(spacing: 20) {
                    // Brand Header
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
                                .frame(width: 76, height: 76)
                                .shadow(color: Color.orange.opacity(0.3), radius: 8, y: 4)
                            
                            CourtAvatarIconView(avatarKey: authMode == 0 ? "slug" : selectedEmoji, size: 48)
                        }
                        .padding(.top, 8)
                        
                        Text("Volleyball Match")
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Beach Doubles • Ladders • Pickup Community")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    // Mode Selector (Log In / New Player)
                    Picker("Mode", selection: $authMode) {
                        Text("Log In").tag(0)
                        Text("New Player").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    if authMode == 0 {
                        // LOG IN VIEW
                        loginSection
                    } else {
                        // NEW PLAYER SIGN UP VIEW
                        signUpSection
                    }
                }
                .padding(.bottom, 40)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .sheet(isPresented: $showRatingGuide) {
                RatingGuideSheet(selectedTier: $selectedRating)
            }
        }
    }
    
    // MARK: - Log In Section
    private var loginSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("PHONE NUMBER")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                
                TextField("(831) 555-0142", text: $loginPhone)
                    .keyboardType(.phonePad)
                    .padding(14)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange.opacity(0.4), lineWidth: 1)
                    )
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("PASSWORD")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                
                HStack {
                    if isLoginPasswordVisible {
                        TextField("Enter your password", text: $loginPassword)
                    } else {
                        SecureField("Enter your password", text: $loginPassword)
                    }
                    Button {
                        isLoginPasswordVisible.toggle()
                    } label: {
                        Image(systemName: isLoginPasswordVisible ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.secondary)
                    }
                }
                .padding(14)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.4), lineWidth: 1)
                )
            }
            
            if let error = loginErrorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            Button {
                let res = dataManager.loginWithPhone(phoneNumber: loginPhone, password: loginPassword)
                if !res.success {
                    loginErrorMessage = res.message
                } else {
                    loginErrorMessage = nil
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                    Text("Log In")
                        .font(.system(size: 16, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.orange)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: Color.orange.opacity(0.3), radius: 6, y: 3)
            }
            
            // Switch to New Player prompt
            Button {
                signUpPhone = loginPhone
                signUpPassword = loginPassword
                withAnimation {
                    authMode = 1
                }
            } label: {
                HStack {
                    Text("First time playing?")
                        .foregroundColor(.secondary)
                    Text("Sign up as New Player")
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                .font(.system(size: 13))
                .frame(maxWidth: .infinity)
            }
            .padding(.top, 4)
            
            // Demo Accounts Quick Tap
            VStack(alignment: .leading, spacing: 8) {
                Text("QUICK DEMO PLAYERS (PW: volleyball123)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        demoPill(name: "Taylor (Slugger)", phone: "8315550102", emoji: "slug")
                        demoPill(name: "Kai (The Jet)", phone: "8315550101", emoji: "🦈")
                        demoPill(name: "Maya (SpikeQueen)", phone: "8315550103", emoji: "🐋")
                        demoPill(name: "Chloe (Sunny)", phone: "8315550105", emoji: "slug")
                    }
                }
            }
            .padding(.top, 10)
        }
        .padding(20)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
    
    private func demoPill(name: String, phone: String, emoji: String) -> some View {
        Button {
            loginPhone = phone
            loginPassword = "volleyball123"
            let res = dataManager.loginWithPhone(phoneNumber: phone, password: "volleyball123")
            if !res.success {
                loginErrorMessage = res.message
            }
        } label: {
            HStack(spacing: 6) {
                CourtAvatarIconView(avatarKey: emoji, size: 20)
                Text(name)
                    .font(.system(size: 12, weight: .bold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.orange.opacity(0.12))
            .foregroundColor(.orange)
            .clipShape(Capsule())
        }
    }
    
    // MARK: - Sign Up Section
    private var signUpSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Mobile Phone (Required)
            VStack(alignment: .leading, spacing: 6) {
                Text("MOBILE PHONE NUMBER (REQUIRED)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                
                TextField("(831) 555-0142", text: $signUpPhone)
                    .keyboardType(.phonePad)
                    .padding(12)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            // Password (Required)
            VStack(alignment: .leading, spacing: 6) {
                Text("PASSWORD (REQUIRED)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                
                HStack {
                    if isSignUpPasswordVisible {
                        TextField("Create a password", text: $signUpPassword)
                    } else {
                        SecureField("Create a password", text: $signUpPassword)
                    }
                    Button {
                        isSignUpPasswordVisible.toggle()
                    } label: {
                        Image(systemName: isSignUpPasswordVisible ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.secondary)
                    }
                }
                .padding(12)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
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
            
            // Avatar Selector
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
                                            .frame(width: 58, height: 58)
                                        
                                        CourtAvatarIconView(avatarKey: item.emoji, size: 38)
                                    }
                                    .overlay(
                                        Circle()
                                            .stroke(selectedEmoji == item.emoji ? Color.orange : Color.clear, lineWidth: 2)
                                    )
                                    
                                    Text(item.name)
                                        .font(.system(size: 10, weight: selectedEmoji == item.emoji ? .bold : .regular))
                                        .foregroundColor(selectedEmoji == item.emoji ? .orange : .secondary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            
            // Rating Tier
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("SKILL LEVEL")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Skill Guide") {
                        showRatingGuide = true
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.orange)
                }
                
                Picker("Skill Level", selection: $selectedRating) {
                    ForEach(RatingTier.allCases, id: \.self) { tier in
                        Text(tier.rawValue).tag(tier)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            // Home Beach
            VStack(alignment: .leading, spacing: 6) {
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
                .padding(12)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                
                if selectedBeach == CourtLocations.customOption {
                    TextField("Enter custom court location", text: $customBeachName)
                        .padding(12)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            
            if let error = signUpErrorMessage {
                Text(error)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.red)
            }
            
            // Submit Button
            Button {
                let cleaned = DataManager.normalizePhoneNumber(signUpPhone)
                if cleaned.isEmpty {
                    signUpErrorMessage = "Please enter a valid phone number."
                    return
                }
                if signUpPassword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    signUpErrorMessage = "Please create a password for your profile."
                    return
                }
                let finalName = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Beach Player" : name.trimmingCharacters(in: .whitespacesAndNewlines)
                let finalNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? finalName : nickname.trimmingCharacters(in: .whitespacesAndNewlines)
                
                dataManager.signUp(
                    phoneNumber: signUpPhone,
                    password: signUpPassword,
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
                    Text("Create Player & Play")
                        .font(.system(size: 16, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.orange)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: Color.orange.opacity(0.3), radius: 6, y: 3)
            }
            
            // Switch to Log In prompt
            Button {
                loginPhone = signUpPhone
                withAnimation {
                    authMode = 0
                }
            } label: {
                HStack {
                    Text("Already have a player profile?")
                        .foregroundColor(.secondary)
                    Text("Log In with Phone")
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                .font(.system(size: 13))
                .frame(maxWidth: .infinity)
            }
            .padding(.top, 4)
        }
        .padding(20)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}
