//
//  LaunchServicesFake.m
//  openmanTests
//
//  Created by Don McCaughey on 2/14/18.
//

#import "LaunchServicesFake.h"


@implementation LaunchServicesFake

- (void)dealloc
{
    [_errorOut release];
    [_return_applications release];
    [super dealloc];
}

- (NSArray<Application *> *)applicationsForBundleIdentifier:(NSString *)bundleIdentifier
                                                      error:(NSError **)error
{
    if (error) *error = [[_errorOut retain] autorelease];
    return [[_return_applications retain] autorelease];
}

- (BOOL)openItemURLs:(NSArray<NSURL *> *)itemURLs
       inApplication:(Application *)application
               error:(NSError **)error
{
    [self doesNotRecognizeSelector:_cmd];
    return NO;
}

@end
