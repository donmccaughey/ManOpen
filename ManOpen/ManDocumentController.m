
#import "ManDocumentController.h"
#import <AppKit/AppKit.h>
#import "ManDocument.h"
#import "ManPage.h"
#import "AproposDocument.h"
#import "NSData+Utils.h"
#import "NSString+ManOpen.h"
#import "NSUserDefaults+ManOpen.h"
#import "PrefPanelController.h"


@implementation ManDocumentController

- init
{
    self = [super init];
    if (self) {
        [PrefPanelController registerManDefaults];
        [[NSBundle mainBundle] loadNibNamed:@"DocController"
                                      owner:self
                            topLevelObjects:&docControllerObjects];
        [docControllerObjects retain];
    }
    return self;
}

- (void)dealloc
{
    [docControllerObjects release];
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [NSApp setServicesProvider:self];

    /* Remember window positions, in case they're non-modal */
    [openTextPanel setFrameUsingName:@"OpenTitlePanel"];
    [openTextPanel setFrameAutosaveName:@"OpenTitlePanel"];
    [aproposPanel setFrameUsingName:@"AproposPanel"];
    [aproposPanel setFrameAutosaveName:@"AproposPanel"];

    [self setupStatusItem];
    
    startedUp = YES;
}

/*
 * By default, NSApplication will want to open an untitled document at
 * startup and when no windows are open. Check our preferences.
 */
- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
    if (startedUp)
        return [[NSUserDefaults standardUserDefaults] boolForKey:@"OpenPanelWhenNoWindows"];
    else
        return [[NSUserDefaults standardUserDefaults] boolForKey:@"OpenPanelOnStartup"];
}
- (BOOL)applicationOpenUntitledFile:(NSApplication *)sender
{
    if ([self applicationShouldOpenUntitledFile:sender]) {
        if (![openTextPanel isVisible])
            [openSectionPopup selectItemAtIndex:0];
        [openTextField selectText:self];
        [openTextPanel performSelector:@selector(makeKeyAndOrderFront:) withObject:self afterDelay:0.0];
        return YES;
    }
    return NO;
}

- (void) setupStatusItem {
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    statusItem.image = [NSImage imageNamed:@"ManOpen"];
    statusItem.image.size = NSMakeSize(20.0, 20.0);
    statusItem.button.action = @selector(openTextPanel:);
    [statusItem retain];
}

- (void)removeDocument:(NSDocument *)document
{
    BOOL autoQuit = [[NSUserDefaults standardUserDefaults] boolForKey:@"QuitWhenLastClosed"];

    [super removeDocument:document];

    if ([[self documents] count] == 0 && autoQuit)
    {
        [[NSApplication sharedApplication] performSelector:@selector(terminate:)
                                                withObject:self afterDelay:0.0];
    }
}

- (NSMutableString *)manCommandWithManPath:(NSString *)manPath
{
    NSMutableString *command = [[@"/usr/bin/man" mutableCopy] autorelease];
    if (manPath.length) {
        [command appendFormat:@" -M %@", manPath.singleQuotedShellWord];
    }
    return command;
}

- (NSData *)dataByExecutingCommand:(NSString *)command maxLength:(NSUInteger)maxLength environment:(NSDictionary*)extraEnv
{
    NSPipe *pipe = [[NSPipe alloc] init];
    NSTask *task = [[NSTask alloc] init];
    NSData *output;
    
    if (extraEnv != nil) {
        NSMutableDictionary *environment = [[[NSProcessInfo processInfo] environment] mutableCopy];
        [environment addEntriesFromDictionary:extraEnv];
        [task setEnvironment:environment];
        [environment release];
    }

    [task setLaunchPath:@"/bin/sh"];
    [task setArguments:[NSArray arrayWithObjects:@"-c", command, nil]];
    [task setStandardOutput:pipe];
    [task setStandardError:[NSFileHandle fileHandleWithNullDevice]]; //don't care about output
    [task launch];

    if (maxLength > 0) {
        output = [[pipe fileHandleForReading] readDataOfLength:maxLength];
        [task terminate];
    }
    else {
        output = [[pipe fileHandleForReading] readDataToEndOfFileIgnoreInterrupt];
    }
    [task waitUntilExit];
    [pipe release];
    [task release];

    return output;
}

- (NSData *)dataByExecutingCommand:(NSString *)command maxLength:(NSUInteger)maxLength
{
    return [self dataByExecutingCommand:command maxLength:maxLength environment:nil];
}

- (NSData *)dataByExecutingCommand:(NSString *)command
{
    return [self dataByExecutingCommand:command maxLength:0];
}

- (NSData *)dataByExecutingCommand:(NSString *)command manPath:(NSString *)manPath
{
    NSDictionary *extraEnv = nil;
    
    if (manPath != nil) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setObject:manPath forKey:@"MANPATH"];
        extraEnv = dict;
    }
    return [self dataByExecutingCommand:command maxLength:0 environment:extraEnv];
}

- (NSString *)manFileForName:(NSString *)name section:(NSString *)section manPath:(NSString *)manPath
{
    NSMutableString *command;
    NSData *data;

    command = [self manCommandWithManPath:manPath];
    [command appendFormat:@" -w %@ %@", section? section:@"", name];

    data = [self dataByExecutingCommand:command];
    if (data != nil)
    {
        NSFileManager *manager = [NSFileManager defaultManager];
        NSString *filename;
        NSUInteger len = [data length];
        const char *ptr = [data bytes];
        const char *newlinePtr = memchr(ptr, '\n', len);

        if (newlinePtr != NULL)
            len = newlinePtr - ptr;

        filename = [manager stringWithFileSystemRepresentation:ptr length:len];
        if (filename != nil && [manager fileExistsAtPath:filename])
            return filename;
    }

    return nil;
}

- (NSString *)typeFromFilename:(NSString *)filename
{
    NSFileHandle  *handle;
    NSFileManager *manager = [NSFileManager defaultManager];
    NSDictionary  *attributes = [manager attributesOfItemAtPath:filename error:nil];
    NSUInteger    maxLength = MIN(150, (NSUInteger)[attributes fileSize]);
    NSData        *fileHeader;
    NSString      *catType = @"cat";
    NSString      *manType = @"man";

    if (maxLength == 0) return catType;

    handle = [NSFileHandle fileHandleForReadingAtPath:filename];
    fileHeader = [handle readDataOfLength:maxLength];

    if ([attributes fileSize] > 1000000) return nil;

    if ([fileHeader isGzipData]) {
        NSString *command = [NSString stringWithFormat:@"/usr/bin/gzip -dc '%@'", [filename singleQuotedShellWordWithSurroundingQuotes:NO]];
        fileHeader = [self dataByExecutingCommand:command maxLength:maxLength];
        manType = @"mangz";
        catType = @"catgz";
    }

    if ([fileHeader isBinaryData]) return nil;

    return [fileHeader isNroffData]? manType : catType;
}

/* Ignore the types; man/cat files can have any range of extensions. */
- (NSInteger)runModalOpenPanel:(NSOpenPanel *)openPanel forTypes:(NSArray *)openableFileExtensions
{
    return [openPanel runModal];
}

- (id)documentForTitle:(NSString *)title
{
    NSArray *documents = [self documents];
    NSUInteger i, count = [documents count];

    for (i=0; i<count; i++)
    {
        NSDocument *document = [documents objectAtIndex:i];
        if ([document isKindOfClass:[ManDocument class]] &&
            [document fileURL] == nil &&
            [[(ManDocument *)document shortTitle] isEqualToString:title])
        {
            return document;
        }
        if ([document isKindOfClass:[AproposDocument class]] &&
            [[document displayName] isEqualToString:title])
        {
            return document;
        }
    }

    return nil;
}

/*" A parallel for openDocumentWithContentsOfFile: for a specific man page "*/
- (id)openDocumentWithName:(NSString *)name
        section:(NSString *)section
        manPath:(NSString *)manPath
{
    ManDocument *document;
    NSString    *title = name;

    if (section && [section length] > 0)
    {
        title = [NSString stringWithFormat:@"%@(%@)",name, section];
    }

    if ((document = [self documentForTitle:title]) == nil)
    {
        NSString *filename;

        document = [[[ManDocument alloc]
                        initWithName:name section:section
                        manPath:manPath title:title] autorelease];
        [self addDocument:document];
        [document makeWindowControllers];

        /* Add the filename to the recent menu */
        filename = [self manFileForName:name section:section manPath:manPath];
        if (filename != nil)
            [self noteNewRecentDocumentURL:[NSURL fileURLWithPath:filename]];
    }

    [document showWindows];

    return document;
}

- (id)openAproposDocument:(NSString *)apropos manPath:(NSString *)manPath
{
    AproposDocument *document;
    NSString *title = [NSString stringWithFormat:@"Apropos %@", apropos];

    if ((document = [self documentForTitle:title]) == nil)
    {
        document = [[[AproposDocument alloc]
                        initWithString:apropos manPath:manPath title:title] autorelease];
        if (document) [self addDocument:document];
        [document makeWindowControllers];
    }

    [document showWindows];

    return document;
}

/*"
 * Parses word for stuff like "file(3)" to break out the section, then
 * calls openDocumentWithName:section:manPath: as appropriate.
"*/
- (id)openWord:(NSString *)word
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *section = nil;
    NSString *base    = word;
    NSRange lparenRange = [word rangeOfString:@"("];
    NSRange rparenRange = [word rangeOfString:@")"];
    id document;

    if (lparenRange.length != 0 && rparenRange.length != 0 &&
        lparenRange.location < rparenRange.location)
    {
        NSRange sectionRange;

        sectionRange.location = NSMaxRange(lparenRange);
        sectionRange.length = rparenRange.location - sectionRange.location;

        base = [word substringToIndex:lparenRange.location];
        section = [word substringWithRange:sectionRange];
    }

    document = [self openDocumentWithName:base section:section manPath:[[NSUserDefaults standardUserDefaults] manPath]];
    [pool release];
    return document;
}

- (void)openString:(NSString *)string
{
    NSArray<NSString *> *words = string.wordsSeparatedByWhitespaceAndNewlineCharacters;
    
    if ([words count] > 20) {
        NSAlert *alert = [[NSAlert new] autorelease];
        alert.messageText = @"Warning";
        alert.informativeText = [NSString stringWithFormat:@"This will open approximately %lu windows!", (unsigned long)words.count];
        [alert addButtonWithTitle:@"Cancel"];
        [alert addButtonWithTitle:@"Continue"];
        NSModalResponse response = [alert runModal];
        if (NSAlertSecondButtonReturn != response) return;
    }

    [self openString:string oneWordOnly:NO];
}

/*"
 * Breaks string up into words and calls -#openWord: on each one.
 * Essentially opens a man page for each word in string, while doing
 * some specialized processing as well -- treating "foo (5)" as one
 * page, recombining words that nroff hyphenated across lines, and
 * ignoring trailing commas.
"*/
- (void)openString:(NSString *)string oneWordOnly:(BOOL)oneOnly
{
    NSArray<NSString *> *words = string.manPageWords;
    if (oneOnly && words.count) {
        words = [NSArray arrayWithObject:words.firstObject];
    }
    
    for (NSString *word in words) {
        [self openWord:word];
    }
}

- (void)openTitleFromPanel
{
    NSString *string = [openTextField stringValue];
    NSArray<NSString *> *words = string.wordsSeparatedByWhitespaceAndNewlineCharacters;

    /* If the string is of the form "3 printf", arrange it better for our parser.  Requested by Eskimo.  Also accept 'n' as a section */
    if ([words count] == 2 &&
        [string rangeOfString:@"("].length == 0 &&
        [ManPage isSection:[words objectAtIndex:0]])
    {
        string = [NSString stringWithFormat:@"%@(%@)", [words objectAtIndex:1], [words objectAtIndex:0]];
    }
    
    /* Append the section if chosen in the popup and not explicity defined in the string */
    if ([string length] > 0 && [openSectionPopup indexOfSelectedItem] > 0 &&
        [string rangeOfString:@"("].length == 0)
    {
        string = [string stringByAppendingFormat:@"(%ld)", (long)[openSectionPopup indexOfSelectedItem]];
    }

    [self openString:string];
    [openTextField selectText:self];
}

- (void)openAproposFromPanel
{
    [self openApropos:[aproposField stringValue]];
    [aproposField selectText:self];
}


- (IBAction)openSection:(id)sender
{
    if ([sender tag] == 0)
        [self openApropos:@""]; // all pages
    else if ([sender tag] == 20)
        [self openApropos:@"(n)"];
    else
        [self openApropos:[NSString stringWithFormat:@"(%ld)", (long)[sender tag]]];
}

- (BOOL)useModalPanels
{
    return ![[NSUserDefaults standardUserDefaults] boolForKey:@"KeepPanelsOpen"];
}

- (IBAction)openTextPanel:(id)sender
{
    if (![openTextPanel isVisible])
        [openSectionPopup selectItemAtIndex:0];
    [openTextField selectText:self];

    if ([self useModalPanels]) {
        if ([NSApp runModalForWindow:openTextPanel] == NSModalResponseOK) {
            [self openTitleFromPanel];
            [NSApp activateIgnoringOtherApps:YES];
        }
    }
    else {
        [openTextPanel makeKeyAndOrderFront:self];
        [NSApp activateIgnoringOtherApps:YES];
    }
    
}

- (IBAction)openAproposPanel:(id)sender
{
    [aproposField selectText:self];
    if ([self useModalPanels]) {
        if ([NSApp runModalForWindow:aproposPanel] == NSModalResponseOK) {
            [self openAproposFromPanel];
            [NSApp activateIgnoringOtherApps:YES];
        }
    }
    else {
        [aproposPanel makeKeyAndOrderFront:self];
        [NSApp activateIgnoringOtherApps:YES];
    }
}

- (IBAction)okText:(id)sender
{
    if ([self useModalPanels])
        [[sender window] orderOut:self];

    if ([[sender window] level] == NSModalPanelWindowLevel) {
        [NSApp stopModalWithCode:NSModalResponseOK];
    }
    else {
        [self openTitleFromPanel];
    }
}

- (IBAction)okApropos:(id)sender
{
    if ([self useModalPanels])
        [[sender window] orderOut:self];

    if ([[sender window] level] == NSModalPanelWindowLevel) {
        [NSApp stopModalWithCode:NSModalResponseOK];
    }
    else {
        [self openAproposFromPanel];
    }
}

- (IBAction)cancelText:(id)sender
{
    [[sender window] orderOut:self];
    if ([[sender window] level] == NSModalPanelWindowLevel)
        [NSApp stopModalWithCode:NSModalResponseCancel];
}

- (void)ensureActive
{
    if (![[NSApplication sharedApplication] isActive])
        [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

- (void)openFile:(NSString *)filename forceToFront:(BOOL)force
{
    if (force)
        [self ensureActive];
    
    [self openDocumentWithContentsOfURL:[NSURL fileURLWithPath:filename]
                                display:YES
                      completionHandler:
     ^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error) {
         // nothing to do here
     }];
}

/*" Simple API methods to open a named man page "*/

- (void)openName:(NSString *)name section:(NSString *)section manPath:(NSString *)manPath forceToFront:(BOOL)force
{
    if (force)
        [self ensureActive];
    [self openDocumentWithName:name section:section manPath:manPath];
}

- (void)openApropos:(NSString *)apropos
{
    [self openAproposDocument:apropos manPath:[[NSUserDefaults standardUserDefaults] manPath]];
}

- (void)openApropos:(NSString *)apropos manPath:(NSString *)manPath forceToFront:(BOOL)force
{
    if (force)
        [self ensureActive];
    [self openAproposDocument:apropos manPath:manPath];
}

/*" Methods to do the services entries "*/
- (void)openFiles:(NSPasteboard *)pboard userData:(NSString *)data error:(NSString **)error
{
    NSArray *fileArray;
    NSArray *types = [pboard types];

    if ([types containsObject:NSFilenamesPboardType] &&
        (fileArray = [pboard propertyListForType:NSFilenamesPboardType]))
    {
        NSUInteger i, count = [fileArray count];
        NSError *openError = nil;
        for (i=0; i<count; i++)
        {
            [self openDocumentWithContentsOfURL:[NSURL fileURLWithPath:[fileArray objectAtIndex:i]]
                                        display:YES
                              completionHandler:
             ^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error) {
                 // nothing to do here
             }];
        }
        
        if (error != NULL && openError != nil)
            *error = [openError localizedDescription];
    }
}

- (void)openSelection:(NSPasteboard *)pboard userData:(NSString *)data error:(NSString **)error
{
    NSString *pboardString;
    NSArray *types = [pboard types];

    if ([types containsObject:NSStringPboardType] &&
        (pboardString = [pboard stringForType:NSStringPboardType]))
    {
        [self openString:pboardString];
    }
}

- (void)openApropos:(NSPasteboard *)pboard userData:(NSString *)data error:(NSString **)error
{
    NSString *pboardString;
    NSArray *types = [pboard types];

    if ([types containsObject:NSStringPboardType] &&
        (pboardString = [pboard stringForType:NSStringPboardType]))
    {
        [self openApropos:pboardString];
    }
}

- (IBAction)orderFrontHelpPanel:(id)sender
{
    [helpPanel makeKeyAndOrderFront:sender];
}
- (IBAction)showHelp:(id)sender  //OPENSTEP wants to call this for some reason...
{
    [self orderFrontHelpPanel:sender];
}
- (IBAction)orderFrontPreferencesPanel:(id)sender
{
    [[PrefPanelController sharedInstance] showWindow:sender];
}

/*
 Under MacOS X, NSApplication will not validate this menu item, so implement
   it here ourselves.
*/
- (IBAction)runPageLayout:(id)sender
{
    [NSApp runPageLayout:sender];
}
@end

