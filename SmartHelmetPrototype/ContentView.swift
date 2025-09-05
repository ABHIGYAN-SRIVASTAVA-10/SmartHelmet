import SwiftUI
import MapKit
import MediaPlayer
import Combine
import CoreLocation

// MARK: - Identifiable wrapper for destination
struct Destination: Identifiable {
    let id = UUID()
    let mapItem: MKMapItem
}

// MARK: - Location Manager
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    @Published var userLocation: CLLocation? = nil
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.last
    }
}

// MARK: - IoT Helmet Manager
class HelmetManager: ObservableObject {
    @Published var isConnected: Bool = false
    
    func toggleConnection() {
        isConnected.toggle()
    }
}

// MARK: - Music Manager
class MusicManager: ObservableObject {
    @Published var songTitle: String = "Unknown Song"
    @Published var artistName: String = "Unknown Artist"
    
    private var player = MPMusicPlayerController.systemMusicPlayer
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        NotificationCenter.default.publisher(for: .MPMusicPlayerControllerNowPlayingItemDidChange)
            .sink { [weak self] _ in
                self?.updateNowPlaying()
            }
            .store(in: &cancellables)
        
        player.beginGeneratingPlaybackNotifications()
        updateNowPlaying()
    }
    
    func updateNowPlaying() {
        if let item = player.nowPlayingItem {
            songTitle = item.title ?? "Unknown Song"
            artistName = item.artist ?? "Unknown Artist"
        }
    }
}

// MARK: - Main View
struct ContentView: View {
    @StateObject private var helmetManager = HelmetManager()
    @StateObject private var musicManager = MusicManager()
    @StateObject private var locationManager = LocationManager()
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 28.6139, longitude: 77.2090),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    @State private var searchQuery = ""
    @State private var destination: Destination? = nil
    @State private var distanceText: String? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            
            // Helmet Status
            HStack {
                Circle()
                    .fill(helmetManager.isConnected ? Color.green : Color.red)
                    .frame(width: 16, height: 16)
                Text(helmetManager.isConnected ? "Helmet Connected" : "Helmet Disconnected")
                    .font(.headline)
            }
            .padding(.top, 10)
            
            // Search Bar
            HStack {
                TextField("Search destination...", text: $searchQuery, onCommit: searchLocation)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: searchLocation) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            // Map with Destination Pin
            Map(coordinateRegion: $region,
                annotationItems: destination == nil ? [] : [destination!]) { place in
                MapMarker(coordinate: place.mapItem.placemark.coordinate, tint: .red)
            }
            .frame(height: 300)
            .cornerRadius(16)
            .shadow(radius: 5)
            
            // Distance Info
            if let distanceText = distanceText {
                Text("Distance: \(distanceText)")
                    .font(.headline)
                    .foregroundColor(.blue)
            }
            
            // Large Toggle Button
            Button(action: {
                helmetManager.toggleConnection()
            }) {
                Text(helmetManager.isConnected ? "Disconnect Helmet" : "Connect to Helmet")
                    .font(.title2)
                    .bold()
                    .padding()
                    .frame(maxWidth: .infinity, minHeight: 80)
                    .background(helmetManager.isConnected ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(16)
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Mini Player at Bottom
            HStack {
                Image(systemName: "music.note")
                    .font(.title2)
                    .padding(.trailing, 8)
                
                VStack(alignment: .leading) {
                    Text(musicManager.songTitle)
                        .font(.subheadline)
                        .bold()
                        .lineLimit(1)
                    Text(musicManager.artistName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Button(action: {
                    let player = MPMusicPlayerController.systemMusicPlayer
                    if player.playbackState == .playing {
                        player.pause()
                    } else {
                        player.play()
                    }
                }) {
                    Image(systemName: MPMusicPlayerController.systemMusicPlayer.playbackState == .playing ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
            .shadow(radius: 4)
        }
        .padding()
    }
    
    // MARK: - Search Function
    private func searchLocation() {
        guard !searchQuery.isEmpty else { return }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchQuery
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response, let mapItem = response.mapItems.first else { return }
            let newDestination = Destination(mapItem: mapItem)
            destination = newDestination
            region.center = mapItem.placemark.coordinate
            
            // Calculate distance if user location is available
            if let userLoc = locationManager.userLocation {
                let destLoc = CLLocation(latitude: mapItem.placemark.coordinate.latitude,
                                         longitude: mapItem.placemark.coordinate.longitude)
                let distanceMeters = userLoc.distance(from: destLoc)
                
                if distanceMeters > 1000 {
                    let km = distanceMeters / 1000
                    distanceText = String(format: "%.2f km", km)
                } else {
                    distanceText = String(format: "%.0f m", distanceMeters)
                }
            }
        }
    }
}
