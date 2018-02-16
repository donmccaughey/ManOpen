/* PrefPanelController.m created by lindberg on Fri 08-Oct-1999 */

#import "PrefPanelController.h"
#import <AppKit/AppKit.h>
#import "ManDocumentController.h"
#import "MVAppInfo.h"
#import "NSUserDefaults+ManOpen.h"


@interface PrefPanelController (Private)
- (void)setUpDefaultManViewerApp;
- (void)setFontFieldToFont:(NSFont *)font;
- (void)setUpManPathUI;
@end

#define DATA_FOR_COLOR(color) [NSArchiver archivedDataWithRootObject:color]
#define BOOL_YES [NSNumber numberWithBool:YES]
#define BOOL_NO [NSNumber numberWithBool:NO]

@implementation PrefPanelController

+ (void)registerManDefaults
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSFileManager *manager = [NSFileManager defaultManager];
    NSDictionary *defaults;
    NSString *nroff   = @"nroff -mandoc '%@'";
    NSString *manpath = @"/usr/local/man:/usr/share/man";
    NSData *textColor = [userDefaults dataForKey:@"TextColor"]; // historical name
    NSData *linkColor = [userDefaults dataForKey:@"LinkColor"]; // historical name
    NSData *bgColor = [userDefaults dataForKey:@"BackgroundColor"]; // historical name
    
    if (textColor == nil)
        textColor = DATA_FOR_COLOR([NSColor textColor]);
    if (linkColor == nil)
        linkColor = DATA_FOR_COLOR([NSColor colorWithDeviceRed:0.1f green:0.1f blue:1.0f alpha:1.0f]);
    if (bgColor == nil)
        bgColor = DATA_FOR_COLOR([NSColor textBackgroundColor]);

    if ([manager fileExistsAtPath:@"/sw/share/man"]) // fink
        manpath = [@"/sw/share/man:" stringByAppendingString:manpath];
    if ([manager fileExistsAtPath:@"/opt/local/share/man"])  //macports
        manpath = [@"/opt/local/share/man:" stringByAppendingString:manpath];
    if ([manager fileExistsAtPath:@"/usr/X11R6/man"])
        manpath = [manpath stringByAppendingString:@":/usr/X11R6/man"];
    
    defaults = [NSDictionary dictionaryWithObjectsAndKeys:
                BOOL_NO,        @"QuitWhenLastClosed",
                BOOL_NO,        @"UseItalics",
                BOOL_YES,       @"UseBold",
                nroff,          @"NroffCommand",
                manpath,        @"ManPath",
                BOOL_NO,        @"KeepPanelsOpen",
                textColor,      @"ManTextColor",
                linkColor,      @"ManLinkColor",
                bgColor,        @"ManBackgroundColor",
                BOOL_YES,       @"NSQuitAlwaysKeepsWindows", // NO will disable by default
                nil];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

+ (id)allocWithZone:(NSZone *)aZone
{
    return [self sharedInstance];
}

+ (id)sharedInstance
{
    static id instance = nil;
    if (instance == nil)
        instance = [[super allocWithZone:NULL] init];
    return instance;
}

- (id)init
{
    self = [super initWithWindowNibName:@"PrefPanel"];
    [self setShouldCascadeWindows:NO];
    [[NSFontManager sharedFontManager] setDelegate:self];

    return self;
}

- (void)dealloc
{
    [manPathArray release];
    [super dealloc];
}

- (void)windowDidLoad
{
    [super windowDidLoad];

    /* The "save windows on quit" is a Lion-only feature */
    if (!IsLion()) {
        NSRect oldFrame = [generalSwitchMatrix frame];
        [generalSwitchMatrix removeRow:4];
        [generalSwitchMatrix sizeToCells];        
        NSRect newFrame = [generalSwitchMatrix frame];
        /* Keep the top edge at the same place; sizeToCells just lowers the height */
        newFrame.origin.y += (oldFrame.size.height - newFrame.size.height);
        [generalSwitchMatrix setFrame:newFrame];
        
    }
    [self setUpDefaultManViewerApp];
    [self setUpManPathUI];
    [self setFontFieldToFont:[[NSUserDefaults standardUserDefaults] manFont]];
}

- (void)setFontFieldToFont:(NSFont *)font
{
    if (!font) return;
    [fontField setFont:font];
    [fontField setStringValue:
        [NSString stringWithFormat:@"%@ %.1f", [font familyName], [font pointSize]]];
}

- (IBAction)openFontPanel:(id)sender
{
    [[self window] makeFirstResponder:nil];     // Make sure *we* get the changeFont: call
    [[NSFontManager sharedFontManager] setSelectedFont:[fontField font] isMultiple:NO];
    [[NSFontPanel sharedFontPanel] orderFront:self];   // Leave us as key
}

/* We only want to allow fixed-pitch fonts.  Does not seem to be called on OSX, though it was documented to work pre-10.3. Rats. */
- (BOOL)fontManager:(id)sender willIncludeFont:(NSString *)fontName
{
    return [sender fontNamed:fontName hasTraits:NSFixedPitchFontMask];
}

- (void)changeFont:(id)sender
{
    NSFont *font = [fontField font];
    NSString *fontString;

    font = [sender convertFont:font];
    [self setFontFieldToFont:font];
    fontString = [NSString stringWithFormat:@"%f %@", [font pointSize], [font fontName]];
    [[NSUserDefaults standardUserDefaults] setObject:fontString forKey:@"ManFont"];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    SEL action = [menuItem action];

    if ((action == @selector(cut:)) || (action == @selector(copy:)) || (action == @selector(delete:)))
    {
        return [manPathController canRemove];
    }

    if (action == @selector(paste:))
    {
        NSArray *types = [[NSPasteboard generalPasteboard] types];
        return [manPathController canInsert] &&
               ([types containsObject:NSFilenamesPboardType] || [types containsObject:NSStringPboardType]);
    }
    /* The menu on our app popup may call this validate method ;-) */
    if (action == @selector(chooseNewApp:))
        return YES;

//    NSLog(@"unk item: %s", action);
    return NO;
}

@end


/* Man path table view pref code.  We are trying to support drag-reordering, and other fun stuff. */


static NSString *ManPathIndexSetPboardType = @"org.clindberg.ManOpen.ManPathIndexSetType";
static NSString *ManPathArrayKey = @"manPathArray";


@implementation PrefPanelController (ManPath)

- (void)setUpManPathUI
{
    [manPathTableView registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, NSStringPboardType, ManPathIndexSetPboardType, nil]];
    [manPathTableView setVerticalMotionCanBeginDrag:YES];
    // XXX NSDragOperationDelete -- not sure the "poof" drag can show that
    [manPathTableView setDraggingSourceOperationMask:NSDragOperationCopy                     forLocal:NO];
    [manPathTableView setDraggingSourceOperationMask:NSDragOperationCopy|NSDragOperationMove|NSDragOperationPrivate forLocal:YES];
}

- (void)saveManPath
{
    if (manPathArray != nil)
        [[NSUserDefaults standardUserDefaults] setObject:[manPathArray componentsJoinedByString:@":"] forKey:@"ManPath"];
}

- (void)addPathDirectories:(NSArray *)directories atIndex:(NSUInteger)insertIndex removeFirst:(NSIndexSet *)removeIndexes
{
    /*
     * For now, trying to see if a simple array of strings will work with NSArrayController.
     * Usually you want to have objects or at least NSDictionary instances with known keys,
     * since bindings work best with key-value setups, but we may be able to hack it since
     * our values are non-editable, by using "description" as the keypath on the NSStrings.
     */
    NSInteger i;

    [self willChangeValueForKey:ManPathArrayKey];
    if (removeIndexes != nil)
    {
        int numBeforeInsertion = 0;

        for (i=[manPathArray count]-1; i>=0; i--)
        {
            if ([removeIndexes containsIndex:i])
            {
                [manPathArray removeObjectAtIndex:i];
                if (i <= insertIndex) numBeforeInsertion++; // need to adjust insertion index
            }
        }
        
        insertIndex -= numBeforeInsertion;
    }

    for (i=0; i<[directories count]; i++)
    {
        NSString *path = [[directories objectAtIndex:i] stringByExpandingTildeInPath];
        NSRange colonRange = [path rangeOfString:@":"];
        while (colonRange.length > 0) { // stringByReplacingOccurrencesOfString is not until 10.5... grrr...
            path = [[path substringToIndex:colonRange.location] stringByAppendingString:[path substringFromIndex:NSMaxRange(colonRange)]];
            colonRange = [path rangeOfString:@":"];
        }
        if (![manPathArray containsObject:path])
            [manPathArray insertObject:path atIndex:insertIndex++];
    }
    [self didChangeValueForKey:ManPathArrayKey];
    [self saveManPath];
}


/* These two methods are bound to the array controller */
- (NSArray *)manPathArray
{
    if (manPathArray == nil)
    {
        NSString *path = [[NSUserDefaults standardUserDefaults] manPath];
        manPathArray = [[path componentsSeparatedByString:@":"] mutableCopy];
    }
    
    return manPathArray;
}
- (void)setManPathArray:(NSArray *)anArray;
{
    [manPathArray setArray:anArray];
    [self saveManPath];
}


- (IBAction)addPathFromPanel:(id)sender
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];

    [panel setAllowsMultipleSelection:YES];
    [panel setCanChooseDirectories:YES];
    [panel setCanChooseFiles:NO];

    [panel beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result) {
        [self didAddManPathFromPanel:panel result:result];
    }];
}

- (void)didAddManPathFromPanel:(NSOpenPanel *)panel result:(NSModalResponse)result
{
    if (NSFileHandlingPanelOKButton == result)
    {
        NSArray *urls = [panel URLs];
        NSUInteger i, count = [urls count];
        NSMutableArray *paths = [NSMutableArray arrayWithCapacity:count];

        for (i=0; i<count; i++)
        {
            NSURL *url = [urls objectAtIndex:i];
            if ([url isFileURL])
                [paths addObject:[url path]];
        }

        NSUInteger insertionIndex = [manPathController selectionIndex];
        if (insertionIndex == NSNotFound)
            insertionIndex = [manPathArray count]; //add it on the end

        [self addPathDirectories:paths atIndex:insertionIndex removeFirst:nil];
    }
}

- (NSArray *)pathsAtIndexes:(NSIndexSet *)set
{
    NSMutableArray *paths = [NSMutableArray arrayWithCapacity:[set count]];
    NSUInteger currIndex;
    
    for (currIndex = 0; currIndex < [manPathArray count]; currIndex++)
    {
        if ([set containsIndex:currIndex])
            [paths addObject:[manPathArray objectAtIndex:currIndex]];
    }

    return paths;
}

- (BOOL)writePaths:(NSArray *)paths toPasteboard:(NSPasteboard *)pb
{
    [pb declareTypes:[NSArray arrayWithObjects:NSStringPboardType, nil] owner:nil];

    /* This causes an NSLog if one of the paths does not exist. Hm.  May not be worth it. Might let folks drag to Trash etc. as well. */
//        [pb setPropertyList:paths forType:NSFilenamesPboardType];
    return [pb setString:[paths componentsJoinedByString:@":"] forType:NSStringPboardType];
}

- (BOOL)writeIndexSet:(NSIndexSet *)set toPasteboard:(NSPasteboard *)pb
{
    NSArray *files = [self pathsAtIndexes:set];

    if ([self writePaths:files toPasteboard:pb])
    {
        [pb addTypes:[NSArray arrayWithObject:ManPathIndexSetPboardType] owner:nil];
        return [pb setData:[NSArchiver archivedDataWithRootObject:set] forType:ManPathIndexSetPboardType];
    }

    return NO;
}

- (NSArray *)pathsFromPasteboard:(NSPasteboard *)pb
{
    NSString *bestType = [pb availableTypeFromArray:[NSArray arrayWithObjects:NSFilenamesPboardType, NSStringPboardType, nil]];
    
    if ([bestType isEqual:NSFilenamesPboardType])
        return [pb propertyListForType:NSFilenamesPboardType];
    
    if ([bestType isEqual:NSStringPboardType])
        return [[pb stringForType:NSStringPboardType] componentsSeparatedByString:@":"];
    
    return nil;
}

- (void)copy:(id)sender
{
    NSArray *files = [self pathsAtIndexes:[manPathController selectionIndexes]];
    [self writePaths:files toPasteboard:[NSPasteboard generalPasteboard]];
}
- (void)delete:(id)sender
{
    [manPathController remove:sender];
}
- (void)cut:(id)sender
{
    [self copy:sender];
    [self delete:sender];
}
- (void)paste:(id)sender
{
    NSArray *paths = [self pathsFromPasteboard:[NSPasteboard generalPasteboard]];
    NSUInteger insertionIndex = [manPathController selectionIndex];
    if (insertionIndex == NSNotFound)
        insertionIndex = [manPathArray count]; //add it on the end
    [self addPathDirectories:paths atIndex:insertionIndex removeFirst:nil];
}

// drag and drop
- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
    return [self writeIndexSet:rowIndexes toPasteboard:pboard];
}
- (NSDragOperation)tableView:(NSTableView*)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
    NSPasteboard *pb = [info draggingPasteboard];

    /* We only drop between rows */
    if (dropOperation != NSTableViewDropAbove)
        return NSDragOperationNone;

    /* If this is a dragging operation in the table itself, show the move icon */
    if ([[pb types] containsObject:ManPathIndexSetPboardType] && ([info draggingSource] == manPathTableView))
        return NSDragOperationMove;

    NSArray *paths = [self pathsFromPasteboard:pb];
    NSUInteger i;
    for (i=0; i<[paths count]; i++)
    {
        NSString *path = [paths objectAtIndex:i];
        if (![manPathArray containsObject:path])
            return NSDragOperationCopy;
    }

    return NSDragOperationNone;
}
- (BOOL)tableView:(NSTableView*)tableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation
{
    NSPasteboard *pb = [info draggingPasteboard];
    NSDragOperation dragOp = [info draggingSourceOperationMask];
    NSArray *pathsToAdd = nil;
    NSIndexSet *removeSet = nil;
    
    if ([[pb types] containsObject:ManPathIndexSetPboardType])
    {
        NSData *indexData = [pb dataForType:ManPathIndexSetPboardType];
        if ((dragOp & NSDragOperationMove) && indexData != nil) {
            removeSet = [NSUnarchiver unarchiveObjectWithData:indexData];
            pathsToAdd = [self pathsAtIndexes:removeSet];
        }
    }
    else
    {
        pathsToAdd = [self pathsFromPasteboard:pb];
    }

    if ([pathsToAdd count] > 0)
    {
        [self addPathDirectories:pathsToAdd atIndex:row removeFirst:removeSet];
        return YES;
    }
    
    return NO;
}

/* PoofDragTableView datasource method */
- (BOOL)tableView:(NSTableView *)tableView performDropOutsideViewAtPoint:(NSPoint)screenPoint
{
    NSPasteboard *pb = [NSPasteboard pasteboardWithName:NSDragPboard];
    if ([[pb types] containsObject:ManPathIndexSetPboardType])
    {
        NSData *indexData = [pb dataForType:ManPathIndexSetPboardType];
        if (indexData != nil)
        {
            NSIndexSet *removeSet = [NSUnarchiver unarchiveObjectWithData:indexData];
            if ([removeSet count] > 0) {
                [self addPathDirectories:[NSArray array] atIndex:0 removeFirst:removeSet];
                return YES;
            }
        }
    }

    return NO;
}

@end





/* 
 * Add a preference pane so that the user can set the default x-man-page
 * application. Under Panther (10.3), Terminal.app supports this, so we should
 * too.  The APIs were private and undocumented prior to 10.4, which is a big reason
 * why that version is now required, since the below code uses the 10.4 APIs.
 */

static NSString *currentAppID = nil;


@implementation PrefPanelController (DefaultManApp)

- (void)setAppPopupToCurrent
{
    NSUInteger currIndex = [MVAppInfo indexOfBundleID:currentAppID];

    if (currIndex == NSNotFound) {
        currIndex = 0;
    }

    if (currIndex < [appPopup numberOfItems])
        [appPopup selectItemAtIndex:currIndex];
}

- (void)resetAppPopup
{
    NSArray *apps = [MVAppInfo allManViewerApps];
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    NSUInteger i;

    [appPopup removeAllItems];
    [appPopup setImage:nil];

    for (i=0; i<[apps count]; i++)
    {
        MVAppInfo *info = [apps objectAtIndex:i];
        NSImage *image = [[workspace iconForFile:[[info appURL] path]] copy];
        NSString *niceName = [info displayName];
        NSString *displayName = niceName;
        int num = 2;

        /* This should never happen any more since apps are uniqued to their bundle ID, but ... */
        while ([appPopup indexOfItemWithTitle:displayName] >= 0) {
            displayName = [NSString stringWithFormat:@"%@[%d]", niceName, num++];
        }
        [appPopup addItemWithTitle:displayName];

        [image setSize:NSMakeSize(16, 16)];
        [[appPopup itemAtIndex:i] setImage:image];
        [image release];
    }

    if ([apps count] > 0)
        [[appPopup menu] addItem:[NSMenuItem separatorItem]];
    [appPopup addItemWithTitle:NSLocalizedString(@"Select... ", @"Select... ")];
    [self setAppPopupToCurrent];
}

- (void)resetCurrentApp
{
    NSString *currSetID = (id)LSCopyDefaultHandlerForURLScheme((CFStringRef)URL_SCHEME);
    
    if (currSetID == nil)
        currSetID = [[[MVAppInfo allManViewerApps] objectAtIndex:0] bundleID];
 
    if (currSetID != nil)
    {
        BOOL resetPopup = (currentAppID == nil); //first time

        [currentAppID release];
        currentAppID = [currSetID retain];
        [currSetID release];

        if ([MVAppInfo indexOfBundleID:currSetID] == NSNotFound)
        {
            [MVAppInfo addAppWithID:currSetID sort:YES];
            resetPopup = YES;
        }
        if (resetPopup)
            [self resetAppPopup];
        else
            [self setAppPopupToCurrent];
    }
}

- (void)setManPageViewer:(NSString *)bundleID
{
    OSStatus error = LSSetDefaultHandlerForURLScheme((CFStringRef)URL_SCHEME, (CFStringRef)bundleID);
    
    if (error != noErr)
        NSLog(@"Could not set default " URL_SCHEME_PREFIX @" app: Launch Services error %d", error);

    [self resetCurrentApp];
}

- (void)setUpDefaultManViewerApp
{
    [MVAppInfo allManViewerApps];
    [self resetCurrentApp];
}

- (IBAction)chooseNewApp:(id)sender
{
    NSArray *apps = [MVAppInfo allManViewerApps];
    NSInteger choice = [appPopup indexOfSelectedItem];

    if (choice >= 0 && choice < [apps count]) {
        MVAppInfo *info = [apps objectAtIndex:choice];
        if ([info bundleID] != currentAppID)
            [self setManPageViewer:[info bundleID]];
    }
    else {
        NSOpenPanel *panel = [NSOpenPanel openPanel];
        [panel setTreatsFilePackagesAsDirectories:NO];
        [panel setAllowsMultipleSelection:NO];
        [panel setResolvesAliases:YES];
        [panel setCanChooseFiles:YES];
        [panel setAllowedFileTypes:[NSArray arrayWithObject:@"app"]];
        [panel beginSheetModalForWindow:[appPopup window] completionHandler:^(NSModalResponse result) {
            [self panelDidEnd:panel result:result];
        }];
    }
}

- (void)panelDidEnd:(NSOpenPanel *)panel result:(NSModalResponse)result
{
    if (NSFileHandlingPanelOKButton == result) {
        NSURL *appURL = [panel URL];
        NSString *appID = [[NSBundle bundleWithPath:[appURL path]] bundleIdentifier];
        if (appID != nil)
            [self setManPageViewer:appID];
    }
    [self setAppPopupToCurrent];
}
@end
