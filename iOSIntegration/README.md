# Test procedures

## SharedContainer in iOSShared

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

## Sharing app extension

See https://dmtopolog.com/ios-app-extensions-data-sharing/

### Need to use the sign-in that is current for the host app

### Using shared storage

Every access to files needs to use something like:

extension FileManager {
  static func sharedContainerURL() -> URL {
    return FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: "group.com.your.domain"
    )!
  }
}

But what is this? Is it analogous to the Documents directory for an app?
Note: Access to this is not thread safe. I think a main issue is access to this across the app extension and the host app.

Places that use FileManager and/or files?
    iOSShared [DONE]
    iOSIntegration  [DONE]
    iOSBasics  [DONE]
        Configuration within this  [DONE]
    iOSDropbox
    iOSFacebook
    PersistentValue  [DONE]

How to access for a SQLite database?

### What backgroundURLSession identifier gets used in a sharing app extension?

