//
//  DisplayPathFormatter.m
//  ManOpen
//
//  Created by Don McCaughey on 2/15/18.
//

#import "DisplayPathFormatter.h"


@implementation DisplayPathFormatter

- (NSString *)stringForObjectValue:(id)anObject
{
    NSString *new = [anObject stringByAbbreviatingWithTildeInPath];
    
    /* The above method may not work if the home directory is a symlink, and our path is already resolved */
    if ([new isAbsolutePath])
    {
        static NSString *resHome = nil;
        if (resHome == nil)
            resHome = [[[NSHomeDirectory() stringByResolvingSymlinksInPath] stringByAppendingString:@"/"] retain];
        
        if ([new hasPrefix:resHome])
            new = [@"~/" stringByAppendingString:[new substringFromIndex:[resHome length]]];
    }
    
    return new;
}

- (BOOL)getObjectValue:(id *)anObject forString:(NSString *)string errorDescription:(NSString **)error {
    *anObject = [string stringByExpandingTildeInPath];
    return YES;
}

@end
