//
//  NSString+ManOpen.m
//  ManOpen
//
//  Created by Don McCaughey on 2/10/18.
//

#import "NSString+ManOpen.h"

#import "ManDocumentController.h"


@implementation NSString (ManOpen)

- (NSArray<NSString *> *)manPageWords
{
    NSArray<NSString *> *words = self.wordsSeparatedByWhitespaceAndNewlineCharacters;
    NSString *lastWord = nil;
    NSMutableArray *manPageWords = [[NSMutableArray new] autorelease];
    for (NSString *word in words) {
        if (!lastWord) {
            lastWord = [word stringByRemovingSuffix:@","];
        } else if ([word hasPrefix:@"("] && [word hasSuffix:@")"]) {
            NSString *manPageWord = [lastWord stringByAppendingString:word];
            [manPageWords addObject:manPageWord];
            lastWord = nil;
        } else if ([lastWord hasSuffix:@"-"]) {
            NSString *prefixWord = [lastWord stringByRemovingSuffix:@"-"];
            lastWord = [prefixWord stringByAppendingString:word];
        } else {
            [manPageWords addObject:lastWord];
            lastWord = [word stringByRemovingSuffix:@","];
        }
    }
    if (lastWord) {
        [manPageWords addObject:lastWord];
    }
    return manPageWords;
}

- (NSString *)singleQuotedShellWord
{
    return [self singleQuotedShellWordWithSurroundingQuotes:YES];
}

- (NSString *)singleQuotedShellWordWithSurroundingQuotes:(BOOL)addSurroundingQuotes
{
    NSString *escaped = [self stringByReplacingOccurrencesOfString:@"'"
                                                        withString:@"'\\''"];
    if (addSurroundingQuotes) {
        return [NSString stringWithFormat:@"'%@'", escaped];
    } else {
        return escaped;
    }
}

- (NSString *)stringByRemovingSuffix:(NSString *)suffix
{
    if ([self hasSuffix:suffix]) {
        return [self substringToIndex:self.length - suffix.length];
    } else {
        return [[self retain] autorelease];
    }
}

- (NSArray<NSString *> *)wordsSeparatedByWhitespaceAndNewlineCharacters
{
    NSArray<NSString *> *components = [self componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSPredicate *notEmptyPredicate = [NSPredicate predicateWithFormat:@"length != 0"];
    return [components filteredArrayUsingPredicate:notEmptyPredicate];
}

@end
