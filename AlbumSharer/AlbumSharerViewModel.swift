import SwiftUI
import Photos
import os // For logging

// Define a custom logger
let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "ViewModel")

class AlbumSharerViewModel: ObservableObject {
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @Published var albums: [PHAssetCollection] = []
    @Published var statusMessage: String = "App Started. Requesting permissions..."
    @Published var isProcessing: Bool = false
    @Published var progress: Double = 0.0

    init() {
        logger.info("ViewModel initialized.")
        requestAuthorization()
    }

    func requestAuthorization() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            DispatchQueue.main.async {
                self?.authorizationStatus = status
                logger.info("Photo Library authorization status: \(status.rawValue)")
                switch status {
                case .authorized, .limited:
                    self?.statusMessage = "Access granted. Fetching albums..."
                    logger.info("Access granted, proceeding to fetch albums.")
                    self?.fetchAlbums()
                case .denied, .restricted:
                    self?.statusMessage = "Photo Library access denied or restricted. Please enable in System Settings."
                    logger.warning("Photo Library access denied or restricted.")
                case .notDetermined:
                    // Should not happen after request, but handle defensively
                    self?.statusMessage = "Waiting for Photo Library permission..."
                    logger.info("Permission status not determined.")
                @unknown default:
                    self?.statusMessage = "Unknown Photo Library authorization status."
                    logger.error("Unknown Photo Library authorization status: \(status.rawValue)")
                }
            }
        }
    }

    func fetchAlbums() {
        logger.info("Attempting to fetch albums.")
        guard PHPhotoLibrary.authorizationStatus(for: .readWrite) == .authorized || PHPhotoLibrary.authorizationStatus(for: .readWrite) == .limited else {
            logger.warning("Cannot fetch albums, authorization not granted.")
            DispatchQueue.main.async {
                self.statusMessage = "Cannot fetch albums: Authorization not granted."
            }
            return
        }

        var fetchedAlbums: [PHAssetCollection] = []

        // Fetch user-created albums (excluding smart albums)
        let userAlbumsOptions = PHFetchOptions()
        // Optionally add sorting if needed, e.g., by title
        // userAlbumsOptions.sortDescriptors = [NSSortDescriptor(key: "localizedTitle", ascending: true)]
        let userAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: userAlbumsOptions)

        userAlbums.enumerateObjects { (collection, _, _) in
            // We double-check it's not a shared album subtype, although .albumRegular should exclude them.
            // Also exclude specific known smart album subtypes if necessary, though .albumRegular aims to handle this.
             if collection.assetCollectionSubtype != .albumCloudShared {
                 fetchedAlbums.append(collection)
                 logger.debug("Fetched album: \\(collection.localizedTitle ?? "Untitled")")
             } else {
                 logger.debug("Skipping shared album: \\(collection.localizedTitle ?? "Untitled")")
             }
        }

        DispatchQueue.main.async {
            self.albums = fetchedAlbums
            if fetchedAlbums.isEmpty {
                self.statusMessage = "No user albums found."
                logger.info("Finished fetching albums. No user albums found.")
            } else {
                self.statusMessage = "Albums loaded. Please select an album."
                logger.info("Finished fetching albums. Found \\(fetchedAlbums.count) albums.")
            }
        }
    }

    // --- Album Creation and Copying --- 

    func createAlbumCopy(sourceAlbum: PHAssetCollection) {
        guard !isProcessing else {
            logger.warning("createAlbumCopy called while already processing.")
            return
        }
        
        guard let sourceAlbumTitle = sourceAlbum.localizedTitle else {
            logger.error("Source album title is nil. Cannot proceed.")
            DispatchQueue.main.async {
                self.statusMessage = "Error: Selected album has no title."
            }
            return
        }

        logger.info("Starting album copy process for: \(sourceAlbumTitle)")
        DispatchQueue.main.async {
            self.isProcessing = true
            self.progress = 0.0
            self.statusMessage = "Starting copy for album: \(sourceAlbumTitle)..."
        }

        // Run checks and Photos operations on a background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            // --- 1. Check if an iCloud Shared Album with the target name already exists --- 
            let sharedAlbumOptions = PHFetchOptions()
            sharedAlbumOptions.predicate = NSPredicate(format: "localizedTitle = %@", sourceAlbumTitle)
            let sharedAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumCloudShared, options: sharedAlbumOptions)

            if sharedAlbums.firstObject != nil {
                logger.warning("An iCloud Shared Album named '\(sourceAlbumTitle)' already exists. Aborting.")
                DispatchQueue.main.async {
                    self.statusMessage = "Error: An iCloud Shared Album named '\(sourceAlbumTitle)' already exists."
                    self.isProcessing = false
                }
                return // Stop processing
            }

            logger.info("No existing iCloud Shared Album found with name '\(sourceAlbumTitle)'. Proceeding...")

            // --- 2. Fetch assets from sourceAlbum --- 
            let fetchOptions = PHFetchOptions()
            // Include all asset types (images, videos)
            // fetchOptions.predicate = NSPredicate(format: "mediaType = %d || mediaType = %d", PHAssetMediaType.image.rawValue, PHAssetMediaType.video.rawValue)
            // fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)] // Optional sort
            let assets = PHAsset.fetchAssets(in: sourceAlbum, options: fetchOptions)

            guard assets.count > 0 else {
                logger.warning("Source album '\(sourceAlbumTitle)' contains no assets. Aborting.")
                DispatchQueue.main.async {
                    self.statusMessage = "Error: Source album '\(sourceAlbumTitle)' is empty."
                    self.isProcessing = false
                }
                return // Stop processing
            }

            logger.info("Found \(assets.count) assets in source album '\(sourceAlbumTitle)'.")
            DispatchQueue.main.async {
                 self.statusMessage = "Found \(assets.count) assets. Preparing to copy..."
            }
            
            // --- 3 & 4. Create new album and copy assets --- 
            var newAlbumPlaceholder: PHObjectPlaceholder? = nil
            var copyError: Error? = nil
            let totalAssets = assets.count
            var copiedCount = 0
            
            do {
                try PHPhotoLibrary.shared().performChangesAndWait {
                    // 3. Create the new regular album
                    let createAlbumRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: sourceAlbumTitle)
                    newAlbumPlaceholder = createAlbumRequest.placeholderForCreatedAssetCollection
                    guard let newAlbumPlaceholder = newAlbumPlaceholder else {
                        logger.error("Failed to get placeholder for new album.")
                        // Error handling needs to be improved here, maybe throw?
                        // For now, rely on the outer catch block if performChanges throws.
                        return
                    }

                    // Retrieve the newly created album to add assets to it
                    guard let newAlbum = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [newAlbumPlaceholder.localIdentifier], options: nil).firstObject else {
                        logger.error("Failed to fetch newly created album.")
                        // Error handling needs to be improved here.
                        return
                    }
                    
                    // 4. Create change request for the new album & copy assets
                    guard let albumChangeRequest = PHAssetCollectionChangeRequest(for: newAlbum) else {
                         logger.error("Failed to get change request for new album.")
                         // Error handling needs to be improved here.
                         return
                    }
                    
                    // Convert PHFetchResult to an array for easier enumeration with index
                    var assetsToCopy: [PHAsset] = []
                    assets.enumerateObjects { (asset, _, _) in
                        assetsToCopy.append(asset)
                    }
                    
                    logger.info("Starting asset copy loop...")
                    albumChangeRequest.addAssets(assetsToCopy as NSFastEnumeration)
                    
                    // Note: Progress tracking within performChanges is difficult.
                    // We will update progress more granularly *after* this block if needed,
                    // or simply update it once here. For now, we assume success if no throw.
                    copiedCount = totalAssets // Assume all copied if no error
                }
                
                // If performChangesAndWait completes without throwing, proceed
                logger.info("Successfully created album '\(sourceAlbumTitle)' and requested asset copy.")
                DispatchQueue.main.async {
                    // Update progress to 100% on successful completion of the block
                    self.progress = 1.0
                    // --- Final Success Message & Instructions --- 
                    self.statusMessage = "Success! Album '\(sourceAlbumTitle)' created with \(totalAssets) items. \nNext Steps: Open Photos, find '\(sourceAlbumTitle)', right-click it, and choose 'Share Album' to create the iCloud Shared Album."
                    logger.info("Process completed successfully. Instructing user on manual sharing.")
                    // --- End Final Instructions --- 
                    self.isProcessing = false // Mark as done
                }
                
            } catch let error {
                logger.error("Error during album creation or asset copy: \(error.localizedDescription)")
                copyError = error // Store error to report
                DispatchQueue.main.async {
                    self.statusMessage = "Error creating album or copying assets: \(error.localizedDescription)"
                    self.isProcessing = false
                }
            }
            
            // TODO: 
            // 5. Handle errors and update status/isProcessing (partially done with catch block).
            //    Add final success message/instructions (Phase 5).

            // --- Remove Placeholder Completion --- 
            /* 
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { // Simulate work
                logger.info("Placeholder: Album copy finished (simulated). Actual implementation needed.")
                self.isProcessing = false
                self.statusMessage = "Placeholder: Finished copy for \(sourceAlbumTitle)."
            }
             */
        }
    }

} 