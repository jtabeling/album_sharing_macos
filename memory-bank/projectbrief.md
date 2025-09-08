# Project Brief

**Project Name:** AlbumSharer

**Original Goal:** Create a macOS SwiftUI application that helps users prepare an existing local Photos album for sharing via iCloud Shared Albums.

**Adjusted Goal:** Create a macOS SwiftUI application that duplicates a local Photos album, copying all its contents to a new album.

**Core Requirements - Final Implementation:**
1.  Request and handle user permission for Photo Library access.
2.  List all albums from the Photos Library.
3.  Allow the user to select one album.
4.  Upon user action (button click):
    *   Check if an album with the same name already exists. If a shared album exists, stop and notify the user.
    *   Create a new regular album with the same name as the selected album.
    *   Copy all photos and videos from the selected album into the newly created album.
    *   Provide visual progress indication during the copy process.
5.  Display clear status messages and handle errors gracefully (verbose logging).

**Key Constraints:**
*   Cannot create iCloud Shared Albums directly due to API limitations.
*   Sharing functionality varies across macOS versions and cannot be reliably accessed programmatically.
*   The app focuses on reliable album duplication functionality, leaving any sharing to be done manually by the user if their system supports it.

**Target Platform:** macOS
**Primary Technology:** Swift, SwiftUI, Photos Framework 