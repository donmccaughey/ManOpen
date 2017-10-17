
#import "ManDocumentController.h"
#import <AppKit/AppKit.h>
#import "ManDocument.h"
#import "AproposDocument.h"
#import "NSData+Utils.h"
#import "PrefPanelController.h"


#define MAN_BINARY     @"/usr/bin/man"
//#define MANPATH_FORMAT @" -m '%@'"  // There's a bug in man(1) on OSX and OSXS
#define MANPATH_FORMAT @" -M '%@'"


/* 
 * We need to make sure we handle all sorts of characters in filenames. The way
 * to do that is surround the path with ' characters -- but then we have to
 * escape any ' characters actually in the string. To do that, you need to add a
 * ' to close the quote section, add an escaped ', then add another ' to start
 * quoting again. Something like '\'' or '"'"'. E.g.: /foo/bar -> '/foo/bar',
 * /foo bar/baz -> '/foo bar/baz', /Apple's Stuff -> '/Apple'\''s Stuff'.
 */
NSString *EscapePath(NSString *path, BOOL addSurroundingQuotes)
{
    if ([path rangeOfString:@"'"].length > 0)
    {
        NSMutableString *newString = [NSMutableString string];
        NSScanner       *scanner = [NSScanner scannerWithString:path];

        [scanner setCharactersToBeSkipped:nil];

        while (![scanner isAtEnd])
        {
            NSString *betweenString = nil;
            if ([scanner scanUpToString:@"'" intoString:&betweenString])
                [newString appendString:betweenString];
            if ([scanner scanString:@"'" intoString:NULL])
                [newString appendString:@"'\\''"];
        }

        path = newString;
    }

    if (addSurroundingQuotes)
        path = [NSString stringWithFormat:@"'%@'", path];

    return path;
}

@implementation ManDocumentController

- init
{
    NSConnection *connection = [NSConnection defaultConnection];

    [super init];

    /*
     * Set ourselves up for DO connections.  I do it here so it's done as
     * early as possible.  If the command-line tool still has problems
     * connecting, we may be able to do this whole thing in main()...
     */
    [connection registerName:@"ManOpenApp"];
    [connection setRootObject:self];

    [PrefPanelController registerManDefaults];
    [NSBundle loadNibNamed:@"DocController" owner:self];

    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [NSApp setServicesProvider:self];

    /* Remember window positions, in case they're non-modal */
    [openTextPanel setFrameUsingName:@"OpenTitlePanel"];
    [openTextPanel setFrameAutosaveName:@"OpenTitlePanel"];
    [aproposPanel setFrameUsingName:@"AproposPanel"];
    [aproposPanel setFrameAutosaveName:@"AproposPanel"];

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
    NSMutableString *command = [NSMutableString stringWithString:MAN_BINARY];

    if (manPath && [manPath length] > 0)
        [command appendFormat:MANPATH_FORMAT, EscapePath(manPath, NO)];

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
    NSDictionary  *attributes = [manager fileAttributesAtPath:filename traverseLink:YES];
    NSUInteger    maxLength = MIN(150, (NSUInteger)[attributes fileSize]);
    NSData        *fileHeader;
    NSString      *catType = @"cat";
    NSString      *manType = @"man";

    if (maxLength == 0) return catType;

    handle = [NSFileHandle fileHandleForReadingAtPath:filename];
    fileHeader = [handle readDataOfLength:maxLength];

    if ([attributes fileSize] > 1000000) return nil;

    if ([fileHeader isGzipData]) {
        NSString *command = [NSString stringWithFormat:@"/usr/bin/gzip -dc '%@'", EscapePath(filename, NO)];
        fileHeader = [self dataByExecutingCommand:command maxLength:maxLength];
        manType = @"mangz";
        catType = @"catgz";
    }

    if ([fileHeader isBinaryData]) return nil;

    return [fileHeader isNroffData]? manType : catType;
}

/*
 * Many methods in the super implementation will only call -makeDocument... etc. if the
 * file's extension is listed in in the NSTypes section in Info.plist.
 * Since we don't want to declare the typical .1, .2, etc. extensions,
 * plus the fact that often man pages outside of the typical MANPATH
 * directories often have other-than-standard extensions, we declare public.data
 * in our Info.plist, which is the usual fix for that situation.  We also override
 * this method completely to avoid the superclass from stumbling over this, which
 * was once the only method we needed to override, but no longer.  The public.data
 * declaration is required for applications linked earlier than 10.7, and at least
 * at the moment, further overrides are necessary, since I want to determine the type
 * by file contents and not extension.  it's possible we could move the type-determining
 * logic into ManDocument itself, but it seems to work this way...
 */
- (id)openDocumentWithContentsOfURL:(NSURL *)absoluteURL display:(BOOL)display error:(NSError **)outError
{
    NSDocument *document;

    /*
     * NSDocument[Controller] doesn't standardize filenames, at least when
     * calling -initWithContentsOfFile:, meaning it will raise if it gets a
     * symlink rather then a regular file.  Therefore, we standardize the path
     * so that symlinks are resolved and removed from the equation.  This will
     * also make document lookup always find the file if it's open, even if under
     * another name, a common situation with man pages.
     */
    NSString *filename = [[absoluteURL path] stringByStandardizingPath];
    NSURL *standardizedURL = [NSURL fileURLWithPath:filename];
    
    if ((document = [self documentForURL:standardizedURL]) == nil)
    {
        /* Resolve the type by contents rather than relying on the extension. */
        NSString *type = [self typeFromFilename:[standardizedURL path]];

        if (type != nil)
        {
            document = [self makeDocumentWithContentsOfURL:standardizedURL ofType:type error:outError];
            [document makeWindowControllers];
            [self addDocument:document];
        }
    }
    if (display)
        [document showWindows];
    return document;
}


#if NS_BLOCKS_AVAILABLE
/*
 * The super implementations of these likewise get confused if someone opens a non-declared
 * extension, even when declaring public.data as a generic type.  When linked against 10.7
 * libraries, these are called instead of the older method above, and I'm getting
 * " QLError(): +[QLSeamlessDocumentOpener seamlessDocumentOpenerForURL:] should only be called in the main thread"
 * errors.  That may be related to the canConcurrentlyReadDocumentsOfType: in the document classes.
 * Overriding these to just call our older override above seems to fix
 * it. If linked against 10.6 or earlier, the default implementation will simply
 * call our override directly it seems.
 */
- (void)openDocumentWithContentsOfURL:(NSURL *)url display:(BOOL)displayDocument completionHandler:(void (^)(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error))completionHandler
{
    NSError *error = nil;
    NSUInteger numDocuments = [[self documents] count];
    NSDocument *document = [self openDocumentWithContentsOfURL:url display:displayDocument error:&error];
    BOOL docAdded = numDocuments < [[self documents] count];
    
    completionHandler(document, !docAdded, error);
}
- (void)reopenDocumentForURL:(NSURL *)url withContentsOfURL:(NSURL*)url2 display:(BOOL)displayDocument completionHandler:(void (^)(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error))completionHandler
{
    [self openDocumentWithContentsOfURL:url display:displayDocument completionHandler:completionHandler];
}
#endif

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


static NSArray *GetWordArray(NSString *string)
{
    NSCharacterSet *spaceSet    = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSCharacterSet *nonspaceSet = [spaceSet invertedSet];
    NSMutableArray *wordArray   = [NSMutableArray array];
    NSScanner      *scanner     = [NSScanner scannerWithString:string];
    NSString       *aWord;
    
    [scanner setCharactersToBeSkipped:spaceSet];
    
    while (![scanner isAtEnd])
    {
        if ([scanner scanCharactersFromSet:nonspaceSet intoString:&aWord])
            [wordArray addObject:aWord];
    }
    
    return wordArray;
}

- (void)openString:(NSString *)string
{
    NSArray *words = GetWordArray(string);
    
    if ([words count] > 20) {
        NSInteger reply = NSRunAlertPanel(@"Warning", @"This will open approximately %d windows!",
                                          @"Cancel", @"Continue", nil, [words count]);
        if (reply != NSAlertAlternateReturn)
            return;
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
    NSScanner      *scanner = [NSScanner scannerWithString:string];
    NSCharacterSet *whitespaceSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSCharacterSet *nonwhitespaceSet = [whitespaceSet invertedSet];
    NSString       *aWord;
    NSString       *lastWord = nil;

    [scanner setCharactersToBeSkipped:whitespaceSet];

    while (![scanner isAtEnd])
    {
        if ([scanner scanCharactersFromSet:nonwhitespaceSet intoString:&aWord])
        {
            if (lastWord == nil)
            {
                lastWord = aWord;
            }
            /* If there was a space between the name and section, join them */
            else if ([aWord hasPrefix:@"("] && [aWord hasSuffix:@")"])
            {
                [self openWord:[lastWord stringByAppendingString:aWord]];
                lastWord = nil;
                if (oneOnly) break;
            }
            /* If (g)nroff hyphenated a word across lines, rejoin them */
            else if ([lastWord hasSuffix:@"-"])
            {
                lastWord = [lastWord substringToIndex:[lastWord length] - 1];
                lastWord = [lastWord stringByAppendingString:aWord];
            }
            else
            {
                /* SEE ALSO sections often have commas between items, ignore it */
                if ([lastWord hasSuffix:@","])
                    lastWord = [lastWord substringToIndex:[lastWord length] - 1];
                [self openWord:lastWord];
                lastWord = nil;
                if (oneOnly) break;
                lastWord = aWord;
            }
        }
    }

    if (lastWord != nil) {
        if ([lastWord hasSuffix:@","])
            lastWord = [lastWord substringToIndex:[lastWord length] - 1];
        [self openWord:lastWord];
    }
}

static BOOL IsSectionWord(NSString *word)
{
    if ([word length] <= 0) return NO;
    if ([[NSCharacterSet decimalDigitCharacterSet] characterIsMember:[word characterAtIndex:0]])
        return YES;
    if ([word isEqual:@"n"]) return YES;
    return NO;
}
- (void)openTitleFromPanel
{
    NSString *string = [openTextField stringValue];
    NSArray *words = GetWordArray(string);

    /* If the string is of the form "3 printf", arrange it better for our parser.  Requested by Eskimo.  Also accept 'n' as a section */
    if ([words count] == 2 &&
        [string rangeOfString:@"("].length == 0 &&
        IsSectionWord([words objectAtIndex:0]))
    {
        string = [NSString stringWithFormat:@"%@(%@)", [words objectAtIndex:1], [words objectAtIndex:0]];
    }
    
    /* Append the section if chosen in the popup and not explicity defined in the string */
    if ([string length] > 0 && [openSectionPopup indexOfSelectedItem] > 0 &&
        [string rangeOfString:@"("].length == 0)
    {
        string = [string stringByAppendingFormat:@"(%d)", [openSectionPopup indexOfSelectedItem]];
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
        [self openApropos:[NSString stringWithFormat:@"(%d", [sender tag]]];
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
        if ([NSApp runModalForWindow:openTextPanel] == NSOKButton)
            [self openTitleFromPanel];
    }
    else {
        [openTextPanel makeKeyAndOrderFront:self];
    }
}

- (IBAction)openAproposPanel:(id)sender
{
    [aproposField selectText:self];
    if ([self useModalPanels]) {
        if ([NSApp runModalForWindow:aproposPanel] == NSOKButton)
            [self openAproposFromPanel];
    }
    else {
        [aproposPanel makeKeyAndOrderFront:self];
    }
}

- (IBAction)okText:(id)sender
{
    if ([self useModalPanels])
        [[sender window] orderOut:self];

    if ([[sender window] level] == NSModalPanelWindowLevel) {
        [NSApp stopModalWithCode:NSOKButton];
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
        [NSApp stopModalWithCode:NSOKButton];
    }
    else {
        [self openAproposFromPanel];
    }
}

- (IBAction)cancelText:(id)sender
{
    [[sender window] orderOut:self];
    if ([[sender window] level] == NSModalPanelWindowLevel)
        [NSApp stopModalWithCode:NSCancelButton];
}

- (void)ensureActive
{
    if (![[NSApplication sharedApplication] isActive])
        [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

/*" A simple API method to open a file "*/
- (oneway void)openFile:(NSString *)filename
{
    [self openFile:filename forceToFront:YES];
}

- (oneway void)openFile:(NSString *)filename forceToFront:(BOOL)force
{
    if (force)
        [self ensureActive];
    [self openDocumentWithContentsOfURL:[NSURL fileURLWithPath:filename] display:YES error:NULL];
}

/*" Simple API methods to open a named man page "*/

- (oneway void)openName:(NSString *)name section:(NSString *)section manPath:(NSString *)manPath forceToFront:(BOOL)force
{
    if (force)
        [self ensureActive];
    [self openDocumentWithName:name section:section manPath:manPath];
}

- (oneway void)openName:(NSString *)name section:(NSString *)section manPath:(NSString *)manPath
{
    [self openName:name section:section manPath:manPath forceToFront:YES];
}

- (oneway void)openName:(NSString *)name section:(NSString *)section
{
    [self openName:name section:section manPath:[[NSUserDefaults standardUserDefaults] manPath]];
}

- (oneway void)openName:(NSString *)name
{
    [self openName:name section:nil];
}

- (oneway void)openApropos:(NSString *)apropos
{
    [self openAproposDocument:apropos manPath:[[NSUserDefaults standardUserDefaults] manPath]];
}

- (oneway void)openApropos:(NSString *)apropos manPath:(NSString *)manPath forceToFront:(BOOL)force
{
    if (force)
        [self ensureActive];
    [self openAproposDocument:apropos manPath:manPath];
}

- (oneway void)openApropos:(NSString *)apropos manPath:(NSString *)manPath
{
    [self openApropos:apropos manPath:manPath forceToFront:YES];
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
            [self openDocumentWithContentsOfURL:[NSURL fileURLWithPath:[fileArray objectAtIndex:i]] display:YES error:&openError];
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


/* Implement our x-man-page: scheme handler */
#import <Foundation/NSScriptCommand.h>
#import <Foundation/NSURL.h>

@interface ManOpenURLHandlerCommand : NSScriptCommand
@end

@implementation ManOpenURLHandlerCommand

#define URL_SCHEME @"x-man-page"
#define URL_PREFIX URL_SCHEME @":"

/*
 * Terminal seems to accept URLs of the form x-man-page://ls , which means
 * the man page name is essentially the "host" portion, and is passed
 * as an argument to the man(1) command.  The double slash is necessary.
 * Terminal accepts a path portion as well, and will take the first path
 * component and add it to the command as a second argument.  Any other
 * path components are ignored.  Thus, x-man-page://3/printf opens up
 * printf(3), and x-man-page://printf/ls opens both printf(1) and ls(1).
 *
 * We make sure to accept all these forms, and maybe some others.  We'll
 * use all path components, and not require the "//" portion.  We'll build
 * up a string and pass it to our -openString:, which wants things like
 * "printf(3) ls pwd".
 */
- (id)performDefaultImplementation
{
    NSString *param = [self directParameter];
    NSString *section = nil;

    if ([param rangeOfString:URL_PREFIX options:NSCaseInsensitiveSearch|NSAnchoredSearch].length > 0)
    {
        NSString *path = [param substringFromIndex:[URL_PREFIX length]];
        NSMutableArray *pageNames = [NSMutableArray array];
        NSArray *components = [path pathComponents];
        NSUInteger i, count = [components count];

        for (i=0; i<count; i++)
        {
            NSString *name = [components objectAtIndex:i];
            if ([name length] == 0 || [name isEqual:@"/"]) continue;
            if (IsSectionWord(name)) {
                section = name;
            }
            else {
                [pageNames addObject:name];
                if (section != nil) {
                    [pageNames addObject:[NSString stringWithFormat:@"(%@)", section]];
                    section = nil;
                }
            }
        }

        if ([pageNames count] > 0)
            [[ManDocumentController sharedDocumentController] openString:[pageNames componentsJoinedByString:@" "]];
    }
    return nil;
}

@end

