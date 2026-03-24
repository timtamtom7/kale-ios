import SwiftUI

struct PricingView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedTier: SubscriptionTier = .free
    @State private var isAnnual = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundLight.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        headerSection
                        billingToggle
                        tiersList
                        footerNote
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Choose a Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.textSecondary)
                            .frame(width: 28, height: 28)
                            .background(Color.surfaceLight)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentGreen.opacity(0.1))
                    .frame(width: 72, height: 72)

                Image(systemName: "leaf.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.accentGreen, Color(hex: "22c55e")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Text("Kale")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.textPrimary)

            Text("Start free. Upgrade when you're ready.")
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    // MARK: - Billing Toggle

    private var billingToggle: some View {
        HStack(spacing: 0) {
            billingOption("Monthly", isSelected: !isAnnual) {
                withAnimation(.easeInOut(duration: 0.2)) { isAnnual = false }
            }

            billingOption("Annual", isSelected: isAnnual) {
                withAnimation(.easeInOut(duration: 0.2)) { isAnnual = true }
            }
        }
        .padding(4)
        .background(Color.surfaceLight)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func billingOption(_ label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    Group {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 9)
                                .fill(Color.accentGreen)
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 9))
        }
    }

    // MARK: - Tiers

    private var tiersList: some View {
        VStack(spacing: 16) {
            PricingTierCard(
                tier: .free,
                monthlyPrice: 0,
                isAnnual: isAnnual,
                isSelected: selectedTier == .free,
                onSelect: { selectedTier = .free }
            )

            PricingTierCard(
                tier: .daily,
                monthlyPrice: isAnnual ? 1.99 : 2.99,
                isAnnual: isAnnual,
                isSelected: selectedTier == .daily,
                onSelect: { selectedTier = .daily }
            )

            PricingTierCard(
                tier: .complete,
                monthlyPrice: isAnnual ? 4.99 : 5.99,
                isAnnual: isAnnual,
                isSelected: selectedTier == .complete,
                onSelect: { selectedTier = .complete }
            )
        }
    }

    // MARK: - Footer

    private var footerNote: some View {
        VStack(spacing: 8) {
            if selectedTier != .free {
                Button {
                    // In a real app, trigger StoreKit purchase here
                    // For now, dismiss
                    dismiss()
                } label: {
                    Text("Start \(selectedTier == .daily ? "Daily" : "Complete")")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.accentGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Text(selectedTier == .daily
                     ? "Unlimited vitamins, barcode scanning & reminders"
                     : "Everything in Daily + consistency reports, family & insights")
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("You're on the Free plan — 3 vitamins, basic reminders.")
                    .font(.system(size: 13))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 8)
            }
        }
    }
}

// MARK: - Tier Card

struct PricingTierCard: View {
    let tier: SubscriptionTier
    let monthlyPrice: Double
    let isAnnual: Bool
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(tier.displayName)
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.textPrimary)

                            if tier == .complete {
                                Text("Best value")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.accentGreen)
                                    .clipShape(Capsule())
                            }
                        }

                        Text(tier.tagline)
                            .font(.system(size: 13))
                            .foregroundColor(.textSecondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        if monthlyPrice == 0 {
                            Text("Free")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.textPrimary)
                        } else {
                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                Text("$\(monthlyPrice, specifier: "%.2f")")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.textPrimary)
                                Text("/mo")
                                    .font(.system(size: 13))
                                    .foregroundColor(.textSecondary)
                            }
                            if isAnnual {
                                Text("$\(monthlyPrice * 12, specifier: "%.2f")/yr")
                                    .font(.system(size: 11))
                                    .foregroundColor(.accentGreen)
                            }
                        }
                    }
                }

                Divider()

                VStack(spacing: 8) {
                    ForEach(tier.features, id: \.self) { feature in
                        HStack(spacing: 10) {
                            Image(systemName: feature.included ? "checkmark.circle.fill" : "xmark.circle")
                                .font(.system(size: 14))
                                .foregroundColor(feature.included ? .accentGreen : .textSecondary.opacity(0.4))

                            Text(feature.label)
                                .font(.system(size: 13))
                                .foregroundColor(feature.included ? .textPrimary : .textSecondary.opacity(0.5))

                            Spacer()
                        }
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.surfaceLight)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isSelected ? Color.accentGreen : Color.inactiveEmpty.opacity(0.5), lineWidth: isSelected ? 2 : 1)
                    )
                    .shadow(color: Color.black.opacity(isSelected ? 0.1 : 0.06), radius: isSelected ? 16 : 10, x: 0, y: 4)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Subscription Tier

enum SubscriptionTier: String, CaseIterable {
    case free, daily, complete

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .daily: return "Daily"
        case .complete: return "Complete"
        }
    }

    var tagline: String {
        switch self {
        case .free: return "For trying out"
        case .daily: return "Everything you need"
        case .complete: return "For serious trackers"
        }
    }

    var monthlyPrice: Double {
        switch self {
        case .free: return 0
        case .daily: return 2.99
        case .complete: return 5.99
        }
    }

    var features: [Feature] {
        switch self {
        case .free:
            return [
                Feature(label: "Up to 3 vitamins", included: true),
                Feature(label: "Basic daily reminders", included: true),
                Feature(label: "Barcode scanning", included: false),
                Feature(label: "Monthly consistency reports", included: false),
                Feature(label: "Multi-user / family sharing", included: false),
                Feature(label: "Health insights", included: false),
            ]
        case .daily:
            return [
                Feature(label: "Unlimited vitamins", included: true),
                Feature(label: "Barcode scanning", included: true),
                Feature(label: "Smart reminders", included: true),
                Feature(label: "Monthly consistency reports", included: false),
                Feature(label: "Multi-user / family sharing", included: false),
                Feature(label: "Health insights", included: false),
            ]
        case .complete:
            return [
                Feature(label: "Unlimited vitamins", included: true),
                Feature(label: "Barcode scanning", included: true),
                Feature(label: "Smart reminders", included: true),
                Feature(label: "Monthly consistency reports", included: true),
                Feature(label: "Multi-user / family sharing", included: true),
                Feature(label: "Health insights", included: true),
            ]
        }
    }
}

struct Feature: Identifiable, Hashable {
    let id = UUID()
    let label: String
    let included: Bool
}

#Preview {
    PricingView()
}
