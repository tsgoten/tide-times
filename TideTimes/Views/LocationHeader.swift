import SwiftUI

struct LocationHeader: View {
    let location: Location
    
    var body: some View {
        VStack(spacing: 8) {
            Text(location.name)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .minimumScaleFactor(0.75)
            
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.secondary)
                    .font(.caption)
                Text(String(format: "%.4f°, %.4f°", location.latitude, location.longitude))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            LocationMapView(location: location)
                .padding(.top, 8)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

#Preview {
    LocationHeader(location: Location(
        id: "1",
        name: "San Francisco",
        latitude: 37.7749,
        longitude: -122.4194
    ))
} 