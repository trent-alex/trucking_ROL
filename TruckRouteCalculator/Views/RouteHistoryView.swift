import SwiftUI
import SwiftData

struct RouteHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \SavedRoute.savedAt, order: .reverse) private var savedRoutes: [SavedRoute]

    var viewModel: RouteCalculatorViewModel

    var body: some View {
        NavigationView {
            Group {
                if savedRoutes.isEmpty {
                    emptyState
                } else {
                    routeList
                }
            }
            .navigationTitle("Route History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No Saved Routes")
                .font(.title3)
                .fontWeight(.semibold)
            Text("Routes you save will appear here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var routeList: some View {
        List {
            ForEach(savedRoutes) { route in
                Button {
                    viewModel.loadSavedRoute(route)
                    dismiss()
                } label: {
                    routeRow(route)
                }
                .tint(.primary)
            }
            .onDelete(perform: deleteRoutes)
        }
        .listStyle(.insetGrouped)
    }

    private func routeRow(_ route: SavedRoute) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(route.origin)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(route.destination)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                    }
                }
                Spacer()
                Text("$\(String(format: "%.2f", route.totalCost))")
                    .font(.headline)
                    .foregroundColor(.blue)
            }
            HStack {
                Text("\(Int(route.distanceMiles)) mi")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(route.savedAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func deleteRoutes(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(savedRoutes[index])
        }
    }
}
