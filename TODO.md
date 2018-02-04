# ManOpen To Do

## Fix Compiler Warnings

### Fix warning `'defaultConnection' is deprecated: first deprecated in macOS 10.6`

- Extend `ManOpenURLHandlerCommand` to handle `manopen:` scheme
- In `openman`, replace use of `NSConnection` and `NSDistantObject` with LaunchServices
    `LSOpenFromURLSpec()` calls using `manopen:` URLs; see
    https://developer.apple.com/documentation/coreservices/launch_services?language=objc
- Remove  `oneway` keyword from `ManDocumentController` method return types
- Remove `ManOpen` protocol
- Remove `NSConnection` set up from `ManDocumentController -init` method

## Fix Bugs

- The _Edit_ | _Copy URL_ command produces clipboard text like `<x-man-doc://grep>`,
    but this should be `x-man-page:///grep`
- The _Edit_ | _Find_ | _Find..._ command shows a Find dialog with Replace field and actions,
    show a Find only dialog instead

## Modernize Code

- Convert `ManOpen.scriptSuite` and `ManOpen.scriptTerminology` to `sdef` format,
    see https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/ScriptableCocoaApplications/SApps_creating_sdef/SAppsCreateSdef.html
    and https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/ScriptableCocoaApplications/SApps_suites/SAppsSuites.html
- Update `Services` array in `Info-ManOpen.plist`
    1. Remove `ManOpen/` prefix from menu item titles
    1. Add `NSServiceDescription` keys
    1. Add `NSRequiredContext` keys
- Convert `openman` to ARC
- Convert `ManOpen` app to ARC
- Convert `ManOpenTests` to ARC

## New Features

- Automatically locate Xcode and search it for man pages
- Distribute `openman` in app bundle and add command to install it
