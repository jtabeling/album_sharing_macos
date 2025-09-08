import SwiftUI
import Photos // Needed for PHAssetCollection

struct ContentView: View {
    // Create and observe the ViewModel
    @StateObject private var viewModel = AlbumSharerViewModel()

    // State to keep track of the selected album
    @State private var selectedAlbumId: String? // Use album local identifier

    var body: some View {
        VStack(alignment: .leading) {
            Text("Select an Album:")
                .font(.headline)
                .padding(.bottom, 5)

            // List the albums
            if viewModel.authorizationStatus == .authorized || viewModel.authorizationStatus == .limited {
                if viewModel.albums.isEmpty {
                    Text("No albums found or still loading...")
                        .foregroundColor(.gray)
                } else {
                    List(viewModel.albums, id: \.localIdentifier, selection: $selectedAlbumId) {
                        album in
                        Text(album.localizedTitle ?? "Untitled Album")
                    }
                    .frame(minHeight: 150, maxHeight: 400) // Give the list some size
                }
            } else {
                Text("Photo Library Access Required. Please check permissions.")
                    .foregroundColor(.red)
                    .padding()
            }

            Spacer() // Pushes content to the top

            // Action Button and Progress
            HStack {
                Button("Create Shared Album Copy") {
                    // Find the selected album object
                    if let selectedId = selectedAlbumId,
                       let sourceAlbum = viewModel.albums.first(where: { $0.localIdentifier == selectedId }) {
                        // TODO: Call ViewModel function
                         viewModel.createAlbumCopy(sourceAlbum: sourceAlbum)
                        print("Button pressed for album: \(sourceAlbum.localizedTitle ?? "-")") // Placeholder
                    } else {
                        print("Button pressed but no album selected or found.") // Placeholder
                    }
                }
                // Disable button if no album is selected or if processing
                .disabled(selectedAlbumId == nil || viewModel.isProcessing) // isProcessing to be added to VM

                Spacer()
            }
            .padding(.top, 10)

            // Progress View - shown only during processing
             if viewModel.isProcessing { // isProcessing to be added to VM
                 ProgressView(value: viewModel.progress) // progress to be added to VM
                     .padding(.top, 5)
             } else {
                 // Keep layout consistent when progress bar not shown
                 Spacer().frame(height: 15) // Adjust height based on ProgressView size
             }

            // Status message area
            Text(viewModel.statusMessage)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 5)

        }
        .padding()
        .frame(minWidth: 300, minHeight: 300) // Set a minimum size for the window
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 