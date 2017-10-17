
#import "SystemType.h"
#ifdef OPENSTEP
#import "NSWindowController.h"
#else
#import <AppKit/NSWindowController.h>
#endif

@class NSText, NSTextField, NSButton;

/* This class has been obsoleted by setUsesFindPanel: in NSTextView, so we no longer use it. */
@interface FindPanelController : NSWindowController
{
    IBOutlet NSTextField *stringField;
    IBOutlet NSTextField *statusField;
    IBOutlet NSButton    *nextButton;
    IBOutlet NSButton    *previousButton;
    IBOutlet NSButton    *ignoreCaseButton;
}

+ (id)sharedInstance;

- (IBAction)findNext:(id)sender;
- (IBAction)findPrevious:(id)sender;
- (IBAction)jumpToSelection:(id)sender;
- (IBAction)enterSelection:(id)sender;

- (NSText *)targetText;

- (NSString *)searchString;
- (NSString *)stringFromTargetText;
- (NSString *)stringFromFindPasteboard;
- (void)saveStringToFindPasteboard:(NSString *)aString;


@end
