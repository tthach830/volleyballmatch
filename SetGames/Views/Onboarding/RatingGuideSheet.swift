import SwiftUI

public struct RatingGuideSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTier: RatingTier
    
    public init(selectedTier: Binding<RatingTier>) {
        self._selectedTier = selectedTier
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Beach Volleyball Rating Guide")
                            .font(.system(size: 22, weight: .bold))
                        Text("Accurate ratings ensure balanced sets, competitive rallies, and great games for everyone on the sand.")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    VStack(spacing: 12) {
                        ForEach(RatingTier.allCases) { tier in
                            Button {
                                selectedTier = tier
                                dismiss()
                            } label: {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        RatingBadge(rating: tier, size: .regular)
                                        
                                        Spacer()
                                        
                                        if selectedTier == tier {
                                            HStack(spacing: 4) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.green)
                                                Text("Selected")
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundColor(.green)
                                            }
                                        }
                                    }
                                    
                                    Text(tier.description)
                                        .font(.system(size: 13))
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(selectedTier == tier ? tier.badgeColor.opacity(0.1) : Color(UIColor.secondarySystemGroupedBackground))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(selectedTier == tier ? tier.badgeColor : Color.clear, lineWidth: 2)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Find Your Rating")
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
}
