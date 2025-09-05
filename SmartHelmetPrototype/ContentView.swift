import SwiftUI
import MapKit
import MediaPlayer
import Combine

// MARK: - IoT Helmet Manager (Mock Bluetooth/WiFi Connection)
class HelmetManager: ObservableObject {
    @Published var isConnected: Bool = false
    
    func connectToHelmet() {
        // Mock IoT Connection
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isConnected = true
        }
    }
}

// MARK: - Music Manager (Now Playing)
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
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 28.6139, longitude: 77.2090), // Example: New Delhi
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    var body: some View {
        VStack(spacing: 20) {
            
            // Helmet Status
            HStack {
                Circle()
                    .fill(helmetManager.isConnected ? Color.green : Color.red)
                    .frame(width: 16, height: 16)
                Text(helmetManager.isConnected ? "Helmet Connected" : "Connecting...")
                    .font(.headline)
            }
            .padding(.top, 10)
            
            // Google Maps / MapKit View
            Map(coordinateRegion: $region)
                .frame(height: 300)
                .cornerRadius(16)
                .shadow(radius: 5)
            
            // Now Playing Music
            VStack {
                Text("Now Playing")
                    .font(.headline)
                Text(musicManager.songTitle)
                    .font(.title2)
                    .bold()
                Text(musicManager.artistName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
            .shadow(radius: 4)
            
            Spacer()
            
            Button(action: {
                helmetManager.connectToHelmet()
            }) {
                Text("Connect to Helmet")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
