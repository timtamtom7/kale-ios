import SwiftUI
import AVFoundation

// MARK: - Camera Permission Denied View

struct CameraPermissionDeniedView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.accentGreen.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "camera.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.accentGreen.opacity(0.6))
            }

            VStack(spacing: 10) {
                Text("Camera access needed")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.textPrimary)

                Text("Kale needs camera access to scan\nsupplement barcodes.")
                    .font(.system(size: 15))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "gear")
                    Text("Open Settings")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(Color.accentGreen)
                .clipShape(Capsule())
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundLight)
    }
}

// MARK: - Barcode Scan Failed View

struct BarcodeScanFailedView: View {
    let onRetry: () -> Void
    let onEnterManually: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "barcode.viewfinder")
                    .font(.system(size: 36))
                    .foregroundColor(.yellow.opacity(0.7))
            }

            VStack(spacing: 10) {
                Text("Couldn't read that one")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.textPrimary)

                Text("We couldn't find this barcode.\nYou can try again or enter details manually.")
                    .font(.system(size: 15))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            VStack(spacing: 12) {
                Button(action: onRetry) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button(action: onEnterManually) {
                    Text("Enter manually")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.accentGreen)
                }
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundLight)
    }
}

// MARK: - Notification Permission Denied View

struct NotificationPermissionDeniedView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.accentGreen.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "bell.slash.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.accentGreen.opacity(0.6))
            }

            VStack(spacing: 10) {
                Text("No notifications")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.textPrimary)

                Text("Enable notifications in Settings to get\ndaily reminders to take your vitamins.")
                    .font(.system(size: 15))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "gear")
                    Text("Open Settings")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(Color.accentGreen)
                .clipShape(Capsule())
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundLight)
    }
}

// MARK: - Empty State View (No Vitamins)

struct EmptyVitaminsView: View {
    let onAddVitamin: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Botanical illustration
            ZStack {
                Circle()
                    .fill(Color.accentGreen.opacity(0.08))
                    .frame(width: 140, height: 140)

                VStack(spacing: 0) {
                    Image(systemName: "pills.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.accentGreen.opacity(0.7))

                    HStack(spacing: -8) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.accentWarm)
                            .rotationEffect(.degrees(-20))
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.accentWarm.opacity(0.7))
                            .rotationEffect(.degrees(15))
                    }
                }
            }

            VStack(spacing: 10) {
                Text("Your supplement cabinet\nis empty.")
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Add your first vitamin to start\nbuilding a daily habit.")
                    .font(.system(size: 15))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            Button(action: onAddVitamin) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                    Text("Add Vitamin")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(Color.accentGreen)
                .clipShape(Capsule())
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundLight)
    }
}

// MARK: - Animated Checkmark

struct AnimatedCheckmark: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.accentGreen)
                .frame(width: 60, height: 60)
                .scaleEffect(animate ? 1.0 : 0.5)
                .opacity(animate ? 1.0 : 0.0)

            Image(systemName: "checkmark")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .scaleEffect(animate ? 1.0 : 0.3)
                .opacity(animate ? 1.0 : 0.0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                animate = true
            }
        }
    }
}

// MARK: - Scan Overlay (improved barcode scanning UI)

struct ScanOverlayView: View {
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack {
                HStack {
                    Button(action: onCancel) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)

                Spacer()

                // Scan frame
                ZStack {
                    // Dimmed area with cutout
                    Rectangle()
                        .fill(Color.black.opacity(0.4))
                        .mask(
                            Rectangle()
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .frame(width: 280, height: 110)
                                        .blendMode(.destinationOut)
                                )
                        )

                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.accentGreen, lineWidth: 3)
                        .frame(width: 280, height: 110)

                    // Corner brackets
                    Group {
                        // Top-left
                        Path { p in
                            p.move(to: CGPoint(x: -5, y: 30))
                            p.addLine(to: CGPoint(x: -5, y: -5))
                            p.addLine(to: CGPoint(x: 30, y: -5))
                        }
                        .stroke(Color.accentGreen, lineWidth: 4)
                        .frame(width: 280, height: 110)

                        // Top-right
                        Path { p in
                            p.move(to: CGPoint(x: 250, y: -5))
                            p.addLine(to: CGPoint(x: 285, y: -5))
                            p.addLine(to: CGPoint(x: 285, y: 30))
                        }
                        .stroke(Color.accentGreen, lineWidth: 4)
                        .frame(width: 280, height: 110)

                        // Bottom-left
                        Path { p in
                            p.move(to: CGPoint(x: -5, y: 80))
                            p.addLine(to: CGPoint(x: -5, y: 115))
                            p.addLine(to: CGPoint(x: 30, y: 115))
                        }
                        .stroke(Color.accentGreen, lineWidth: 4)
                        .frame(width: 280, height: 110)

                        // Bottom-right
                        Path { p in
                            p.move(to: CGPoint(x: 250, y: 115))
                            p.addLine(to: CGPoint(x: 285, y: 115))
                            p.addLine(to: CGPoint(x: 285, y: 80))
                        }
                        .stroke(Color.accentGreen, lineWidth: 4)
                        .frame(width: 280, height: 110)
                    }
                }
                .frame(width: 280, height: 110)

                Spacer()

                VStack(spacing: 16) {
                    Text("Point camera at barcode")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)

                    Button {
                        // Manual entry — handled by parent
                    } label: {
                        Text("Enter manually")
                            .font(.system(size: 14))
                            .foregroundColor(.accentGreen)
                    }
                }
                .padding(.bottom, 60)
            }
        }
    }
}

#Preview("Camera Permission Denied") {
    CameraPermissionDeniedView()
}

#Preview("Barcode Scan Failed") {
    BarcodeScanFailedView(onRetry: {}, onEnterManually: {})
}

#Preview("Notification Permission Denied") {
    NotificationPermissionDeniedView()
}

#Preview("Empty Vitamins") {
    EmptyVitaminsView(onAddVitamin: {})
}



// MARK: - Calendar Data Missing

struct CalendarDataMissingView: View {
    let date: Date
    var onRetry: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 32))
                .foregroundColor(.textSecondary)

            Text("Couldn't load calendar data")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.textPrimary)

            Text("There was a problem loading your tracking data for this month.")
                .font(.system(size: 12))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)

            if onRetry != nil {
                Button {
                    onRetry?()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                        Text("Retry")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.accentGreen)
                }
                .padding(.top, 4)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.surfaceLight)
        )
    }
}

// MARK: - Low Stock Notification Failed

struct LowStockNotificationFailedView: View {
    let vitaminName: String
    let onRetry: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: "bell.slash.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.red.opacity(0.7))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Notification failed")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.textPrimary)
                Text("Couldn't notify for \(vitaminName). Check notification permissions.")
                    .font(.system(size: 11))
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            Button(action: onRetry) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.accentGreen)
                    .frame(width: 32, height: 32)
                    .background(Color.accentGreen.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.red.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.red.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview("Low Stock Detection Failed") {
    LowStockDetectionFailedView(onRetry: {})
        .padding()
        .background(Color.backgroundLight)
}

#Preview("Calendar Data Missing") {
    CalendarDataMissingView(date: Date())
        .padding()
        .background(Color.backgroundLight)
}

#Preview("Notification Failed") {
    LowStockNotificationFailedView(vitaminName: "Vitamin D3", onRetry: {})
        .padding()
        .background(Color.backgroundLight)
}
