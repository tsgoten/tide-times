import Foundation
import CoreLocation
import MapKit

class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var searchResults: [Location] = []
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    private let geocoder = CLGeocoder()
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func searchLocations(_ query: String) {
        guard !query.isEmpty else {
            searchNearbyCoastalLocations()
            return
        }
        
        print("Searching for: \(query)")
        
        Task {
            do {
                let placemarks = try await geocoder.geocodeAddressString(query)
                print("Found \(placemarks.count) results")
                
                await MainActor.run {
                    self.searchResults = placemarks.compactMap { placemark in
                        guard let name = placemark.name ?? placemark.locality ?? placemark.country,
                              let location = placemark.location else {
                            return nil
                        }
                        
                        let result = Location(
                            id: "\(location.coordinate.latitude),\(location.coordinate.longitude)",
                            name: name,
                            latitude: location.coordinate.latitude,
                            longitude: location.coordinate.longitude
                        )
                        print("Added result: \(result.name)")
                        return result
                    }
                }
            } catch {
                print("Geocoding error: \(error.localizedDescription)")
                await MainActor.run {
                    self.searchResults = []
                }
            }
        }
    }
    
    private func searchNearbyCoastalLocations() {
        guard let location = locationManager.location else {
            print("No current location available")
            return
        }
        
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = "harbor OR beach OR port OR marina OR pier"
        searchRequest.region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 25000, // 25km radius
            longitudinalMeters: 25000
        )
        
        Task {
            do {
                let response = try await MKLocalSearch(request: searchRequest).start()
                
                await MainActor.run {
                    self.searchResults = response.mapItems.compactMap { item in
                        guard let name = item.name else { return nil }
                        return Location(
                            id: "\(item.placemark.coordinate.latitude),\(item.placemark.coordinate.longitude)",
                            name: name,
                            latitude: item.placemark.coordinate.latitude,
                            longitude: item.placemark.coordinate.longitude
                        )
                    }
                    .sorted { $0.name < $1.name }
                    
                    print("Found \(self.searchResults.count) coastal locations")
                }
            } catch {
                print("Local search error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            if manager.authorizationStatus == .authorizedWhenInUse {
                searchNearbyCoastalLocations()
            }
        }
    }
} 