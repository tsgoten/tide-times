import SwiftUI

struct TideGraph: View {
    let tideData: TideData
    
    private var minHeight: Double {
        min(
            tideData.heights.map(\.height).min() ?? 0,
            tideData.extremes.map(\.height).min() ?? 0
        )
    }
    
    private var maxHeight: Double {
        max(
            tideData.heights.map(\.height).max() ?? 0,
            tideData.extremes.map(\.height).max() ?? 0
        )
    }
    
    private var currentTimePoint: CGPoint? {
        let now = Date()
        guard let index = tideData.heights.firstIndex(where: { $0.date > now }),
              index > 0 else { return nil }
        
        let prev = tideData.heights[index - 1]
        let next = tideData.heights[index]
        let progress = (now.timeIntervalSince1970 - prev.dt) / (next.dt - prev.dt)
        
        let height = prev.height + (next.height - prev.height) * progress
        return CGPoint(x: Double(index - 1) + progress, y: height)
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .top, spacing: 0) {
                // Y-axis labels
                VStack {
                    ForEach(0..<5) { i in
                        Text(String(format: "%.1fm", minHeight + (maxHeight - minHeight) * Double(4 - i) / 4))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(height: 44)
                        if i < 4 {
                            Spacer()
                        }
                    }
                }
                .frame(width: 32)
                
                // Main graph area
                VStack(spacing: 0) {
                    // Graph with grid
                    ZStack {
                        // Grid lines
                        VStack(spacing: 0) {
                            ForEach(0..<5) { i in
                                Divider()
                                    .overlay(Color.gray.opacity(0.2))
                                if i < 4 {
                                    Spacer()
                                }
                            }
                        }
                        
                        // Curved tide line with gradient
                        Path { path in
                            let points = tideData.heights.enumerated().map { index, height in
                                CGPoint(
                                    x: CGFloat(index) * ((geometry.size.width - 36) / CGFloat(tideData.heights.count - 1)),
                                    y: geometry.size.height * 0.85 * (1 - CGFloat((height.height - minHeight) / (maxHeight - minHeight)))
                                )
                            }
                            
                            path.move(to: points[0])
                            for i in 1..<points.count {
                                let prev = points[i - 1]
                                let current = points[i]
                                
                                let control1 = CGPoint(
                                    x: prev.x + (current.x - prev.x) / 2,
                                    y: prev.y
                                )
                                let control2 = CGPoint(
                                    x: prev.x + (current.x - prev.x) / 2,
                                    y: current.y
                                )
                                
                                path.addCurve(to: current, control1: control1, control2: control2)
                            }
                        }
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue.opacity(0.7), .blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 3
                        )
                        
                        // Current time indicator
                        if let currentPoint = currentTimePoint {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 12, height: 12)
                                .shadow(color: .black.opacity(0.2), radius: 2)
                                .position(
                                    x: ((geometry.size.width - 36) * CGFloat(currentPoint.x) / CGFloat(tideData.heights.count - 1)),
                                    y: geometry.size.height * 0.85 * (1 - CGFloat((currentPoint.y - minHeight) / (maxHeight - minHeight)))
                                )
                        }
                    }
                    .frame(height: geometry.size.height * 0.85)
                    
                    // Time axis at bottom
                    HStack {
                        ForEach(tideData.extremes) { extreme in
                            if let index = tideData.heights.firstIndex(where: { abs($0.dt - extreme.dt) < 1800 }) {
                                Text(extreme.date, style: .time)
                                    .font(.caption2)
                                    .foregroundColor(extreme.isHigh ? .red : .blue)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .padding(.trailing, 4)
        }
        .padding(.horizontal, 4)
    }
}

#Preview {
    TideGraph(tideData: TideData(
        status: 200,
        callCount: 1,
        requestLat: 37.7749,
        requestLon: -122.4194,
        responseLat: 37.7749,
        responseLon: -122.4194,
        atlas: "NOAA",
        copyright: "test",
        heights: [
            TideHeight(dt: Date().timeIntervalSince1970 - 7200, height: 1.2),
            TideHeight(dt: Date().timeIntervalSince1970 - 3600, height: 1.5),
            TideHeight(dt: Date().timeIntervalSince1970, height: 1.8),
            TideHeight(dt: Date().timeIntervalSince1970 + 3600, height: 2.1),
            TideHeight(dt: Date().timeIntervalSince1970 + 7200, height: 1.9)
        ],
        extremes: [
            TideExtreme(dt: Date().timeIntervalSince1970, height: 1.8, type: "High"),
            TideExtreme(dt: Date().timeIntervalSince1970 + 6 * 3600, height: 0.5, type: "Low")
        ]
    ))
    .frame(height: 200)
    .padding()
} 