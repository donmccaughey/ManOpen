# ManOpen To Do

## Fix Compiler Warnings

### Fix warning `'defaultConnection' is deprecated: first deprecated in macOS 10.6`

- Extend `ManOpenURLHandlerCommand` to handle `manopen:` scheme
- When handling `manopen:` scheme, pass along `MANPATH` and `background` parameters
    for man page and apropos variants
- Validate that  `manopen:` scheme handles all  `MANSECT`s given in `man.conf` and section
    names in `openman.m`.
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
- In the `ManDocument` class, the `copyURL` instance variable will be mistakenly set to
    something like `x-man-doc://2/open(2)`
- When `MANPATH` is nil or not provided, apropos and man page searches should use the
    `MANPATH` stored in user defaults; currently only some code paths do this.
    
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
- Make sure that `ManOpen.app` can always find the `openman.1` man page.
