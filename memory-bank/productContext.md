# Product Context

**Why:** Users often want to duplicate an album in their Photos library.

**Original Goal:** Build a tool to streamline the process of creating an iCloud Shared Album based on an existing local album.

**Adjusted Goal:** Build a tool to streamline the process of duplicating a Photos album by creating a new album and copying all content.

**Problem Solved:** This app automates the process of duplicating a Photos album by creating a new album with the same name as an existing one and copying all its contents. This saves time compared to manually creating a new album and adding photos one by one.

**How it Works (User Perspective):**
1.  Launch the app.
2.  Grant permission to access the Photos Library (if requested).
3.  See a list of existing photo albums.
4.  Select the desired album.
5.  Click "Create Shared Album Copy" button.
6.  See progress as the app creates a new album and copies photos/videos.
7.  Receive a confirmation message upon completion.

**User Experience Goals:**
*   **Simple:** Easy-to-understand interface with minimal steps.
*   **Efficient:** Saves time compared to manually recreating album content.
*   **Informative:** Provides clear status updates, progress indication, and error messages.
*   **Safe:** Avoids modifying existing albums; requires explicit user permission.

**Constraints Addressed:**
*   Worked within the limitations of the Photos framework API.
*   Focused on reliable core functionality rather than attempting to force unavailable sharing features.
*   Provides clear feedback on the state of the operation to the user. 