import SwiftUI

struct VitaminCard: View {
    let vitamin: Vitamin
    let isTaken: Bool
    let onToggle: () -> Void

    @State private var animateCheck = false
    @State private var scale: CGFloat = 1.0

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                animateCheck = true
                scale = 1.04
            }
            onToggle()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    animateCheck = false
                    scale = 1.0
                }
            }
        }) {
            HStack(spacing: 16) {
                pillIcon
                VStack(alignment: .leading, spacing: 2) {
                    Text(vitamin.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(isTaken ? .white : .textPrimary)
                    Text(vitamin.dosage)
                        .font(.system(size: 13))
                        .foregroundColor(isTaken ? .white.opacity(0.8) : .textSecondary)
                }
                Spacer()
                checkmark
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isTaken ? Color.accentGreen : Color.surfaceLight)
                    .shadow(color: Color.black.opacity(isTaken ? 0.05 : 0.08), radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isTaken ? Color.accentGreen.opacity(0.3) : Color.inactiveEmpty.opacity(0.5), lineWidth: 1)
            )
            .scaleEffect(scale)
        }
        .buttonStyle(.plain)
    }

    private var pillIcon: some View {
        ZStack {
            Circle()
                .fill(isTaken ? Color.white.opacity(0.25) : Color.accentGreen.opacity(0.1))
                .frame(width: 40, height: 40)

            Text(vitamin.pillEmoji)
                .font(.system(size: 20))
                .opacity(isTaken ? 0.9 : 1.0)
        }
    }

    private var checkmark: some View {
        ZStack {
            Circle()
                .stroke(isTaken ? Color.white.opacity(0.5) : Color.inactiveEmpty, lineWidth: 1.5)
                .frame(width: 26, height: 26)

            if isTaken {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .scaleEffect(animateCheck ? 1.2 : 1.0)
                    .opacity(animateCheck ? 1.0 : 0.8)
            }
        }
        .frame(width: 26, height: 26)
    }
}

#Preview {
    VStack {
        VitaminCard(
            vitamin: Vitamin(name: "Vitamin D3", dosage: "2000 IU", pillEmoji: "💊"),
            isTaken: false,
            onToggle: {}
        )
        VitaminCard(
            vitamin: Vitamin(name: "Magnesium", dosage: "400mg", pillEmoji: "🫙"),
            isTaken: true,
            onToggle: {}
        )
    }
    .padding()
    .background(Color.backgroundLight)
}
