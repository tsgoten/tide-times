import Foundation

struct RecentSearchService {
    private static let recentSearchesKey = "recent_searches"
    private static let maxRecentSearches = 5
    
    static func getRecentSearches() -> [Location] {
        guard let data = UserDefaults.standard.data(forKey: recentSearchesKey),
              let locations = try? JSONDecoder().decode([Location].self, from: data) else {
            return []
        }
        return locations
    }
    
    static func addRecentSearch(_ location: Location) {
        var recentSearches = getRecentSearches()
        
        // Remove if already exists
        recentSearches.removeAll { $0.id == location.id }
        
        // Add to beginning
        recentSearches.insert(location, at: 0)
        
        // Keep only the most recent searches
        if recentSearches.count > maxRecentSearches {
            recentSearches = Array(recentSearches.prefix(maxRecentSearches))
        }
        
        // Save updated list
        if let encoded = try? JSONEncoder().encode(recentSearches) {
            UserDefaults.standard.set(encoded, forKey: recentSearchesKey)
        }
    }
} 