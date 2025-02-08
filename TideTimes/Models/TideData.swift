import Foundation

struct TideData: Codable {
    let status: Int
    let callCount: Int
    let requestLat: Double
    let requestLon: Double
    let responseLat: Double
    let responseLon: Double
    let atlas: String
    let copyright: String
    let heights: [TideHeight]
    let extremes: [TideExtreme]
}

struct TideHeight: Codable, Identifiable {
    let dt: TimeInterval
    let height: Double
    
    var id: TimeInterval { dt }
    var date: Date { Date(timeIntervalSince1970: dt) }
}

struct TideExtreme: Codable, Identifiable {
    let dt: TimeInterval
    let height: Double
    let type: String
    
    var id: TimeInterval { dt }
    var date: Date { Date(timeIntervalSince1970: dt) }
    var isHigh: Bool { type == "High" }
} 