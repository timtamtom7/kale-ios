import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            Color.backgroundLight.ignoresSafeArea()

            TabView(selection: $currentPage) {
                OnboardingPage1()
                    .tag(0)
                OnboardingPage2()
                    .tag(1)
                OnboardingPage3()
                    .tag(2)
                OnboardingPage4(onComplete: onComplete)
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)

            VStack {
                Spacer()
                pageIndicator
                    .padding(.bottom, 40)
            }
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color.accentGreen : Color.inactiveEmpty)
                    .frame(width: index == currentPage ? 8 : 6, height: index == currentPage ? 8 : 6)
                    .animation(.spring(response: 0.3), value: currentPage)
            }
        }
    }
}

// MARK: - Page 1: Concept

struct OnboardingPage1: View {
    var body: some View {
        ZStack {
            BotanicalBackground(intensity: 0.6)

            VStack(spacing: 32) {
                Spacer()

                // Botanical leaf cluster illustration
                ZStack {
                    Circle()
                        .fill(Color.accentGreen.opacity(0.12))
                        .frame(width: 200, height: 200)

                    // Main leaf shape (SF Symbol composite)
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.accentGreen, Color(hex: "22c55e")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .rotationEffect(.degrees(-15))

                    // Secondary leaves
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.accentWarm.opacity(0.8))
                        .rotationEffect(.degrees(60))
                        .offset(x: 60, y: -30)

                    Image(systemName: "leaf.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(Color.accentWarm.opacity(0.6))
                        .rotationEffect(.degrees(110))
                        .offset(x: 30, y: 50)
                }
                .padding(.top, 40)

                VStack(spacing: 16) {
                    Text("Every day starts with this.")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("Not a lecture. Not a checklist.\nJust a quiet habit that compounds.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 40)

                Spacer()
                Spacer()
            }
        }
    }
}

// MARK: - Page 2: Add vitamins

struct OnboardingPage2: View {
    var body: some View {
        ZStack {
            BotanicalBackground(intensity: 0.4)

            VStack(spacing: 32) {
                Spacer()

                // Barcode scan illustration
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.surfaceLight)
                        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 8)
                        .frame(width: 220, height: 140)

                    VStack(spacing: 12) {
                        // Barcode lines
                        HStack(spacing: 3) {
                            ForEach([3, 2, 4, 1, 3, 5, 2, 1, 4, 3, 2, 5, 1], id: \.self) { width in
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(Color.textPrimary)
                                    .frame(width: CGFloat(width * 2 + 1), height: 40)
                            }
                        }
                        .padding(.horizontal, 20)

                        Text("0634157000085")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.textSecondary)

                        HStack(spacing: 4) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 12))
                            Text("Vitamin D3")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(.accentGreen)
                    }
                }

                // Camera frame overlay
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.accentGreen, lineWidth: 3)
                        .frame(width: 260, height: 100)

                    // Corner accents
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 20))
                        path.addLine(to: CGPoint(x: 0, y: 0))
                        path.addLine(to: CGPoint(x: 20, y: 0))
                    }
                    .stroke(Color.accentGreen, lineWidth: 3)
                    .offset(x: -130, y: -50)

                    Path { path in
                        path.move(to: CGPoint(x: -20, y: 0))
                        path.addLine(to: CGPoint(x: 0, y: 0))
                        path.addLine(to: CGPoint(x: 0, y: 20))
                    }
                    .stroke(Color.accentGreen, lineWidth: 3)
                    .offset(x: 130, y: 50)
                }

                VStack(spacing: 16) {
                    Text("Scan. Done.")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundColor(.textPrimary)

                    Text("Point your camera at any supplement\nbarcode. Kale fills in the rest.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 40)

                Spacer()
                Spacer()
            }
        }
    }
}

// MARK: - Page 3: Never forget

struct OnboardingPage3: View {
    var body: some View {
        ZStack {
            BotanicalBackground(intensity: 0.3)

            VStack(spacing: 32) {
                Spacer()

                // Notification illustration
                ZStack {
                    // Phone mockup
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.surfaceLight)
                        .shadow(color: Color.black.opacity(0.12), radius: 24, x: 0, y: 12)
                        .frame(width: 180, height: 360)

                    VStack(spacing: 0) {
                        // Dynamic Island
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black)
                            .frame(width: 80, height: 24)
                            .padding(.top, 12)

                        Spacer()

                        // Notification card
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "leaf.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.accentGreen)
                                Text("Kale")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.textPrimary)
                                Spacer()
                            }

                            Text("Good morning. 🌿")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.textPrimary)

                            Text("Today: Vitamin D + Magnesium")
                                .font(.system(size: 13))
                                .foregroundColor(.textSecondary)

                            HStack(spacing: 12) {
                                Button {
                                } label: {
                                    Text("Take")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 8)
                                        .background(Color.accentGreen)
                                        .clipShape(Capsule())
                                }

                                Button {
                                } label: {
                                    Text("Later")
                                        .font(.system(size: 13))
                                        .foregroundColor(.textSecondary)
                                }
                            }
                            .padding(.top, 4)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.backgroundLight)
                        )
                        .padding(.horizontal, 16)

                        Spacer()
                    }
                }

                VStack(spacing: 16) {
                    Text("Never wonder again.")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundColor(.textPrimary)

                    Text("One gentle notification each morning.\nTap to confirm. That's the whole ritual.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 40)

                Spacer()
                Spacer()
            }
        }
    }
}

// MARK: - Page 4: Start taking

struct OnboardingPage4: View {
    let onComplete: () -> Void
    @EnvironmentObject var notificationService: NotificationService
    @State private var showingNotificationPermission = false

    var body: some View {
        ZStack {
            BotanicalBackground(intensity: 0.5)

            VStack(spacing: 32) {
                Spacer()

                // Animated check illustration
                ZStack {
                    Circle()
                        .fill(Color.accentGreen.opacity(0.15))
                        .frame(width: 160, height: 160)

                    Circle()
                        .fill(Color.accentGreen.opacity(0.1))
                        .frame(width: 120, height: 120)

                    Image(systemName: "checkmark")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.accentGreen)
                        .scaleEffect(1.0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.5).delay(0.2), value: UUID())
                }

                VStack(spacing: 16) {
                    Text("Start taking.")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundColor(.textPrimary)

                    Text("You can add your first supplement now.\nWe'll remind you every morning.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 40)

                // Sample vitamins preview
                VStack(spacing: 10) {
                    SampleVitaminRow(emoji: "💊", name: "Vitamin D3", dosage: "2000 IU")
                    SampleVitaminRow(emoji: "🫙", name: "Magnesium", dosage: "400mg")
                    SampleVitaminRow(emoji: "🐟", name: "Omega-3", dosage: "1000mg")
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.surfaceLight.opacity(0.8))
                        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
                )

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        notificationService.requestAuthorization()
                        onComplete()
                    } label: {
                        Text("Get Started")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.accentGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button {
                        onComplete()
                    } label: {
                        Text("Skip for now")
                            .font(.system(size: 14))
                            .foregroundColor(.textSecondary)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }
}

struct SampleVitaminRow: View {
    let emoji: String
    let name: String
    let dosage: String

    var body: some View {
        HStack(spacing: 12) {
            Text(emoji)
                .font(.system(size: 20))
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(Color.accentGreen.opacity(0.1))
                )

            Text(name)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.textPrimary)

            Spacer()

            Text(dosage)
                .font(.system(size: 13))
                .foregroundColor(.textSecondary)
        }
    }
}

// MARK: - Botanical Background

struct BotanicalBackground: View {
    let intensity: Double

    var body: some View {
        ZStack {
            // Soft cream base
            Color.backgroundLight

            // Large organic blob top-right
            BlobShape()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.accentGreen.opacity(0.08 * intensity),
                            Color.accentGreen.opacity(0.0)
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: 150, y: -150)

            // Bottom-left blob
            BlobShape()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.accentWarm.opacity(0.06 * intensity),
                            Color.accentWarm.opacity(0.0)
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)
                .offset(x: -100, y: 300)

            // Floating leaf top-left
            Image(systemName: "leaf.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.accentGreen.opacity(0.06 * intensity))
                .rotationEffect(.degrees(-30))
                .offset(x: -80, y: 80)

            // Small leaf mid-right
            Image(systemName: "leaf.fill")
                .font(.system(size: 30))
                .foregroundStyle(Color.accentWarm.opacity(0.08 * intensity))
                .rotationEffect(.degrees(45))
                .offset(x: 120, y: 200)
        }
    }
}

// Organic blob shape
struct BlobShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        path.move(to: CGPoint(x: w * 0.5, y: h * 0.05))
        path.addCurve(
            to: CGPoint(x: w * 0.95, y: h * 0.4),
            control1: CGPoint(x: w * 0.75, y: h * 0.0),
            control2: CGPoint(x: w * 1.0, y: h * 0.2)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.7, y: h * 0.95),
            control1: CGPoint(x: w * 0.9, y: h * 0.7),
            control2: CGPoint(x: w * 0.8, y: h * 1.0)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.1, y: h * 0.6),
            control1: CGPoint(x: w * 0.5, y: h * 0.9),
            control2: CGPoint(x: w * 0.1, y: h * 0.85)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.3, y: h * 0.15),
            control1: CGPoint(x: w * 0.1, y: h * 0.35),
            control2: CGPoint(x: w * 0.15, y: h * 0.05)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.5, y: h * 0.05),
            control1: CGPoint(x: w * 0.35, y: h * 0.0),
            control2: CGPoint(x: w * 0.45, y: h * 0.0)
        )

        return path
    }
}

#Preview {
    OnboardingView(onComplete: {})
        .environmentObject(NotificationService.shared)
}
