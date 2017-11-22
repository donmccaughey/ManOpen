#import "ManOpenURLHandlerCommand.h"

#import "ManDocumentController.h"


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
    
    if ([@"x-man-page" isEqualToString:url.scheme.lowercaseString]) {
        NSString *resourceSpecifier = url.resourceSpecifier;
        
        NSString *aproposSuffix = @";type=a";
        BOOL isApropos = [resourceSpecifier hasSuffix:aproposSuffix];
        if (isApropos) {
            NSUInteger index = resourceSpecifier.length - aproposSuffix.length;
            resourceSpecifier = [resourceSpecifier substringToIndex:index];
        }
        
        NSMutableArray *words = [NSMutableArray array];
        NSString *section = nil;
        for (NSString *component in resourceSpecifier.pathComponents) {
            if ([@"" isEqualToString:component]) continue;
            if ([@"/" isEqualToString:component]) continue;
            if (IsSectionWord(component)) {
                section = component;
            } else {
                [words addObject:component];
                if (section) {
                    [words addObject:[NSString stringWithFormat:@"(%@)", section]];
                    section = nil;
                }
            }
        }
        
        if (words.count) {
            if (isApropos) {
                [_manDocumentController openApropos:words.firstObject];
            } else {
                [_manDocumentController openString:[words componentsJoinedByString:@" "]];
            }
        }
    } else if ([@"file" isEqualToString:url.scheme.lowercaseString]) {
        NSString *path = nil;
        if (url.host.length) {
            if ([@"localhost" isEqualToString:url.host.lowercaseString]) {
                path = url.path;
            }
        } else {
            path = url.resourceSpecifier;
        }
        if (path.length > 1 && [path hasPrefix:@"/"]) {
            [_manDocumentController openFile:path
                                forceToFront:YES];
        }
    }
    
    return nil;
}

@end
