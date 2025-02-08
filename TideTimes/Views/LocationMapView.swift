import SwiftUI
import MapKit

struct LocationMapView: View {
    let location: Location
    
    var body: some View {
        Map(position: .constant(MapCameraPosition.region(region))) {
            // Location pin
            Marker(location.name, coordinate: coordinate)
            
            // 10km radius circle
            MapCircle(center: coordinate, radius: 10000)
                .foregroundStyle(.blue.opacity(0.2))
                .stroke(.blue, lineWidth: 1)
        }
        .frame(height: 150)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: location.latitude,
            longitude: location.longitude
        )
    }
    
    private var region: MKCoordinateRegion {
        MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 25000, // Show slightly more than the 10km radius
            longitudinalMeters: 25000
        )
    }
} 