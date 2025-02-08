import SwiftUI
import CoreLocation

struct LocationSearchView: View {
    let searchResults: [Location]
    @Binding var selectedLocation: Location?
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationService = LocationService()
    @State private var searchText = ""
    @State private var recentSearches: [Location] = []
    
    var body: some View {
        NavigationView {
            Group {
                if searchText.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        if !recentSearches.isEmpty {
                            Text("Recent Searches")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            List(recentSearches) { location in
                                Button {
                                    selectedLocation = location
                                    RecentSearchService.addRecentSearch(location)
                                    dismiss()
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(location.name)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        HStack {
                                            Image(systemName: "clock.arrow.circlepath")
                                                .font(.caption)
                                            Text(String(format: "%.4f°, %.4f°", location.latitude, location.longitude))
                                                .font(.caption)
                                        }
                                        .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                            .listStyle(.plain)
                        } else {
                            ContentUnavailableView(
                                "Search Locations",
                                systemImage: "location.magnifyingglass",
                                description: Text("Enter a city, harbor, or coastal location")
                            )
                        }
                    }
                } else if locationService.searchResults.isEmpty {
                    ContentUnavailableView(
                        "No Locations Found",
                        systemImage: "location.slash",
                        description: Text("Try searching for a different location")
                    )
                } else {
                    List(locationService.searchResults) { location in
                        Button {
                            selectedLocation = location
                            RecentSearchService.addRecentSearch(location)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(location.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                HStack {
                                    Image(systemName: "location.fill")
                                        .font(.caption)
                                    Text(String(format: "%.4f°, %.4f°", location.latitude, location.longitude))
                                        .font(.caption)
                                }
                                .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .searchable(text: $searchText, prompt: "Search locations")
            .onChange(of: searchText) { _, newValue in
                locationService.searchLocations(newValue)
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            recentSearches = RecentSearchService.getRecentSearches()
        }
    }
}

#Preview {
    LocationSearchView(
        searchResults: [
            Location(id: "1", name: "San Francisco", latitude: 37.7749, longitude: -122.4194),
            Location(id: "2", name: "New York", latitude: 40.7128, longitude: -74.0060)
        ],
        selectedLocation: .constant(nil)
    )
} 