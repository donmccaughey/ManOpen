//
//  NSUserDefaults+ManOpen.m
//  ManOpen
//
//  Created by Don McCaughey on 2/10/18.
//

#import "NSUserDefaults+ManOpen.h"


@implementation NSUserDefaults (ManOpen)

- (NSColor *)colorForKey:(NSString *)key
{
    NSData *colorData = [self dataForKey:key];
    return colorData ? [NSUnarchiver unarchiveObjectWithData:colorData] : nil;
}

- (NSColor *)manTextColor
{
    return [self colorForKey:@"ManTextColor"];
}

- (NSColor *)manLinkColor
{
    return [self colorForKey:@"ManLinkColor"];
}

- (NSColor *)manBackgroundColor
{
    return [self colorForKey:@"ManBackgroundColor"];
}

- (NSFont *)manFont
{
    NSFont *defaultFont = [NSFont userFixedPitchFontOfSize:12.0f];
    
    NSString *fontString = [self stringForKey:@"ManFont"];
    if (!fontString) return defaultFont;
    
    NSRange range = [fontString rangeOfString:@" "];
    if (NSNotFound == range.location) return defaultFont;
    
    CGFloat size = [fontString substringToIndex:range.location].floatValue ?: 12.0;
    NSString *name = [fontString substringFromIndex:NSMaxRange(range)];
    NSFont *font = [NSFont fontWithName:name
                                   size:size];
    
    return font ?: defaultFont;
}

- (NSString *)manPath
{
    return [self stringForKey:@"ManPath"];
}

@end
