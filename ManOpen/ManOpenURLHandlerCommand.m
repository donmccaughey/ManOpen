#import "ManOpenURLHandlerCommand.h"

#import "FileURLComponents.h"
#import "ManDocumentController.h"
#import "ManOpenURLComponents.h"
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
    [_manDocumentController release];
    [super dealloc];
}

- (id)performDefaultImplementation
{
    NSURL *url = [NSURL URLWithString:self.directParameter];
    
    if (url.isManOpenScheme) {
        ManOpenURLComponents *components = [[[ManOpenURLComponents alloc] initWithURL:url] autorelease];
        if (components.manPage) {
            [_manDocumentController openString:components.manPage.description];
        } else if (components.aproposKeyword) {
            [_manDocumentController openApropos:components.aproposKeyword
                                        manPath:components.manPath
                                   forceToFront:!components.isBackground];
        } else if (components.filePath) {
            [_manDocumentController openFile:components.filePath
                                forceToFront:!components.isBackground];
        }
    } else if (url.isXManPageScheme) {
        XManPageURLComponents *components = [[[XManPageURLComponents alloc] initWithURL:url] autorelease];
        if (components.aproposKeyword) {
            [_manDocumentController openApropos:components.aproposKeyword
                                        manPath:nil
                                   forceToFront:YES];
        } else if (components.manPages.count) {
            NSString *string = [[components.manPages valueForKey:@"description"] componentsJoinedByString:@" "];
            [_manDocumentController openString:string];
        }
    } else if (url.isFileScheme) {
        FileURLComponents *components = [[[FileURLComponents alloc] initWithURL:url] autorelease];
        if (components.isLocalhost && components.isAbsolute && !components.isDirectory) {
            [_manDocumentController openFile:components.path
                                forceToFront:YES];
        }
    }
    
    return nil;
}

@end
