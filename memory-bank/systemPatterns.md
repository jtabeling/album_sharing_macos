# System Patterns

**Architecture:** MVVM (Model-View-ViewModel)

*   **Model:** Primarily represented by the `Photos` framework objects (`PHAssetCollection`, `PHAsset`, `PHPhotoLibrary`). Data fetching and modification logic resides within the `Photos` framework and is mediated by the `ViewModel`.
*   **View:** SwiftUI Views (`ContentView`) responsible for displaying data and forwarding user interactions to the `ViewModel`.
*   **ViewModel:** An `ObservableObject` class (`AlbumSharerViewModel`) that acts as the intermediary. It:
    *   Requests photo library authorization.
    *   Fetches albums from the `Photos` framework.
    *   Holds the state for the selected album, progress, and status messages.
    *   Contains the logic for creating the new album and copying assets.
    *   Exposes data and state to the `View` via `@Published` properties.

**Key Technical Decisions:**
*   Using SwiftUI for the UI for a modern macOS look and feel.
*   Using the standard `Photos` framework for library interaction.
*   Handling API limitations by focusing on reliable album duplication.
*   Employing MVVM to separate concerns (UI vs. Logic vs. Data).
*   Implementing batch processing for assets to provide smoother progress updates.
*   Using a task-specific approach to error handling with appropriate user feedback.

**Component Relationships:**
*   `ContentView` observes `AlbumSharerViewModel` for state changes.
*   `AlbumSharerViewModel` interacts with `PHPhotoLibrary` (shared instance).
*   `AlbumSharerViewModel` fetches `PHAssetCollection` (albums) and `PHAsset` (photos/videos).
*   `AlbumSharerViewModel` performs album changes within a `PHPhotoLibrary.shared().performChanges` block.
*   Asset copying is performed in batches within `performChangesAndWait` blocks for better progress reporting.

**Key Implementation Details:**
*   Albums fetching changed to use `.subtype = .any` for better compatibility.
*   Album creation and asset copying separated into distinct operations for better error handling.
*   Batch processing of assets (20 at a time) to provide smooth progress updates.
*   Clear validation checks for existing albums and empty source albums.
*   Async/background processing with main thread UI updates. 