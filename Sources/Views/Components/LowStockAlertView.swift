import SwiftUI

struct LowStockAlertCard: View {
    let vitamin: Vitamin
    let onUpdateStock: () -> Void
    @State private var appeared = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.orange)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Low stock: \(vitamin.name)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textPrimary)
                if let stock = vitamin.stockCount {
                    let days = stock / max(vitamin.dailyDose, 1)
                    Text("\(days) days left (\(stock) capsules)")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                }
            }

            Spacer()

            Button {
                onUpdateStock()
            } label: {
                Text("Update")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange)
                    .clipShape(Capsule())
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Color.orange.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -10)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                appeared = true
            }
        }
    }
}

struct LowStockSheet: View {
    let vitamins: [Vitamin]
    @EnvironmentObject var databaseService: DatabaseService
    @Environment(\.dismiss) var dismiss
    @State private var editingVitamin: Vitamin?
    @State private var stockText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundLight.ignoresSafeArea()

                if vitamins.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.accentGreen)
                        Text("All stocked up!")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.textPrimary)
                        Text("No vitamins running low right now.")
                            .font(.system(size: 14))
                            .foregroundColor(.textSecondary)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(vitamins) { vitamin in
                                LowStockAlertCard(vitamin: vitamin) {
                                    editingVitamin = vitamin
                                    stockText = vitamin.stockCount.map { "\($0)" } ?? ""
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Low Stock Alert")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.accentGreen)
                }
            }
            .sheet(item: $editingVitamin) { vitamin in
                stockEditSheet(for: vitamin)
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func stockEditSheet(for vitamin: Vitamin) -> some View {
        NavigationStack {
            ZStack {
                Color.backgroundLight.ignoresSafeArea()
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Capsules remaining for \(vitamin.name)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.textSecondary)
                        TextField("e.g. 60", text: $stockText)
                            .font(.system(size: 17))
                            .keyboardType(.numberPad)
                            .padding(12)
                            .background(Color.surfaceLight)
                            .cornerRadius(Theme.CornerRadius.md)
                    }

                    Button {
                        if let count = Int(stockText) {
                            try? databaseService.updateStock(for: vitamin, count: count)
                            editingVitamin = nil
                        }
                    } label: {
                        Text("Save")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.accentGreen)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
                    }
                    .disabled(Int(stockText) == nil)

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Update Stock")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { editingVitamin = nil }
                        .foregroundColor(.accentGreen)
                }
            }
        }
        .presentationDetents([.height(280)])
    }
}

struct LowStockDetectionFailedView: View {
    let onRetry: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.red)
            Text("Couldn't check stock levels. Make sure stock tracking is enabled.")
                .font(.system(size: 13))
                .foregroundColor(.textSecondary)
            Spacer()
            Button(action: onRetry) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12))
                    .foregroundColor(.accentGreen)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Color.red.opacity(0.08))
        )
    }
}
