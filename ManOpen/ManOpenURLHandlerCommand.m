#import "ManOpenURLHandlerCommand.h"

#import "ManDocumentController.h"


#define URL_SCHEME @"x-man-page"
#define URL_PREFIX URL_SCHEME @":"


@implementation ManOpenURLHandlerCommand

- (id)performDefaultImplementation
{
    NSString *param = [self directParameter];
    NSString *section = nil;
    
    if ([param rangeOfString:URL_PREFIX options:NSCaseInsensitiveSearch|NSAnchoredSearch].length > 0)
    {
        NSString *path = [param substringFromIndex:[URL_PREFIX length]];
        NSMutableArray *pageNames = [NSMutableArray array];
        NSArray *components = [path pathComponents];
        NSUInteger i, count = [components count];
        
        for (i=0; i<count; i++)
        {
            NSString *name = [components objectAtIndex:i];
            if ([name length] == 0 || [name isEqual:@"/"]) continue;
            if (IsSectionWord(name)) {
                section = name;
            }
            else {
                [pageNames addObject:name];
                if (section != nil) {
                    [pageNames addObject:[NSString stringWithFormat:@"(%@)", section]];
                    section = nil;
                }
            }
        }
        
        if ([pageNames count] > 0)
            [[ManDocumentController sharedDocumentController] openString:[pageNames componentsJoinedByString:@" "]];
    }
    return nil;
}

@end
