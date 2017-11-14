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
        NSMutableArray *words = [NSMutableArray array];
        NSString *section = nil;
        for (NSString *component in url.resourceSpecifier.pathComponents) {
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
            [_manDocumentController openString:[words componentsJoinedByString:@" "]];
        }
    }
    
    return nil;
}

@end
