# Tech Context

**Platform:** macOS
**Language:** Swift
**UI Framework:** SwiftUI
**Core Frameworks:**
*   `Photos`: For interacting with the user's Photo Library (fetching albums, assets, creating albums, modifying content).
*   `SwiftUI`: For building the user interface.
*   `Foundation`: For basic data types and error handling.
*   `os`: For structured logging (Logger).

**Development Setup:**
*   Xcode IDE
*   Standard Swift Package Manager for any future dependencies (none currently required).
*   **Git version control** - Repository hosted at https://github.com/jtabeling/album_sharing_macos.

**Technical Constraints:**
*   Requires macOS version supporting the Photos framework APIs (typically macOS 10.13+).
*   **Cannot create iCloud Shared Albums** directly through the Photos framework API.
*   **Sharing functionality varies** across macOS versions and user setups, making it unreliable to provide universal sharing instructions.
*   Requires explicit user permission to access the Photos Library.
*   Performance considerations for copying large numbers of assets mitigated through batch processing.

**Dependencies:** None outside of standard Apple frameworks.

**Critical Files:**
*   `Info.plist`: Contains necessary privacy descriptions for Photos access.
*   `AlbumSharerViewModel.swift`: Central business logic and Photos framework interaction.
*   `ContentView.swift`: Main UI implementation with album selection, progress indication, and status display.
*   `AlbumSharingApp.swift`: App entry point.

**Configuration:**
*   Minimum target macOS version should be set according to the version that supports required Photos APIs (typically 10.13+).

**Repository Information:**
*   **GitHub URL:** https://github.com/jtabeling/album_sharing_macos
*   **Main branch:** main
*   **Initial commit:** Complete AlbumSharer macOS app with memory bank documentation
*   **Build status:** ✅ Successfully builds and runs on macOS 