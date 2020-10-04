# How to get your app going

## Enable keychain sharing

Some of the sign-ins (e.g., Dropbox) store their creds in the keychain.
See https://www.albertomoral.com/blog/share-keychain-between-app-and-extension
and https://developer.apple.com/documentation/security/keychain_services/keychain_items/sharing_access_to_keychain_items_among_a_collection_of_apps

An access group needs to be enabled in both the app and the share extension. I think the same name needs to be used in both too.

## Enable an app group -- a shared container for the sharing extension

This needs to be enabled in both the app and the share extension.

# Test procedures

## Test file upload in sharing extension

## Sharing invitation

Sharing link
a) user not signed in
b) user already signed in

Sharing code from UI
a) user not signed in
b) user already signed in

## SharedContainer in iOSShared

All access now to files should be through the shared container.

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

Getting this warning:
warning: Embedded binary's NSExtensionActivationRule is TRUEPREDICATE. Before you submit your containing app to the App Store, be sure to replace all uses of TRUEPREDICATE with specific predicate statements or NSExtensionActivationRule keys. If any extensions in your containing app include TRUEPREDICATE, the app will be rejected.

### As I think Rod mentioned, will need a means for the user to select the album that they want to use to upload a file.

### Am I using the keychain at all, currently?

### What to do if the user is not signed in already?

That is, if the user is not signed in to the host app? It seems like there ought to be a sign-in experience in the sharing extension. Hmmm. One issue here is that this sign-in UI is currently in SwiftUI. I'm not sure I can use SwiftUI in a sharing extension.

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
    iOSDropbox  [DONE]
    iOSFacebook
    PersistentValue  [DONE]

How to access for a SQLite database?

### What backgroundURLSession identifier gets used in a sharing app extension?

