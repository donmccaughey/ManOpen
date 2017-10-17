/* AproposDocument.m created by lindberg on Tue 10-Oct-2000 */

#import "AproposDocument.h"
#import <AppKit/AppKit.h>
#import "ManDocumentController.h"
#import "PrefPanelController.h"

@interface NSDocument (LionRestorationMethods)
- (void)encodeRestorableStateWithCoder:(NSCoder *)coder;
- (void)restoreStateWithCoder:(NSCoder *)coder;
@end

@implementation AproposDocument

+ (BOOL)canConcurrentlyReadDocumentsOfType:(NSString *)typeName
{
    return YES;
}

- (void)_loadWithString:(NSString *)apropos manPath:(NSString *)manPath title:(NSString *)aTitle
{
    ManDocumentController *docController = [ManDocumentController sharedDocumentController];
    NSMutableString *command = [docController manCommandWithManPath:manPath];
    NSData *output;
    
    titles = [[NSMutableArray alloc] init];
    descriptions = [[NSMutableArray alloc] init];
    title = [aTitle retain];
    [self setFileType:@"apropos"];

    /* Searching for a blank string doesn't work anymore... use a catchall regex */
    if ([apropos length] == 0)
        apropos = @".";
    searchString = [apropos retain];

    /*
     * Starting on Tiger, man -k doesn't quite work the same as apropos directly.
     * Use apropos then, even on Panther.  Panther/Tiger no longer accept the -M
     * argument, so don't try... we set the MANPATH environment variable, which
     * gives a warning on Panther (stderr; ignored) but not on Tiger.
     */
//    [command appendString:@" -k"];
    [command setString:@"/usr/bin/apropos"];
    
    [command appendFormat:@" %@", EscapePath(apropos, YES)];
    output = [docController dataByExecutingCommand:command manPath:manPath];
    /* The whatis database appears to not be UTF8 -- at least, UTF8 can fail, even on 10.7 */
    [self parseOutput:[[[NSString alloc] initWithData:output encoding:NSMacOSRomanStringEncoding] autorelease]];
}

- (id)initWithString:(NSString *)apropos manPath:(NSString *)manPath title:(NSString *)aTitle
{
    [super init];
    [self _loadWithString:apropos manPath:manPath title:aTitle];
    
    if ([titles count] == 0) {
        NSRunAlertPanel(@"Nothing found", @"No pages related to '%@' found", nil, nil, nil, apropos);
        [self release];
        return nil;
    }

    return self;
}

- (void)dealloc
{
    [title release];
    [titles release];
    [descriptions release];
    [searchString release];
    [super dealloc];
}

- (NSString *)windowNibName
{
    return @"Apropos";
}

- (NSString *)displayName
{
    return title;
}

- (void)windowControllerDidLoadNib:(NSWindowController *)windowController
{
    NSString *sizeString = [[NSUserDefaults standardUserDefaults] stringForKey:@"AproposWindowSize"];

    [super windowControllerDidLoadNib:windowController];

    if (sizeString != nil)
    {
        NSSize windowSize = NSSizeFromString(sizeString);
        NSWindow *window = [tableView window];
        NSRect frame = [window frame];

        if (windowSize.width > 30.0 && windowSize.height > 30.0) {
            frame.size = windowSize;
            [window setFrame:frame display:NO];
        }
    }

    [tableView setTarget:self];
    [tableView setDoubleAction:@selector(openManPages:)];
    [tableView sizeLastColumnToFit];
}

- (void)parseOutput:(NSString *)output
{
    NSArray *lines = [output componentsSeparatedByString:@"\n"];
    NSUInteger i, count = [lines count];

    if ([output length] == 0) return;

    lines = [lines sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    
    for (i=0; i<count; i++)
    {
        NSString *line = [lines objectAtIndex:i];
        NSRange dashRange;

        if ([line length] == 0) continue;

        dashRange = [line rangeOfString:@"\t\t- "]; //OPENSTEP
        if (dashRange.length == 0)
            dashRange = [line rangeOfString:@"\t- "]; //OPENSTEP
        if (dashRange.length == 0)
            dashRange = [line rangeOfString:@"\t-" options:NSBackwardsSearch|NSAnchoredSearch];
        if (dashRange.length == 0)
            dashRange = [line rangeOfString:@" - "]; //MacOSX
        if (dashRange.length == 0)
            dashRange = [line rangeOfString:@" -" options:NSBackwardsSearch|NSAnchoredSearch];

        if (dashRange.length == 0) continue;

        [titles addObject:[line substringToIndex:dashRange.location]];
        [descriptions addObject:[line substringFromIndex:NSMaxRange(dashRange)]];
    }
}

- (IBAction)saveCurrentWindowSize:(id)sender
{
    NSSize size = [[tableView window] frame].size;
    [[NSUserDefaults standardUserDefaults] setObject:NSStringFromSize(size) forKey:@"AproposWindowSize"];
}

- (IBAction)openManPages:(id)sender
{
    if ([sender clickedRow] >= 0) {
        NSString *manPage = [titles objectAtIndex:[sender clickedRow]];
        [[ManDocumentController sharedDocumentController] openString:manPage oneWordOnly:YES];
    }
}

- (void)printShowingPrintPanel:(BOOL)showPanel
{
    NSPrintOperation *op = [NSPrintOperation printOperationWithView:tableView];
    [op setShowsPrintPanel:showPanel];
    [op setShowsProgressPanel:showPanel];
    [op runOperationModalForWindow:[tableView window] delegate:nil didRunSelector:NULL contextInfo:NULL];
}

/* NSTableView dataSource */
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [titles count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSArray *strings = (tableColumn == titleColumn)? titles : descriptions;
    return [strings objectAtIndex:row];
}

/* Document restoration */
#define RestoreSearchString @"SearchString"
#define RestoreTitle @"Title"

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];
    [coder encodeObject:searchString forKey:RestoreSearchString];
    [coder encodeObject:title forKey:RestoreTitle];
}

- (void)restoreStateWithCoder:(NSCoder *)coder
{
    [super restoreStateWithCoder:coder];
    
    if (![coder containsValueForKey:RestoreSearchString])
        return;
    
    NSString *search = [coder decodeObjectForKey:RestoreSearchString];
    NSString *theTitle = [coder decodeObjectForKey:RestoreTitle];
    NSString *manPath = [[NSUserDefaults standardUserDefaults] manPath];
    
    [self _loadWithString:search manPath:manPath title:theTitle];
    [[self windowControllers] makeObjectsPerformSelector:@selector(synchronizeWindowTitleWithDocumentName)];
    [tableView reloadData];
}

@end
