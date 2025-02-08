import Foundation

class TideService {
    private let baseURL = "https://api.tidesandcurrents.noaa.gov/api/prod/datagetter"
    
    func fetchTideData(latitude: Double, longitude: Double) async throws -> TideData {
        do {
            // First find the nearest station
            let station = try await findNearestStation(latitude: latitude, longitude: longitude)
            print("Found nearest station: \(station.name) (ID: \(station.id))")
            
            // Check cache first for this station
            if let cachedData = CacheService.getCachedTideData(forStationId: station.id) {
                print("Returning cached tide data for station \(station.id)")
                return cachedData
            }
            
            // If no cache, fetch new data
            let tideData = try await fetchDataFromStation(station)
            
            // Cache the successful response with the station ID
            CacheService.cacheTideData(tideData, forStationId: station.id)
            return tideData
            
        } catch {
            print("Error fetching tide data: \(error.localizedDescription)")
            
            // Return mock data as fallback
            print("Falling back to mock data")
            return createMockTideData(latitude: latitude, longitude: longitude)
        }
    }
    
    private func fetchDataFromStation(_ station: NOAAStation) async throws -> TideData {
        let now = Date()
        let calendar = Calendar.current
        let beginDate = calendar.date(byAdding: .hour, value: -12, to: now)!
        let endDate = calendar.date(byAdding: .hour, value: 12, to: now)!
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd HH:mm"
        
        // Build URL with proper parameters for water level predictions
        let urlString = "\(baseURL)?" +
            "begin_date=\(dateFormatter.string(from: beginDate))" +
            "&end_date=\(dateFormatter.string(from: endDate))" +
            "&station=\(station.id)" +
            "&product=predictions" +
            "&datum=MLLW" +
            "&time_zone=lst_ldt" +
            "&interval=30" + // Get data every 30 minutes for smoother graph
            "&units=metric" +
            "&application=TideTimes" +
            "&format=json"
        
        print("Fetching tide data from URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let noaaResponse = try JSONDecoder().decode(NOAAResponse.self, from: data)
        let tideData = try convertToTideData(noaaResponse, station: station)
        
        print("Received \(tideData.heights.count) tide readings for station \(station.id)")
        return tideData
    }
    
    private func createMockTideData(latitude: Double, longitude: Double) -> TideData {
        let now = Date()
        let calendar = Calendar.current
        
        // Create 24 hours of mock data
        var heights: [TideHeight] = []
        var extremes: [TideExtreme] = []
        
        // Generate more realistic mock data based on location
        let baseHeight = 1.5 // Average tide height
        let amplitude = 0.7 // Tide range
        let phaseShift = Double(calendar.component(.hour, from: now)) / 12.0 * .pi
        
        for hour in -12...12 {
            let time = calendar.date(byAdding: .hour, value: hour, to: now)!
            let timeInterval = time.timeIntervalSince1970
            
            // Create a sinusoidal wave pattern with location-based variation
            let progress = Double(hour) / 6.0 + phaseShift
            let height = baseHeight + amplitude * sin(progress * .pi)
            
            heights.append(TideHeight(dt: timeInterval, height: height))
            
            // Add extremes at peaks and troughs
            if hour % 6 == 0 {
                let isHigh = sin(progress * .pi) > 0
                extremes.append(TideExtreme(
                    dt: timeInterval,
                    height: isHigh ? baseHeight + amplitude : baseHeight - amplitude,
                    type: isHigh ? "High" : "Low"
                ))
            }
        }
        
        return TideData(
            status: 200,
            callCount: 1,
            requestLat: latitude,
            requestLon: longitude,
            responseLat: latitude,
            responseLon: longitude,
            atlas: "MOCK",
            copyright: "Mock Data (NOAA API Unavailable)",
            heights: heights,
            extremes: extremes
        )
    }
    
    private func findNearestStation(latitude: Double, longitude: Double) async throws -> NOAAStation {
        let urlString = "https://api.tidesandcurrents.noaa.gov/mdapi/prod/webapi/stations.json?type=tidepredictions"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let stationsResponse = try JSONDecoder().decode(NOAAStationsResponse.self, from: data)
        
        // Find nearest station with water level predictions
        let nearestStation = stationsResponse.stations
            .min(by: { station1, station2 in
                let distance1 = calculateDistance(lat1: latitude, lon1: longitude,
                                               lat2: station1.lat, lon2: station1.lng)
                let distance2 = calculateDistance(lat1: latitude, lon1: longitude,
                                               lat2: station2.lat, lon2: station2.lng)
                return distance1 < distance2
            })
        
        guard let station = nearestStation else {
            throw URLError(.cannotFindHost)
        }
        
        let distance = calculateDistance(lat1: latitude, lon1: longitude,
                                      lat2: station.lat, lon2: station.lng)
        print("Selected station \(station.name) at distance: \(Int(distance/1000))km")
        
        return station
    }
    
    private func calculateDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let R = 6371e3 // Earth's radius in meters
        let φ1 = lat1 * .pi / 180
        let φ2 = lat2 * .pi / 180
        let Δφ = (lat2 - lat1) * .pi / 180
        let Δλ = (lon2 - lon1) * .pi / 180
        
        let a = sin(Δφ/2) * sin(Δφ/2) +
                cos(φ1) * cos(φ2) *
                sin(Δλ/2) * sin(Δλ/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        
        return R * c
    }
    
    private func convertToTideData(_ noaaResponse: NOAAResponse, station: NOAAStation) throws -> TideData {
        let predictions = noaaResponse.predictions.sorted { $0.t < $1.t }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        let heights: [TideHeight] = try predictions.map { prediction in
            guard let date = dateFormatter.date(from: prediction.t) else {
                throw URLError(.cannotParseResponse)
            }
            return TideHeight(
                dt: date.timeIntervalSince1970,
                height: Double(prediction.v) ?? 0.0
            )
        }
        
        // Find extremes (local maxima and minima)
        var extremes: [TideExtreme] = []
        for i in 1..<heights.count-1 {
            let prev = heights[i-1].height
            let curr = heights[i].height
            let next = heights[i+1].height
            
            if (curr > prev && curr > next) {
                extremes.append(TideExtreme(
                    dt: heights[i].dt,
                    height: curr,
                    type: "High"
                ))
            } else if (curr < prev && curr < next) {
                extremes.append(TideExtreme(
                    dt: heights[i].dt,
                    height: curr,
                    type: "Low"
                ))
            }
        }
        
        return TideData(
            status: 200,
            callCount: 1,
            requestLat: station.lat,
            requestLon: station.lng,
            responseLat: station.lat,
            responseLon: station.lng,
            atlas: "NOAA",
            copyright: "NOAA CO-OPS API",
            heights: heights,
            extremes: extremes
        )
    }
}

// NOAA API Response Models
struct NOAAResponse: Codable {
    let predictions: [NOAAPrediction]
}

struct NOAAPrediction: Codable {
    let t: String  // time
    let v: String  // value
}

struct NOAAStationsResponse: Codable {
    let stations: [NOAAStation]
}

struct NOAAStation: Codable {
    let id: String
    let name: String
    let lat: Double
    let lng: Double
    let expansionProducts: [String]
} 