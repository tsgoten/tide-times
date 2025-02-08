import SwiftUI

struct TideExtremesTable: View {
    let tideData: TideData
    
    private var relevantExtremes: [TideExtreme] {
        let now = Date()
        let sortedExtremes = tideData.extremes.sorted { $0.date < $1.date }
        
        let pastExtremes = sortedExtremes
            .filter { $0.date < now }
            .suffix(2)
        
        let futureExtremes = sortedExtremes
            .filter { $0.date > now }
            .prefix(2)
        
        return (Array(pastExtremes) + Array(futureExtremes))
            .sorted { $0.date < $1.date }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Tide Extremes")
                .font(.headline)
                .padding(.bottom, 4)
            
            ForEach(relevantExtremes) { extreme in
                HStack(spacing: 16) {
                    // Tide type icon with background
                    ZStack {
                        Circle()
                            .fill(extreme.isHigh ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: extreme.isHigh ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            .foregroundColor(extreme.isHigh ? .red : .blue)
                            .font(.title2)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        // Tide type and height
                        Text("\(extreme.type) Tide")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(String(format: "%.1f meters", extreme.height))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Time with relative indicator
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(extreme.date, style: .time)
                            .font(.body)
                            .monospacedDigit()
                            .foregroundColor(.primary)
                        
                        Text(extreme.date, style: .relative)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(12)
            }
        }
        .padding()
    }
}

#Preview {
    TideExtremesTable(tideData: TideData(
        status: 200,
        callCount: 1,
        requestLat: 37.7749,
        requestLon: -122.4194,
        responseLat: 37.7749,
        responseLon: -122.4194,
        atlas: "NOAA",
        copyright: "NOAA CO-OPS API",
        heights: [],
        extremes: [
            TideExtreme(dt: Date().timeIntervalSince1970 - 3600, height: 1.2, type: "Low"),
            TideExtreme(dt: Date().timeIntervalSince1970 + 3600, height: 2.1, type: "High"),
            TideExtreme(dt: Date().timeIntervalSince1970 + 7200, height: 0.8, type: "Low"),
            TideExtreme(dt: Date().timeIntervalSince1970 - 7200, height: 1.9, type: "High")
        ]
    ))
} 