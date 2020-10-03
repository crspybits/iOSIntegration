# Test procedures
## Upload four image files to server, in background, disconnected from Xcode debugger, with app terminated.

1. Remove the app from iPhone device (to reset the file log).
2. Install app to iPhone device (not simulator).
3. Disconnect from Xcode debugger, and launch again.
4. Sign into owning account.
5. Go to Files menu item
6. In succession, tap Sync, Sharing Groups, Get first sharing group.
7. Tap on "Upload multiple large files with fail." Uploads will be triggered, and app will (intentionally) crash.
8. Wait for uploads to complete. E.g., watch the server logs.
9. Start app again and go to the Logs menu. 
10. Refresh and look at the bottom-- make sure that the logs indicate success. E.g., you should see "v0UploadsFinished" and success messages.

# TODO:

## UI

### Dark mode and sign-in

#### In dark mode, the individual sign-in buttons are not setup with color correctly.

### Tappable area for hamburger menu button is too small

## Using shared storage for sharing app extension

## What backgroundURLSession identifier gets used in a sharing app extension?
