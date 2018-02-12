//
//  NSString+ManOpen.h
//  ManOpen
//
//  Created by Don McCaughey on 2/10/18.
//

#import <Foundation/Foundation.h>


@interface NSString (ManOpen)

@property (readonly) NSArray<NSString *> *manPageWords;
@property (readonly) NSString *singleQuotedShellWord;
@property (readonly) NSArray<NSString *> *wordsSeparatedByWhitespaceAndNewlineCharacters;

- (NSString *)singleQuotedShellWordWithSurroundingQuotes:(BOOL)addSurroundingQuotes;

- (NSString *)stringByRemovingSuffix:(NSString *)suffix;

@end
