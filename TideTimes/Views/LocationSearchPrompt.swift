import SwiftUI

struct LocationSearchPrompt: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "location.magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(.blue)
                .frame(width: 80, height: 80)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())
            
            Text("Find Your Location")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Search for a coastal location to view tide information")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(32)
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(16)
        .padding()
    }
}

#Preview {
    LocationSearchPrompt()
} 