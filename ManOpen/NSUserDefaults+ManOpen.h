//
//  NSUserDefaults+ManOpen.h
//  ManOpen
//
//  Created by Don McCaughey on 2/10/18.
//

#import <Cocoa/Cocoa.h>


@interface NSUserDefaults (ManOpen)

- (NSColor *)colorForKey:(NSString *)key;

- (NSFont *)manFont;

- (NSString *)manPath;

- (NSColor *)manTextColor;

- (NSColor *)manLinkColor;

- (NSColor *)manBackgroundColor;

@end
