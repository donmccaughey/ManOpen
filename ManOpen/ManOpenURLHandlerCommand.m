#import "ManOpenURLHandlerCommand.h"

#import "FileURLComponents.h"
#import "ManDocumentController.h"
#import "ManPage.h"
#import "NSURL+ManOpen.h"


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
        NSString *resourceSpecifier = url.resourceSpecifier;
        
        NSString *aproposSuffix = @";type=a";
        BOOL isApropos = [resourceSpecifier hasSuffix:aproposSuffix];
        if (isApropos) {
            NSUInteger index = resourceSpecifier.length - aproposSuffix.length;
            resourceSpecifier = [resourceSpecifier substringToIndex:index];
        }
        
        NSPredicate *notRootPredicate = [NSPredicate predicateWithFormat:@"'/' != SELF"];
        NSArray<NSString *> *pathComponents = [resourceSpecifier.pathComponents filteredArrayUsingPredicate:notRootPredicate];
        if (!pathComponents.count) return nil;
        
        NSMutableArray<ManPage *> *manPages = [NSMutableArray new];
        if (1 == pathComponents.count) {
            ManPage *manPage = [[ManPage alloc] initWithName:pathComponents.firstObject];
            [manPages addObject:manPage];
        } else {
            NSString *section = nil;
            for (NSString *pathComponent in pathComponents) {
                if (!section && [ManPage isSection:pathComponent]) {
                    section = pathComponent;
                } else {
                    ManPage *manPage = [[ManPage alloc] initWithSection:section
                                                                andName:pathComponent];
                    [manPages addObject:manPage];
                    section = nil;
                }
            }
        }
        
        if (isApropos) {
            [_manDocumentController openApropos:manPages.firstObject.name];
        } else {
            NSString *string = [[manPages valueForKey:@"description"] componentsJoinedByString:@" "];
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
