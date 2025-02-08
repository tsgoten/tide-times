import Foundation

struct CacheService {
    private static let cacheExpirationKey = "tide_data_expiration"
    private static let cacheDuration: TimeInterval = 3600 // 1 hour
    
    static func cacheTideData(_ tideData: TideData, forStationId stationId: String) {
        if let encoded = try? JSONEncoder().encode(tideData) {
            UserDefaults.standard.set(encoded, forKey: "tide_data_\(stationId)")
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "\(cacheExpirationKey)_\(stationId)")
        }
    }
    
    static func getCachedTideData(forStationId stationId: String) -> TideData? {
        guard let data = UserDefaults.standard.data(forKey: "tide_data_\(stationId)"),
              let expirationTime = UserDefaults.standard.object(forKey: "\(cacheExpirationKey)_\(stationId)") as? TimeInterval else {
            return nil
        }
        
        // Check if cache is still valid
        let now = Date().timeIntervalSince1970
        if now - expirationTime > cacheDuration {
            return nil
        }
        
        return try? JSONDecoder().decode(TideData.self, from: data)
    }
} 