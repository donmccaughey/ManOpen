
#import "ManDocument.h"
#import <AppKit/AppKit.h>
#import "ManDocumentController.h"
#import "PrefPanelController.h"
#import "NSData+Utils.h"


@interface ManTextView : NSTextView
- (void)scrollRangeToTop:(NSRange)charRange;
@end

#define RestoreWindowDict @"RestoreWindowInfo"
#define RestoreSection    @"Section"
#define RestoreTitle      @"Title"
#define RestoreName       @"Name"
#define RestoreFileURL    @"URL"
#define RestoreFileType   @"DocType"
@interface NSDocument (LionRestorationMethods)
- (void)encodeRestorableStateWithCoder:(NSCoder *)coder;
- (void)restoreStateWithCoder:(NSCoder *)coder;
@end


@implementation ManDocument

+ (BOOL)canConcurrentlyReadDocumentsOfType:(NSString *)typeName
{
    return YES;
}

- (void)_loadDocumentWithName:(NSString *)name
                      section:(NSString *)section
                      manPath:(NSString *)manPath
                        title:(NSString *)title
{
    ManDocumentController *docController = [ManDocumentController sharedDocumentController];
    NSMutableString *command = [docController manCommandWithManPath:manPath];
    
    [self setFileType:@"man"];
    [self setShortTitle:title];
    
    if (section && [section length] > 0)
    {
        [command appendFormat:@" %@", [section lowercaseString]];
        copyURL = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"x-man-doc://%@/%@", section, title]];
    }
    else
    {
        copyURL = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"x-man-doc://%@", title]];
    }
    
    restoreData = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                   name,    RestoreName,
                   title,   RestoreTitle,
                   section, RestoreSection,
                   nil];
    
    [command appendFormat:@" %@", name];
    
    [self loadCommand:command];
}

- initWithName:(NSString *)name
	section:(NSString *)section
	manPath:(NSString *)manPath
	title:(NSString *)title
{
    [super init];
    [self _loadDocumentWithName:name section:section manPath:manPath title:title];
    return self;
}

- (void)dealloc
{
    [taskData release];
    [copyURL release];
    [shortTitle release];
    [sections release];
    [restoreData release];
    [super dealloc];
}

- (NSString *)windowNibName
{
    return @"ManPage";
}

/*
 * Standard NSDocument method.  We only want to override if we aren't
 * representing an actual file.
 */
- (NSString *)displayName
{
    return ([self fileURL] != nil)? [super displayName] : [self shortTitle];
}

- (NSString *)shortTitle
{
    return shortTitle;
}

- (void)setShortTitle:(NSString *)aString
{
    [shortTitle autorelease];
    shortTitle = [aString retain];
}

- (NSText *)textView
{
    return textView;
}

- (void)setupSectionPopup
{
    [sectionPopup removeAllItems];
    [sectionPopup addItemWithTitle:@"Section:"];
    [sectionPopup setEnabled:[sections count] > 0];

    if ([sectionPopup isEnabled])
        [sectionPopup addItemsWithTitles:sections];
}

- (void)addSectionHeader:(NSString *)header range:(NSRange)range
{
    /* Make sure it is a header -- error text sometimes is not Courier, so it gets passed in here. */
    if ([header rangeOfCharacterFromSet:[NSCharacterSet uppercaseLetterCharacterSet]].length > 0 &&
        [header rangeOfCharacterFromSet:[NSCharacterSet lowercaseLetterCharacterSet]].length == 0)
    {
        NSString *label = header;
        int count = 1;

        /* Check for dups (e.g. lesskey(1) ) */
        while ([sections containsObject:label]) {
            count++;
            label = [NSString stringWithFormat:@"%@ [%d]", header, count];
        }

        [sections addObject:label];
        [sectionRanges addObject:[NSValue valueWithRange:range]];
    }
}

- (void)showData
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSTextStorage *storage = nil;
    NSFont        *manFont = [defaults manFont];
    NSColor       *linkColor = [defaults manLinkColor];
    NSColor       *textColor = [defaults manTextColor];
    NSColor       *backgroundColor = [defaults manBackgroundColor];

    if (textView == nil || hasLoaded) return;

    if ([taskData isRTFData])
    {
        storage = [[NSTextStorage alloc] initWithRTF:taskData documentAttributes:NULL];
    }
    else if (taskData != nil)
    {
        storage = [[NSTextStorage alloc] initWithHTML:taskData documentAttributes:NULL];
    }

    if (storage == nil)
        storage = [[NSTextStorage alloc] init];

    if ([[storage string] rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]].length == 0)
    {
        [[storage mutableString] setString:@"\nNo manual entry."];
    }

    if (sections == nil) {
        sections = [[NSMutableArray alloc] init];
        sectionRanges = [[NSMutableArray alloc] init];
    }
    [sections removeAllObjects];
    [sectionRanges removeAllObjects];
    
    /* Convert the attributed string to use the user's chosen font and text color */
    if (storage != nil)
    {
        NSFontManager *manager = [NSFontManager sharedFontManager];
        NSString      *family = [manFont familyName];
        CGFloat       size    = [manFont pointSize];
        NSUInteger    currIndex = 0;

        NS_DURING
        [storage beginEditing];

        while (currIndex < [storage length])
        {
            NSRange currRange;
            NSDictionary *attribs = [storage attributesAtIndex:currIndex effectiveRange:&currRange];
            NSFont       *font = [attribs objectForKey:NSFontAttributeName];
            BOOL isLink = NO;

            /* We mark "sections" with Helvetica fonts */
            if (font != nil && ![[font familyName] isEqualToString:@"Courier"]) {
                [self addSectionHeader:[[storage string] substringWithRange:currRange] range:currRange];
            }

            isLink = ([attribs objectForKey:NSLinkAttributeName] != nil);

            if (font != nil && ![[font familyName] isEqualToString:family])
                font = [manager convertFont:font toFamily:family];
            if (font != nil && [font pointSize] != size)
                font = [manager convertFont:font toSize:size];
            if (font != nil)
                [storage addAttribute:NSFontAttributeName value:font range:currRange];

            /*
             * Starting in 10.3, there is a -setLinkTextAttributes: method to set these, without having to
             * determine the ranges ourselves.  However, since we are already iterating all the ranges
             * for other reasons, may as well keep the old way.
             */
            if (isLink)
                [storage addAttribute:NSForegroundColorAttributeName value:linkColor range:currRange];
            else
                [storage addAttribute:NSForegroundColorAttributeName value:textColor range:currRange];
            
            currIndex = NSMaxRange(currRange);
        }

        [storage endEditing];
        NS_HANDLER
        NSLog(@"Exception during formatting: %@", localException);
        NS_ENDHANDLER

        [[textView layoutManager] replaceTextStorage:storage];
        [[textView window] invalidateCursorRectsForView:textView];
        [storage release];
    }

    [textView setBackgroundColor:backgroundColor];
    [self setupSectionPopup];
    
    /*
     * The 10.7 document reloading stuff can cause the loading methods to be invoked more than
     * once, and the second time through we have thrown away our raw data.  Probably indicates
     * some overkill code elsewhere on my part, but putting in the hadLoaded guard to only
     * avoid doing anything after we have loaded real data seems to help.
     */
    if (taskData != nil)
        hasLoaded = YES;

    // no need to keep around rtf data
    [taskData release];
    taskData = nil;
    [pool release];
}

- (NSString *)filterCommand
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    /* HTML parser in tiger got slow... RTF is faster, and is usable now that it supports hyperlinks */
    //    NSString *tool = @"cat2html";
    NSString *tool = @"cat2rtf";
    NSString *command = [[NSBundle mainBundle] pathForResource:tool ofType:nil];

    command = EscapePath(command, YES);
    command = [command stringByAppendingString:@" -lH"]; // generate links, mark headers
    if ([defaults boolForKey:@"UseItalics"])
        command = [command stringByAppendingString:@" -i"];
    if (![defaults boolForKey:@"UseBold"])
        command = [command stringByAppendingString:@" -g"];

    return command;
}

- (void)loadCommand:(NSString *)command
{
    ManDocumentController *docController = [ManDocumentController sharedDocumentController];
    NSString *fullCommand = [NSString stringWithFormat:@"%@ | %@", command, [self filterCommand]];

    [taskData release];
    taskData = nil;
    taskData = [[docController dataByExecutingCommand:fullCommand] retain];

    [self showData];
}

- (void)loadManFile:(NSString *)filename isGzip:(BOOL)isGzip
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *nroffFormat = [defaults stringForKey:@"NroffCommand"];
    NSString *nroffCommand;
    BOOL     hasQuote = ([nroffFormat rangeOfString:@"'%@'"].length > 0);

    /* If Gzip, change the command into a filter of the output of gzcat.  I'm
       getting the feeling that the customizable nroff command is more trouble
       than it's worth, especially now that OSX uses the good version of gnroff */
    if (isGzip)
    {
        NSString *repl = hasQuote? @"'%@'" : @"%@";
        NSRange replRange = [nroffFormat rangeOfString:repl];
        if (replRange.length > 0) {
            NSMutableString *formatCopy = [[nroffFormat mutableCopy] autorelease];
            [formatCopy replaceCharactersInRange:replRange withString:@""];
            nroffFormat = [NSString stringWithFormat:@"/usr/bin/gzip -dc %@ | %@", repl, formatCopy];
        }
    }
    
    nroffCommand = [NSString stringWithFormat:nroffFormat, EscapePath(filename, !hasQuote)];
    [self loadCommand:nroffCommand];
}

- (void)loadCatFile:(NSString *)filename isGzip:(BOOL)isGzip
{
    NSString *binary = isGzip? @"/usr/bin/gzip -dc" : @"/bin/cat";
    [self loadCommand:[NSString stringWithFormat:@"%@ '%@'", binary, EscapePath(filename, NO)]];
}

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)type error:(NSError **)error
{
    if ([type isEqual:@"man"])
        [self loadManFile:[url path] isGzip:NO];
    else if ([type isEqual:@"mangz"])
        [self loadManFile:[url path] isGzip:YES];
    else if ([type isEqual:@"cat"])
        [self loadCatFile:[url path] isGzip:NO];
    else if ([type isEqual:@"catgz"])
        [self loadCatFile:[url path] isGzip:YES];
    else {
        NSDictionary *errorDetail = [NSDictionary dictionaryWithObject:@"Invalid document type" forKey:NSLocalizedDescriptionKey];
        if (error != NULL)
            *error = [NSError errorWithDomain:@"ManOpen" code:0 userInfo:errorDetail];
        return NO;
    }

    // strip extension twice in case it is a e.g. "1.gz" filename
    [self setShortTitle:[[[[url path] lastPathComponent] stringByDeletingPathExtension] stringByDeletingPathExtension]];
    copyURL = [url retain];
    
    restoreData = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                   url,    RestoreFileURL,
                   type,   RestoreFileType,
                   nil];

    if (taskData == nil)
    {
        NSDictionary *errorDetail = [NSDictionary dictionaryWithObject:@"Could not read manual data" forKey:NSLocalizedDescriptionKey];
        if (error != NULL)
            *error = [NSError errorWithDomain:@"ManOpen" code:0 userInfo:errorDetail];
        return NO;
    }

    return YES;
}

- (void)windowControllerDidLoadNib:(NSWindowController *)windowController
{
    NSString *sizeString = [[NSUserDefaults standardUserDefaults] stringForKey:@"ManWindowSize"];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [super windowControllerDidLoadNib:windowController];

    [textView setEditable:NO];
    [textView setSelectable:YES];
    [textView setImportsGraphics:NO];
    [textView setRichText:YES];
    [textView setUsesFindPanel:YES];

    if (sizeString != nil)
    {
        NSSize windowSize = NSSizeFromString(sizeString);
        NSWindow *window = [textView window];
        NSRect frame = [window frame];

        if (windowSize.width > 30.0 && windowSize.height > 30.0) {
            frame.size = windowSize;
            [window setFrame:frame display:NO];
        }
    }

    if ([self shortTitle] != nil)
        [titleStringField setStringValue:[self shortTitle]];
    [[[textView textStorage] mutableString] setString:@"Loading..."];
    [textView setBackgroundColor:[defaults manBackgroundColor]];
    [textView setTextColor:[defaults manTextColor]];
    [self performSelector:@selector(showData) withObject:nil afterDelay:0.0];

    [[textView window] makeFirstResponder:textView];
    [[textView window] setDelegate:self];
}

- (IBAction)openSelection:(id)sender
{
    NSRange selectedRange = [textView selectedRange];

    if (selectedRange.length > 0)
    {
        NSString *selectedString = [[textView string] substringWithRange:selectedRange];
        [[ManDocumentController sharedDocumentController] openString:selectedString];
    }
    [[textView window] makeFirstResponder:textView];
}

- (IBAction)displaySection:(id)sender
{
    NSInteger section = [sectionPopup indexOfSelectedItem];
    if (section > 0 && section <= [sectionRanges count]) {
        NSRange range = [[sectionRanges objectAtIndex:section-1] rangeValue];
        [textView scrollRangeToTop:range];
    }
}

- (IBAction)copyURL:(id)sender
{
    if (copyURL != nil)
    {
        NSPasteboard *pb = [NSPasteboard generalPasteboard];
        NSMutableArray *types = [NSMutableArray array];
        
        [types addObject:NSURLPboardType];
        if ([copyURL isFileURL])
            [types addObject:NSFilenamesPboardType];
        [types addObject:NSStringPboardType];
        [pb declareTypes:types owner:nil];

        [copyURL writeToPasteboard:pb];
        [pb setString:[NSString stringWithFormat:@"<%@>", [copyURL absoluteString]] forType:NSStringPboardType];
        if ([copyURL isFileURL])
            [pb setPropertyList:[NSArray arrayWithObject:[copyURL path]] forType:NSFilenamesPboardType];
    }
}

- (IBAction)saveCurrentWindowSize:(id)sender
{
    NSSize size = [[textView window] frame].size;
    [[NSUserDefaults standardUserDefaults] setObject:NSStringFromSize(size) forKey:@"ManWindowSize"];
}

/* Always use global page layout */
- (IBAction)runPageLayout:(id)sender
{
    [[NSApplication sharedApplication] runPageLayout:sender];
}

- (void)printShowingPrintPanel:(BOOL)showPanel
{
    NSPrintOperation *operation = [NSPrintOperation printOperationWithView:textView];
    NSPrintInfo      *printInfo = [operation printInfo];

    [printInfo setVerticallyCentered:NO];
    [printInfo setHorizontallyCentered:YES];
    [printInfo setHorizontalPagination:NSFitPagination];
    [operation setShowsPrintPanel:showPanel];
    [operation setShowsProgressPanel:showPanel];

    [operation runOperationModalForWindow:[textView window] delegate:nil didRunSelector:NULL contextInfo:NULL];
}

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
    if ([item action] == @selector(copyURL:))
        return copyURL != nil;

    return [super validateMenuItem:item];
}

- (BOOL)textView:(NSTextView *)aTextView clickedOnLink:(id)link atIndex:(unsigned)charIndex
{
    NSString *page = nil;

    /* On Tiger, NSURL, Panther and before, NSString */
    if ([link isKindOfClass:[NSString class]] && [link hasPrefix:@"manpage:"])
        page = [link substringFromIndex:8];
    if ([link isKindOfClass:[NSURL class]])
        page = [link resourceSpecifier];

    if (page == nil)
        return NO;
    [[ManDocumentController sharedDocumentController] openString:page];
    return YES;
}

- (void)textView:(NSTextView *)textView clickedOnCell:(id <NSTextAttachmentCell>)cell inRect:(NSRect)cellFrame
{
    NSString *filename = nil;

    /* NSHelpAttachment stores the string in the fileName variable */
    if ([[cell attachment] respondsToSelector:@selector(fileName)])
        filename = [(id)[cell attachment] fileName];

    if ([filename hasPrefix:@"manpage:"]) {
        filename = [filename substringFromIndex:8];
        [[ManDocumentController sharedDocumentController] openString:filename];
    }
}

- (void)windowDidUpdate:(NSNotification *)notification
{
    /* Disable the Open Selection button if there's no selection to work on */
    [openSelectionButton setEnabled:([textView selectedRange].length > 0)];
}

- (BOOL)windowShouldZoom:(NSWindow *)window toFrame:(NSRect)newFrame
{
    return YES;
}

- (NSRect)windowWillUseStandardFrame:(NSWindow *)window defaultFrame:(NSRect)newFrame
{
    NSScrollView *scrollView = [textView enclosingScrollView];
    NSRect currentFrame = [window frame];
    NSRect desiredFrame;
    NSSize textSize;
    NSRect scrollRect;
    NSRect contentRect;

    /* Get the text's natural size */
    textSize = [[textView textStorage] size];
    textSize.width += ([textView textContainerInset].width * 2) + 10; //add a little extra padding
    [textView sizeToFit];
    textSize.height = NSHeight([textView frame]); //this seems to be more accurate

    /* Get the size the scrollView should be based on that */
    scrollRect.origin = NSZeroPoint;
    scrollRect.size = [NSScrollView frameSizeForContentSize:textSize
                                      hasHorizontalScroller:[scrollView hasHorizontalScroller]
                                        hasVerticalScroller:[scrollView hasVerticalScroller]
                                                 borderType:[scrollView borderType]];

    /* Get the window's content size -- basically the scrollView size plus our title area */
    contentRect = scrollRect;
    contentRect.size.height += NSHeight([[window contentView] frame]) - NSHeight([scrollView frame]);

    /* Get the desired window frame size */
    desiredFrame = [NSWindow frameRectForContentRect:contentRect styleMask:[window styleMask]];

    /* Set the origin based on window's current location */
    desiredFrame.origin.x = currentFrame.origin.x;
    desiredFrame.origin.y = NSMaxY(currentFrame) - NSHeight(desiredFrame);

    /* NSWindow will clip this rect to the actual available screen area */
    return desiredFrame;
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];
    [coder encodeObject:restoreData forKey:RestoreWindowDict];
}

- (void)restoreStateWithCoder:(NSCoder *)coder
{
    [super restoreStateWithCoder:coder];

    if (![coder containsValueForKey:RestoreWindowDict])
        return;

    NSDictionary *restoreInfo = [coder decodeObjectForKey:RestoreWindowDict];
    if ([restoreInfo objectForKey:RestoreName] != nil)
    {
        NSString *name = [restoreInfo objectForKey:RestoreName];
        NSString *section = [restoreInfo objectForKey:RestoreSection];
        NSString *title = [restoreInfo objectForKey:RestoreTitle];
        NSString *manPath = [[NSUserDefaults standardUserDefaults] manPath];
        
        [self _loadDocumentWithName:name section:section manPath:manPath title:title];
    }
    /* Usually, URL-backed documents have been automatically restored already
       (the copyURL would be set), but just in case... */
    else if ([restoreInfo objectForKey:RestoreFileURL] != nil && copyURL == nil)
    {
        NSURL *url = [restoreInfo objectForKey:RestoreFileURL];
        NSString *type  = [restoreInfo objectForKey:RestoreFileType];
        [self readFromURL:url ofType:type error:NULL];
    }

    if ([self shortTitle] != nil)
        [titleStringField setStringValue:[self shortTitle]];
    [[self windowControllers] makeObjectsPerformSelector:@selector(synchronizeWindowTitleWithDocumentName)];
}

@end


@implementation ManTextView

static NSCursor *linkCursor = nil;

+ (void)initialize
{
    NSImage *linkImage;
    NSString *path;

    path = [[NSBundle mainBundle] pathForResource:@"LinkCursor" ofType:@"tiff"];
    linkImage = [[NSImage alloc] initWithContentsOfFile: path];
    linkCursor = [[NSCursor alloc] initWithImage:linkImage hotSpot:NSMakePoint(6.0f, 1.0f)];
    [linkCursor setOnMouseEntered:YES];
    [linkImage release];
}

- (void)resetCursorRects
{
    NSTextContainer *container = [self textContainer];
    NSLayoutManager *layout    = [self layoutManager];
    NSTextStorage *storage     = [self textStorage];
    NSRect visible = [self visibleRect];
    NSUInteger currIndex = 0;

    [super resetCursorRects];

    while (currIndex < [storage length])
    {
        NSRange currRange;
        NSDictionary *attribs = [storage attributesAtIndex:currIndex effectiveRange:&currRange];
        BOOL isLinkSection = [attribs objectForKey:NSLinkAttributeName] != nil;

        if (isLinkSection)
        {
            NSRect *rects;
            NSRange ignoreRange = {NSNotFound, 0};
            NSUInteger i, rectCount = 0;

            rects = [layout rectArrayForCharacterRange:currRange
                            withinSelectedCharacterRange:ignoreRange
                            inTextContainer:container
                            rectCount:&rectCount];

            for (i=0; i<rectCount; i++)
                if (NSIntersectsRect(visible, rects[i]))
                    [self addCursorRect:rects[i] cursor:linkCursor];
        }

        currIndex = NSMaxRange(currRange);
    }
}

- (void)scrollRangeToTop:(NSRange)charRange
{
    NSLayoutManager *layout = [self layoutManager];
    NSRange glyphRange = [layout glyphRangeForCharacterRange:charRange actualCharacterRange:NULL];
    NSRect rect = [layout boundingRectForGlyphRange:glyphRange inTextContainer:[self textContainer]];
    CGFloat height = NSHeight([self visibleRect]);

    if (height > 0)
        rect.size.height = height;

    [self scrollRectToVisible:rect];
}

/* Make space page down (and shift/alt-space page up) */
- (void)keyDown:(NSEvent *)event
{
    if ([[event charactersIgnoringModifiers] isEqual:@" "])
    {
         if ([event modifierFlags] & (NSShiftKeyMask|NSAlternateKeyMask))
             [self pageUp:self];
         else
             [self pageDown:self];
    }
    else
    {
        [super keyDown:event];
    }
}

/* 
 * Draw page numbers when printing. Under early versions of MacOS X... the normal
 * NSString drawing methods don't work in the context of this method. So, I fell back on
 * CoreGraphics primitives, which did. However, I'm now just supporting Tiger (10.4) and up,
 * and it looks like the bugs have been fixed, so we can just use the higher-level
 * NSStringDrawing now, thankfully.
 */
- (void)drawPageBorderWithSize:(NSSize)size
{
    NSFont *font = [[NSUserDefaults standardUserDefaults] manFont];
    NSInteger currPage = [[NSPrintOperation currentOperation] currentPage];
    NSString *pageString = [NSString stringWithFormat:@"%d", (int)currPage];
    NSMutableParagraphStyle *style = [[[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
    NSMutableDictionary *drawAttribs = [NSMutableDictionary dictionary];
    NSRect drawRect = NSMakeRect(0.0f, 0.0f, size.width, 20.0f + [font ascender]);

    [style setAlignment:NSCenterTextAlignment];
    [drawAttribs setObject:style forKey:NSParagraphStyleAttributeName];
    [drawAttribs setObject:font forKey:NSFontAttributeName];

    [pageString drawInRect:drawRect withAttributes:drawAttribs];
    
//    CGFloat strWidth = [str sizeWithAttributes:attribs].width;
//    NSPoint point = NSMakePoint(size.width/2 - strWidth/2, 20.0f);
//    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
//    
//    CGContextSaveGState(context);
//    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
//    CGContextSetTextDrawingMode(context, kCGTextFill);  //needed?
//    CGContextSetGrayFillColor(context, 0.0f, 1.0f);
//    CGContextSelectFont(context, [[font fontName] cStringUsingEncoding:NSMacOSRomanStringEncoding], [font pointSize], kCGEncodingMacRoman);
//    CGContextShowTextAtPoint(context, point.x, point.y, [str cStringUsingEncoding:NSMacOSRomanStringEncoding], [str lengthOfBytesUsingEncoding:NSMacOSRomanStringEncoding]);
//    CGContextRestoreGState(context);
}

@end
