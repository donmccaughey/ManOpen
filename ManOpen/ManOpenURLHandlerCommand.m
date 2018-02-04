#import "ManOpenURLHandlerCommand.h"

#import "FileURLComponents.h"
#import "ManDocumentController.h"
#import "ManPage.h"
#import "NSURL+ManOpen.h"
#import "XManPageURLComponents.h"


@implementation ManOpenURLHandlerCommand

- (instancetype)init
{
    self = [super init];
    if (self) {
        _manDocumentController = [[ManDocumentController sharedDocumentController] retain];
    }
    return self;
}

- (instancetype)initWithCommandDescription:(NSScriptCommandDescription *)commandDef
{
    self = [super initWithCommandDescription:commandDef];
    if (self) {
        _manDocumentController = [[ManDocumentController sharedDocumentController] retain];
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
    [_manDocumentController release];
}

- (id)performDefaultImplementation
{
    NSURL *url = [NSURL URLWithString:self.directParameter];
    
    if (url.isXManPageScheme) {
        XManPageURLComponents *components = [[XManPageURLComponents alloc] initWithURL:url];
        if (components.aproposKeyword) {
            [_manDocumentController openApropos:components.aproposKeyword];
        } else if (components.manPages.count) {
            NSString *string = [[components.manPages valueForKey:@"description"] componentsJoinedByString:@" "];
            [_manDocumentController openString:string];
        }
    } else if (url.isFileScheme) {
        FileURLComponents *components = [[FileURLComponents alloc] initWithURL:url];
        if (components.isLocalhost && components.isAbsolute && !components.isDirectory) {
            [_manDocumentController openFile:components.path
                                forceToFront:YES];
        }
    }
    
    return nil;
}

@end
