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
    return EscapePath(self, addSurroundingQuotes);
}

@end
