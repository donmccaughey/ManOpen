 
#import "FindPanelController.h"
#import <stdlib.h>
#import <Foundation/NSString.h>
#import <Foundation/NSException.h>
#import <Foundation/NSArray.h>
#import <AppKit/NSText.h>
#import <AppKit/NSPasteboard.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSTextField.h>
#import <AppKit/NSButton.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSMenuItem.h>
#import <AppKit/NSColor.h>
#import "ManDocumentController.h"
#import "ManDocument.h"

@interface NSText (Search)
- (BOOL)findString:(NSString *)aString
        ignoreCase:(BOOL)ignoreCase
         backwards:(BOOL)backwards
              wrap:(BOOL)wrap;
@end

@interface FindPanelController (Private)
- (BOOL)searchGoingBackwards:(BOOL)backwards;
- (void)_findNext:(id)sender;
- (void)_findPrevious:(id)sender;
- (void)_findEnter:(id)sender;
@end

@implementation FindPanelController

+ (id)allocWithZone:(NSZone *)aZone
{
    return [self sharedInstance];
}

+ (id)sharedInstance
{
    static id instance = nil;

    if (instance == nil) {
        instance = [[super allocWithZone:NULL] initWithWindowNibName:@"FindPanel"];
		[instance setWindowFrameAutosaveName:@"Find Panel"];
		[instance setShouldCascadeWindows:NO];
	}

    return instance;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    [nextButton setTarget:self];
    [nextButton setAction:@selector(_findNext:)];
    [previousButton setTarget:self];
    [previousButton setAction:@selector(_findPrevious:)];
    [stringField setTarget:self];
    [stringField setAction:@selector(_findEnter:)];
    [statusField setTextColor:[NSColor controlShadowColor]];
    [statusField setStringValue:@""];
    [[self window] useOptimizedDrawing:YES];
}

- (void)showWindow:(id)sender
{
    [super showWindow:sender];
    [stringField setStringValue:[self stringFromFindPasteboard]];
    [stringField selectText:self];
}

- (IBAction)findNext:(id)sender
{
    if ([self isWindowLoaded] && [[self window] isVisible])
        [nextButton performClick:sender];
    else
        [self _findNext:sender];
}

- (IBAction)findPrevious:(id)sender
{
    if ([self isWindowLoaded] && [[self window] isVisible])
        [previousButton performClick:sender];
    else
        [self _findPrevious:sender];
}

- (IBAction)jumpToSelection:(id)sender
{
    NSText *theText = [self targetText];
    [theText scrollRangeToVisible:[theText selectedRange]];
}

- (IBAction)enterSelection:(id)sender
{
    NSString *string = [self stringFromTargetText];;

    if ([self isWindowLoaded] && [[NSApplication sharedApplication] keyWindow] == [self window])
        return;

    if ([string length] == 0)
    {
        NSBeep();
        return;
    }

    [self saveStringToFindPasteboard:string];
    [stringField setStringValue:string];
    [stringField selectText:self];
}

- (NSText *)targetText
{
    id document = [[NSDocumentController sharedDocumentController] currentDocument];
    if ([document respondsToSelector:@selector(textView)])
        return [document textView];
    return nil;
}

- (void)saveStringToFindPasteboard:(NSString *)aString
{
    NSPasteboard *findPasteboard = [NSPasteboard pasteboardWithName:NSFindPboard];

    if ([aString length] == 0) return;

    NS_DURING
        [findPasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
        [findPasteboard setString:aString forType:NSStringPboardType];
    NS_HANDLER
    NS_ENDHANDLER;
}

- (NSString *)stringFromFindPasteboard
{
    NSPasteboard *findPasteboard = [NSPasteboard pasteboardWithName:NSFindPboard];
    NSString     *string = @"";

    NS_DURING
        if ([[findPasteboard types] containsObject:NSStringPboardType])
            string = [findPasteboard stringForType:NSStringPboardType];
    NS_HANDLER
        string = @"";
    NS_ENDHANDLER;

    return string;
}

- (NSString *)stringFromTargetText
{
    NSText   *theText = [self targetText];
    NSRange  selectedRange = [theText selectedRange];

    return (selectedRange.length == 0)? nil : [[theText string] substringWithRange:selectedRange];
}

- (NSString *)searchString
{
    if ([self isWindowLoaded] && [[self window] isVisible])
    {
        NSString *string = [stringField stringValue];
        if ([string length] > 0)
            return string;
    }

    return [self stringFromFindPasteboard];
}

- (BOOL)searchGoingBackwards:(BOOL)backwards
{
    NSString *string = [self searchString];
    NSText   *targetText = [self targetText];

    if ([string length] == 0 || targetText == nil)
    {
        if (targetText == nil)
            [statusField setStringValue:@"Nothing to search"];
        return NO;
    }

    [self saveStringToFindPasteboard:string];
    [stringField selectText:self];

    if ([targetText findString:string ignoreCase:[ignoreCaseButton state]
                     backwards:backwards wrap:YES])
    {
        [[targetText window] makeFirstResponder:targetText]; //make sure selection shows
        [statusField setStringValue:@""];
        return YES;
    }
    else
    {
        NSBeep();
        [statusField setStringValue:@"Not found"];
        return NO;
    }
}

- (void)_findNext:(id)sender
{
    [self searchGoingBackwards:NO];
}

- (void)_findPrevious:(id)sender
{
    [self searchGoingBackwards:YES];
}

- (void)_findEnter:(id)sender
{
    if ([self searchGoingBackwards:NO])
        [[self window] orderOut:sender];
}

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
    if ([item action] == @selector(enterSelection:) ||
        [item action] == @selector(jumpToSelection:))
    {
        NSText *targetText = [self targetText];
        return targetText != nil && [targetText selectedRange].length > 0;
    }
    if ([item action] == @selector(findPrevious:) ||
        [item action] == @selector(findNext:))
    {
        return [[self searchString] length] > 0;
    }
    return YES;
}

@end

/*
 * The obsolete NSCStringText has a similar method, which is very handy for
 * find panel usage, so we implement it on NSText.
 */
@implementation NSText (Search)

- (BOOL)findString:(NSString *)aString
        ignoreCase:(BOOL)ignoreCase
         backwards:(BOOL)backwards
              wrap:(BOOL)wrap
{
    NSString *searchText = [self string];
    NSRange  selectedRange = [self selectedRange];
    NSRange  beforeRange, afterRange, searchRange, foundRange;
    NSStringCompareOptions mask = 0;

    beforeRange = NSMakeRange(0, selectedRange.location);
    afterRange.location = NSMaxRange(selectedRange);
    afterRange.length = [searchText length] - afterRange.location;

    if (ignoreCase) mask |= NSCaseInsensitiveSearch;
    if (backwards)  mask |= NSBackwardsSearch;

    searchRange = (backwards)? beforeRange : afterRange;
    foundRange  = [searchText rangeOfString:aString options:mask range:searchRange];

    if (foundRange.length == 0 && wrap)
    {
        searchRange = (backwards)? afterRange : beforeRange;
        foundRange  = [searchText rangeOfString:aString options:mask range:searchRange];
    }

    if (foundRange.length > 0)
    {
        [self setSelectedRange:foundRange];
        [self scrollRangeToVisible:foundRange];
        return YES;
    }

    return NO;
}

@end
