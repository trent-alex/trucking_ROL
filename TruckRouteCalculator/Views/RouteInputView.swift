import SwiftUI

struct RouteInputView: View {
    @ObservedObject var viewModel: RouteCalculatorViewModel

    var body: some View {
        VStack(spacing: 16) {
            // Origin Input
            VStack(alignment: .leading, spacing: 8) {
                Label("Origin", systemImage: "location.circle.fill")
                    .font(.headline)
                    .foregroundColor(.green)

                TextField("Enter pickup location", text: $viewModel.origin)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.words)
                    .onChange(of: viewModel.origin) {
                        viewModel.searchOrigin()
                    }

                // Origin Suggestions
                if !viewModel.originSuggestions.isEmpty {
                    SuggestionsListView(
                        suggestions: viewModel.originSuggestions,
                        onSelect: viewModel.selectOrigin
                    )
                }
            }

            // Destination Input
            VStack(alignment: .leading, spacing: 8) {
                Label("Destination", systemImage: "mappin.circle.fill")
                    .font(.headline)
                    .foregroundColor(.red)

                TextField("Enter delivery location", text: $viewModel.destination)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.words)
                    .onChange(of: viewModel.destination) {
                        viewModel.searchDestination()
                    }

                // Destination Suggestions
                if !viewModel.destinationSuggestions.isEmpty {
                    SuggestionsListView(
                        suggestions: viewModel.destinationSuggestions,
                        onSelect: viewModel.selectDestination
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct SuggestionsListView: View {
    let suggestions: [LocationSuggestion]
    let onSelect: (LocationSuggestion) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(suggestions.prefix(5)) { suggestion in
                Button(action: { onSelect(suggestion) }) {
                    HStack {
                        Image(systemName: "mappin")
                            .foregroundColor(.gray)
                        VStack(alignment: .leading) {
                            Text(suggestion.title)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            if !suggestion.subtitle.isEmpty {
                                Text(suggestion.subtitle)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 8)
                }
                Divider()
            }
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}

#Preview {
    RouteInputView(viewModel: RouteCalculatorViewModel())
        .padding()
}
