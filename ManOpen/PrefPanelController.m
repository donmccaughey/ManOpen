/* PrefPanelController.m created by lindberg on Fri 08-Oct-1999 */

#import "PrefPanelController.h"
#import <AppKit/AppKit.h>
#import "ManDocumentController.h"

@implementation NSUserDefaults (ManOpenPreferences)

- (NSColor *)_manColorForKey:(NSString *)key
{
    NSData *colorData = [self dataForKey:key];
    
    if (colorData == nil) return nil;
    return [NSUnarchiver unarchiveObjectWithData:colorData];
}
- (NSColor *)manTextColor
{
    return [self _manColorForKey:@"ManTextColor"];
}
- (NSColor *)manLinkColor
{
    return [self _manColorForKey:@"ManLinkColor"];
}
- (NSColor *)manBackgroundColor
{
    return [self _manColorForKey:@"ManBackgroundColor"];
}
    
- (NSFont *)manFont
{
    NSString *fontString = [self stringForKey:@"ManFont"];
    
    if (fontString != nil)
    {
        NSRange spaceRange = [fontString rangeOfString:@" "];
        if (spaceRange.length > 0)
        {
            CGFloat size = [[fontString substringToIndex:spaceRange.location] floatValue];
            NSString *name = [fontString substringFromIndex:NSMaxRange(spaceRange)];
            NSFont *font = [NSFont fontWithName:name size:size];
            if (font != nil) return font;
        }
    }
    
    return [NSFont userFixedPitchFontOfSize:12.0f]; // Monaco
}

- (NSString *)manPath
{
    return [self stringForKey:@"ManPath"];
}

@end


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


/*
 * Class to add a delegate method for when something was dropped with no other action
 * outside the view, i.e. the "poof" removing functionality.  In 10.7, this can almost
 * be implemented in the dataSource, but I wanted to retain the "slide back" functionality
 * when dropped in an invalid place inside the view, which requires a subclass anyways.
 * Prior to 10.7, a subclass is required to get the "end" notification, and also to
 * disable the "slide back" functionality.
 */
@interface PoofDragTableView : NSTableView
@end

@interface NSObject (PoofDragDataSource)
- (BOOL)tableView:(NSTableView *)tableView performDropOutsideViewAtPoint:(NSPoint)screenPoint;
@end

/*
 * NSDraggingSession is a 10.7 only class, which has the slide-back property, which Id like to
 * set depending on the image is inside or outside the view.  Since I will be compiling on
 * pre-10.7 systems, I can't invoke the API directly.
 */
@class NSDraggingSession;
#define SessionSlideBackKey @"animatesToStartingPositionsOnCancelOrFail"

@implementation PoofDragTableView

- (BOOL)containsScreenPoint:(NSPoint)screenPoint
{
    NSPoint windowPoint = [[self window] convertScreenToBase:screenPoint];
    NSPoint viewPoint = [self convertPoint:windowPoint fromView:nil];

    return NSMouseInRect(viewPoint, [self bounds], [self isFlipped]);
}

- (void)dragImage:(NSImage *)anImage at:(NSPoint)imageLoc offset:(NSSize)mouseOffset event:(NSEvent *)theEvent pasteboard:(NSPasteboard *)pboard source:(id)sourceObject slideBack:(BOOL)slideBack
{
    /* Prevent slide back prior to Lion (where we can control it with newer methods) */
    [super dragImage:anImage at:imageLoc offset:mouseOffset event:theEvent pasteboard:pboard source:sourceObject slideBack:IsLion() && slideBack];
}

/* Only implement the 10.7 method, since I don't think we can conditionally affect the "slide back" value prior to 10.7 */
- (void)draggingSession:(NSDraggingSession *)session movedToPoint:(NSPoint)screenPoint
{
//    [super draggingSession:session movedToPoint:screenPoint]; // doesn't exist
    [session setValue:[NSNumber numberWithBool:[self containsScreenPoint:screenPoint]] forKey:SessionSlideBackKey];
}

/* 10.7 has a new method, but it still calls this one, so this is all we need */
- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)screenPoint operation:(NSDragOperation)operation
{
    /* Only try the poof if the operation was None (nothing accepted the drop) and it is outside our view */
    if (operation == NSDragOperationNone && ![self containsScreenPoint:screenPoint])
    {
        if ([[self dataSource] respondsToSelector:@selector(tableView:performDropOutsideViewAtPoint:)] &&
            [(id)[self dataSource] tableView:self performDropOutsideViewAtPoint:screenPoint])
        {
            NSShowAnimationEffect(NSAnimationEffectDisappearingItemDefault, screenPoint, NSZeroSize, nil, nil, nil);
        }
    }
    [super draggedImage:anImage endedAt:screenPoint operation:operation];
}

@end


/* Formatter to abbreviate folders in the user's home directory for a nicer display. */
@implementation DisplayPathFormatter

- (NSString *)stringForObjectValue:(id)anObject
{
    NSString *new = [anObject stringByAbbreviatingWithTildeInPath];
    
    /* The above method may not work if the home directory is a symlink, and our path is already resolved */
    if ([new isAbsolutePath])
    {
        static NSString *resHome = nil;
        if (resHome == nil)
            resHome = [[[NSHomeDirectory() stringByResolvingSymlinksInPath] stringByAppendingString:@"/"] retain];

        if ([new hasPrefix:resHome])
            new = [@"~/" stringByAppendingString:[new substringFromIndex:[resHome length]]];
    }
    
    return new;
}
- (BOOL)getObjectValue:(id *)anObject forString:(NSString *)string errorDescription:(NSString **)error {
    *anObject = [string stringByExpandingTildeInPath];
    return YES;
}
@end

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

    [panel beginSheetForDirectory:nil file:nil
         modalForWindow:[self window]
         modalDelegate:self
         didEndSelector:@selector(didAddManPathFromPanel:code:context:)
         contextInfo:NULL];
}
- (void)didAddManPathFromPanel:(NSOpenPanel *)panel code:(int)returnCode context:(void *)context
{
    if (returnCode == NSOKButton)
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
#import <ApplicationServices/ApplicationServices.h>

/* Little class to store info on the possible man page viewers, for easier sorting by display name */
@interface MVAppInfo : NSObject
{
    NSString *bundleID;
    NSString *displayName;
    NSURL *appURL;
}

+ (NSArray *)allManViewerApps;
+ (void)addAppWithID:(NSString *)aBundleID sort:(BOOL)shouldResort;
+ (NSUInteger)indexOfBundleID:(NSString*)bundleID;
- (NSString *)bundleID;
- (NSString *)displayName;
- (NSURL *)appURL;

@end

@implementation MVAppInfo

#define URL_SCHEME @"x-man-page"
#define URL_SCHEME_PREFIX URL_SCHEME @":"

static NSMutableArray *allApps = nil;

- (id)initWithBundleID:(NSString *)aBundleID
{
    bundleID = [aBundleID retain];
    return self;
}

- (void)dealloc
{
    [appURL release];
    [displayName release];
    [bundleID release];
    [super dealloc];
}

- (BOOL)isEqualToBundleID:(NSString *)aBundleID
{
    return [bundleID caseInsensitiveCompare:aBundleID] == NSOrderedSame;
}
- (BOOL)isEqual:(id)other
{
    return [self isEqualToBundleID:[other bundleID]];
}
- (NSUInteger)hash
{
    return [[bundleID lowercaseString] hash];
}
- (NSComparisonResult)compareDisplayName:(id)other
{
    return [[self displayName] localizedCaseInsensitiveCompare:[other displayName]];
}

- (NSString *)bundleID
{
    return bundleID;
}

- (NSURL *)appURL
{
    if (appURL == nil)
    {
        NSString *path = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:bundleID];
        if (path != nil)
            appURL = [[NSURL fileURLWithPath:path] retain];
    }

    return appURL;
}

- (NSString *)displayName
{
    if (displayName == nil)
    {
        NSURL *url = [self appURL];
        NSDictionary *infoDict = [(id)CFBundleCopyInfoDictionaryForURL((CFURLRef)url) autorelease];
        NSString *appVersion;
        NSString *niceName = nil;

        if (infoDict == nil)
            infoDict = [[NSBundle bundleWithPath:[url path]] infoDictionary];
        
        LSCopyDisplayNameForURL((CFURLRef)url, (CFStringRef*)&niceName);
        [niceName autorelease];
        if (niceName == nil)
            niceName = [[url path] lastPathComponent];
        
        appVersion = [infoDict objectForKey:@"CFBundleShortVersionString"];
        if (appVersion != nil)
            niceName = [NSString stringWithFormat:@"%@ (%@)", niceName, appVersion];

        displayName = [niceName retain];
    }
    
    return displayName;
}

+ (void)sortApps
{
    [allApps sortUsingSelector:@selector(compareDisplayName:)];
}
+ (void)addAppWithID:(NSString *)aBundleID sort:(BOOL)shouldResort
{
    MVAppInfo *info = [[MVAppInfo alloc] initWithBundleID:aBundleID];
    if (![allApps containsObject:info])
    {
        [allApps addObject:info];
        if (shouldResort)
            [self sortApps];
    }
    [info release];
}

+ (NSArray *)allManViewerApps
{
    if (allApps == nil)
    {
        /* Ensure our app is registered */
//        NSString *appPath = [[NSBundle mainBundle] bundlePath];
//        NSURL *url = [NSURL fileURLWithPath:appPath];
//        LSRegisterURL((CFURLRef)url, false);
        
        NSArray *allBundleIDs = [(id)LSCopyAllHandlersForURLScheme((CFStringRef)URL_SCHEME) autorelease];
        NSUInteger i;

        allApps = [[NSMutableArray alloc] initWithCapacity:[allBundleIDs count]];
        for (i = 0; i<[allBundleIDs count]; i++) {
            [self addAppWithID:[allBundleIDs objectAtIndex:i] sort:NO];
        }        
        [self sortApps];
    }
    
    return allApps;
}

+ (NSUInteger)indexOfBundleID:(NSString*)bundleID
{
    NSArray *apps = [self allManViewerApps];
    NSUInteger i, count = [apps count];

    for (i=0; bundleID != nil && i<count; i++) {
        if ([[apps objectAtIndex:i] isEqualToBundleID:bundleID])
            return i;
    }

    return NSNotFound;
}

@end

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

        [image setScalesWhenResized:YES];
        [image setSize:NSMakeSize(16, 16)];
        [[appPopup itemAtIndex:i] setImage:image];
        [image release];
    }

    if ([apps count] > 0)
        [[appPopup menu] addItem:[NSMenuItem separatorItem]];
    [appPopup addItemWithTitle:@"Select... "];
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
        [panel beginSheetForDirectory:nil file:nil types:[NSArray arrayWithObject:@"app"]
                       modalForWindow:[appPopup window] modalDelegate:self
                       didEndSelector:@selector(panelDidEnd:code:context:) contextInfo:NULL];
    }
}

- (void)panelDidEnd:(NSOpenPanel *)panel code:(int)returnCode context:(void *)context
{
    if (returnCode == NSOKButton) {
        NSURL *appURL = [panel URL];
        NSString *appID = [[NSBundle bundleWithPath:[appURL path]] bundleIdentifier];
        if (appID != nil)
            [self setManPageViewer:appID];
    }
    [self setAppPopupToCurrent];
}
@end
