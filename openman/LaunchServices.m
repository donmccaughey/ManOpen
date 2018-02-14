//
//  LaunchServices.m
//  ManOpen
//
//  Created by Don McCaughey on 2/14/18.
//

#import "LaunchServices.h"

#import <CoreServices/CoreServices.h>


@implementation LaunchServices

- (NSArray<NSURL *> *)URLsForBundleIdentifier:(NSString *)bundleIdentifier
                                        error:(NSError **)error
{
    NSError *localError = nil;
    NSArray<NSURL *> *urls = (NSArray *)LSCopyApplicationURLsForBundleIdentifier((CFStringRef)bundleIdentifier, (CFErrorRef *)&localError);
    [urls autorelease];
    [localError autorelease];
    if (urls) {
        return urls;
    } else {
        if (localError && kLSApplicationNotFoundErr == localError.code) {
            return @[];
        } else {
            if (error) *error = localError;
            return nil;
        }
    }
}

@end
