//
//  NSString+ManOpen.m
//  ManOpen
//
//  Created by Don McCaughey on 2/10/18.
//

#import "NSString+ManOpen.h"

#import "ManDocumentController.h"


@implementation NSString (ManOpen)

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

- (NSArray<NSString *> *)wordsSeparatedByWhitespaceAndNewlineCharacters
{
    NSArray<NSString *> *components = [self componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSPredicate *notEmptyPredicate = [NSPredicate predicateWithFormat:@"length != 0"];
    return [components filteredArrayUsingPredicate:notEmptyPredicate];
}

@end
