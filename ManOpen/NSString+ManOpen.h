//
//  NSString+ManOpen.h
//  ManOpen
//
//  Created by Don McCaughey on 2/10/18.
//

#import <Foundation/Foundation.h>


@interface NSString (ManOpen)

@property (readonly) NSString *singleQuotedShellWord;

- (NSString *)singleQuotedShellWordWithSurroundingQuotes:(BOOL)addSurroundingQuotes;

@end
