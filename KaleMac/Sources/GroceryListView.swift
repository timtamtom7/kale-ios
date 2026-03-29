import SwiftUI

struct GroceryListView: View {
    @Binding var groceryItems: [GroceryItem]
    @State private var searchText = ""
    @State private var showingClearConfirmation = false

    var filteredItems: [GroceryItem] {
        groceryItems.filter { item in
            searchText.isEmpty || item.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var groupedItems: [(GroceryCategory, [GroceryItem])] {
        let grouped = Dictionary(grouping: filteredItems) { $0.category }
        return GroceryCategory.allCases.compactMap { category in
            guard let items = grouped[category], !items.isEmpty else { return nil }
            return (category, items)
        }
    }

    var checkedCount: Int {
        groceryItems.filter { $0.isChecked }.count
    }

    var totalCount: Int {
        groceryItems.count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                HStack {
                    Text("Grocery List")
                        .font(.largeTitle.bold())

                    Spacer()

                    if !groceryItems.isEmpty {
                        Text("\(checkedCount)/\(totalCount)")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                }

                if !groceryItems.isEmpty {
                    HStack {
                        Text("Week's groceries")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Clear Checked") {
                            showingClearConfirmation = true
                        }
                        .font(.subheadline)
                        .foregroundStyle(Theme.tomato)
                    }
                }
            }
            .padding()
            .background(Theme.cream)

            // Search
            if !groceryItems.isEmpty {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search items...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(10)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Theme.surface)
            }

            // Grocery list
            if groceryItems.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "cart")
                        .font(.system(size: 64))
                        .foregroundStyle(.tertiary)
                    Text("No Groceries Yet")
                        .font(.title2.bold())
                    Text("Add meals to your weekly plan to auto-generate your grocery list.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        ForEach(groupedItems, id: \.0) { category, items in
                            Section {
                                ForEach(items) { item in
                                    GroceryItemRow(item: binding(for: item))
                                }
                            } header: {
                                CategoryHeader(category: category, count: items.count)
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }
                .background(Theme.surface)
            }
        }
        .confirmationDialog("Clear checked items?", isPresented: $showingClearConfirmation, titleVisibility: .visible) {
            Button("Clear Checked", role: .destructive) {
                groceryItems.removeAll { $0.isChecked }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func binding(for item: GroceryItem) -> Binding<GroceryItem> {
        guard let index = groceryItems.firstIndex(where: { $0.id == item.id }) else {
            return .constant(item)
        }
        return $groceryItems[index]
    }
}

struct GroceryItemRow: View {
    @Binding var item: GroceryItem
    @State private var checkAnimation = false

    var body: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    item.isChecked.toggle()
                    checkAnimation = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    checkAnimation = false
                }
            } label: {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(item.isChecked ? Theme.kaleGreen : .secondary)
                    .scaleEffect(checkAnimation ? 1.2 : 1.0)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.body)
                    .strikethrough(item.isChecked)
                    .foregroundStyle(item.isChecked ? .secondary : .primary)

                if let meal = item.fromMeal {
                    Text("From: \(meal)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Text("\(formatQuantity(item.quantity)) \(item.unit)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(item.isChecked ? Theme.kaleGreen.opacity(0.05) : Color.clear)
        .contentShape(Rectangle())
    }

    private func formatQuantity(_ qty: Double) -> String {
        if qty.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", qty)
        } else {
            return String(format: "%.1f", qty)
        }
    }
}

struct CategoryHeader: View {
    let category: GroceryCategory
    let count: Int

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: category.icon)
                .foregroundStyle(Theme.kaleGreen)
            Text(category.rawValue)
                .font(.headline)
            Spacer()
            Text("\(count)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Theme.surface)
    }
}
