import SwiftUI

struct RequestLocationView: View {
    let locationService: LocationService
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "location.circle")
                .font(.system(size: 64))
                .foregroundColor(.blue)
            
            Text("Location Access")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("We'll show you tide information for coastal locations near you")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                locationService.requestLocationPermission()
            } label: {
                Text("Allow Location Access")
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .padding()
    }
} 