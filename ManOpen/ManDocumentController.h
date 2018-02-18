
#import "SystemType.h"
#import <AppKit/NSDocumentController.h>


@class NSPanel, NSTextField, NSPopUpButton, NSFont;
@class NSData, NSMutableString;


@interface ManDocumentController : NSDocumentController
{
    IBOutlet NSPanel *openTextPanel;
    IBOutlet NSPanel *aproposPanel;
    IBOutlet NSPanel *infoPanel;
    IBOutlet NSPanel *helpPanel;
    IBOutlet NSTextField *aproposField;
    IBOutlet NSTextField *openTextField;
    IBOutlet NSPopUpButton *openSectionPopup;
    BOOL startedUp;
    NSArray *docControllerObjects;
}

- (id)openWord:(NSString *)word;

- (void)openString:(NSString *)string;
- (void)openString:(NSString *)string oneWordOnly:(BOOL)oneOnly;

- (void)openFile:(NSString *)filename
    forceToFront:(BOOL)force;

- (void)openName:(NSString *)name
         section:(NSString *)section
         manPath:(NSString *)manPath
    forceToFront:(BOOL)force;

- (void)openApropos:(NSString *)apropos;

- (void)openApropos:(NSString *)apropos
            manPath:(NSString *)manPath
       forceToFront:(BOOL)force;

- (IBAction)openSection:(id)sender;
- (IBAction)openTextPanel:(id)sender;
- (IBAction)openAproposPanel:(id)sender;
- (IBAction)okApropos:(id)sender;
- (IBAction)okText:(id)sender;
- (IBAction)cancelText:(id)sender;

- (IBAction)orderFrontHelpPanel:(id)sender;
- (IBAction)orderFrontPreferencesPanel:(id)sender;

// Helper methods for document classes
- (NSMutableString *)manCommandWithManPath:(NSString *)manPath;
- (NSData *)dataByExecutingCommand:(NSString *)command;
- (NSData *)dataByExecutingCommand:(NSString *)command manPath:(NSString *)manPath;
- (NSString *)typeFromFilename:(NSString *)filename;

@end
