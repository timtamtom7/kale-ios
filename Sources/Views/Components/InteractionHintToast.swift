import SwiftUI

struct InteractionHintToast: View {
    let hint: String
    let onDismiss: () -> Void
    @State private var appeared = false

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentWarm.opacity(0.2))
                    .frame(width: 36, height: 36)
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.yellow)
            }

            Text(hint)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.leading)

            Spacer()

            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    appeared = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    onDismiss()
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.textSecondary)
                    .frame(width: 20, height: 20)
                    .background(Color.inactiveEmpty.opacity(0.3))
                    .clipShape(Circle())
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.surfaceLight)
                .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.accentWarm.opacity(0.4), lineWidth: 1)
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                appeared = true
            }
            // Auto-dismiss after 6 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                if appeared {
                    withAnimation(.easeOut(duration: 0.2)) {
                        appeared = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        onDismiss()
                    }
                }
            }
        }
    }
}

struct InteractionHintService {
    static func getHint(for vitaminName: String) -> SupplementInteraction? {
        let lowercased = vitaminName.lowercased()
        var candidates: [SupplementInteraction] = []

        for interaction in SupplementInteraction.allInteractions {
            if lowercased.contains(interaction.trigger.lowercased()) {
                candidates.append(interaction)
            }
        }

        return candidates.sorted { $0.priority < $1.priority }.first
    }

    static func getHints(for vitaminNames: [String]) -> [SupplementInteraction] {
        var results: [SupplementInteraction] = []
        var seen = Set<String>()

        for name in vitaminNames {
            if let hint = getHint(for: name), !seen.contains(hint.id) {
                seen.insert(hint.id)
                results.append(hint)
            }
        }

        return results.sorted { $0.priority < $1.priority }
    }
}
