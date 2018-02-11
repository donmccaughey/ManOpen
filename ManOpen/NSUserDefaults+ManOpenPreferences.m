//
//  NSUserDefaults+ManOpenPreferences.m
//  ManOpen
//
//  Created by Don McCaughey on 2/10/18.
//

#import "NSUserDefaults+ManOpenPreferences.h"


@implementation NSUserDefaults (ManOpenPreferences)

- (NSColor *)_manColorForKey:(NSString *)key
{
    NSData *colorData = [self dataForKey:key];
    
    if (colorData == nil) return nil;
    return [NSUnarchiver unarchiveObjectWithData:colorData];
}

- (NSColor *)manTextColor
{
    return [self _manColorForKey:@"ManTextColor"];
}

- (NSColor *)manLinkColor
{
    return [self _manColorForKey:@"ManLinkColor"];
}

- (NSColor *)manBackgroundColor
{
    return [self _manColorForKey:@"ManBackgroundColor"];
}

- (NSFont *)manFont
{
    NSString *fontString = [self stringForKey:@"ManFont"];
    
    if (fontString != nil)
    {
        NSRange spaceRange = [fontString rangeOfString:@" "];
        if (spaceRange.length > 0)
        {
            CGFloat size = [[fontString substringToIndex:spaceRange.location] floatValue];
            NSString *name = [fontString substringFromIndex:NSMaxRange(spaceRange)];
            NSFont *font = [NSFont fontWithName:name size:size];
            if (font != nil) return font;
        }
    }
    
    return [NSFont userFixedPitchFontOfSize:12.0f]; // Monaco
}

- (NSString *)manPath
{
    return [self stringForKey:@"ManPath"];
}

@end
