//
//  NSUserDefaults+ManOpenPreferences.h
//  ManOpen
//
//  Created by Don McCaughey on 2/10/18.
//

#import <Cocoa/Cocoa.h>


@interface NSUserDefaults (ManOpenPreferences)

- (NSFont *)manFont;

- (NSString *)manPath;

- (NSColor *)manTextColor;

- (NSColor *)manLinkColor;

- (NSColor *)manBackgroundColor;

- (NSColor *)_manColorForKey:(NSString *)key;

@end
