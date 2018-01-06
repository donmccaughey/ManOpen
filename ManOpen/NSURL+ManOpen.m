//
//  NSURL+ManOpen.m
//  ManOpen
//
//  Created by Don McCaughey on 12/24/17.
//

#import "NSURL+ManOpen.h"


@implementation NSURL (ManOpen)

- (BOOL)isFileScheme
{
    return [@"file" isEqualToString:self.scheme.lowercaseString];
}

- (BOOL)isManOpenScheme
{
    return [@"manopen" isEqualToString:self.scheme.lowercaseString];
}

- (BOOL)isXManPageScheme
{
    return [@"x-man-page" isEqualToString:self.scheme.lowercaseString];
}

@end
