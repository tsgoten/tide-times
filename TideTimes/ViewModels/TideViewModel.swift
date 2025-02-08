import Foundation
import SwiftUI

@MainActor
class TideViewModel: ObservableObject {
    @Published var tideData: TideData?
    @Published var selectedLocation: Location? {
        didSet {
            if let location = selectedLocation {
                saveLocation(location)
                Task {
                    await fetchTideData()
                }
            }
        }
    }
    @Published var isLoading = false
    @Published var error: Error?
    
    private let tideService = TideService()
    private let locationKey = "selectedLocation"
    
    init() {
        loadSavedLocation()
    }
    
    func fetchTideData() async {
        guard let location = selectedLocation else { return }
        
        isLoading = true
        do {
            tideData = try await tideService.fetchTideData(
                latitude: location.latitude,
                longitude: location.longitude
            )
            
            // Debug prints
            if let data = tideData {
                print("Received tide data:")
                print("Heights count: \(data.heights.count)")
                print("Extremes count: \(data.extremes.count)")
                print("Height range: \(data.heights.map(\.height).min() ?? 0) to \(data.heights.map(\.height).max() ?? 0)")
            }
        } catch {
            self.error = error
            print("Error fetching tide data: \(error.localizedDescription)")
        }
        isLoading = false
    }
    
    private func saveLocation(_ location: Location) {
        if let encoded = try? JSONEncoder().encode(location) {
            UserDefaults.standard.set(encoded, forKey: locationKey)
        }
    }
    
    private func loadSavedLocation() {
        if let data = UserDefaults.standard.data(forKey: locationKey),
           let location = try? JSONDecoder().decode(Location.self, from: data) {
            selectedLocation = location
        }
    }
} 