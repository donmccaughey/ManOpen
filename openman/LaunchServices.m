//
//  LaunchServices.m
//  ManOpen
//
//  Created by Don McCaughey on 2/14/18.
//

#import "LaunchServices.h"

#import <CoreServices/CoreServices.h>

#import "Application.h"


@implementation LaunchServices

- (NSArray<Application *> *)applicationsForBundleIdentifier:(NSString *)bundleIdentifier
                                                      error:(NSError **)error
{
    NSArray<NSBundle *> *bundles = [self bundlesForBundleIdentifier:bundleIdentifier
                                                              error:error];
    if (bundles) {
        NSMutableArray<Application *> *applications = [[NSMutableArray new] autorelease];
        for (NSBundle *bundle in bundles) {
            Application *application = [[[Application alloc] initWithBundle:bundle] autorelease];
            [applications addObject:application];
        }
        return applications;
    } else {
        return nil;
    }
}

- (NSArray<NSBundle *> *)bundlesForBundleIdentifier:(NSString *)bundleIdentifier
                                              error:(NSError **)error
{
    NSArray<NSURL *> *urls = [self URLsForBundleIdentifier:bundleIdentifier
                                                     error:error];
    if (urls) {
        NSMutableArray<NSBundle *> *bundles = [[NSMutableArray new] autorelease];
        for (NSURL *url in urls) {
            NSBundle *bundle = [NSBundle bundleWithURL:url];
            [bundles addObject:bundle];
        }
        return bundles;
    } else {
        return nil;
    }
}

- (BOOL)openItemURLs:(NSArray<NSURL *> *)itemURLs
       inApplication:(Application *)application
               error:(NSError **)error
{
    return [self openItemURLs:itemURLs
                     inAppURL:application.url
                        error:error];
}

- (BOOL)openItemURLs:(NSArray<NSURL *> *)itemURLs
            inAppURL:(NSURL *)appURL
               error:(NSError **)error
{
    LSLaunchFlags launchFlags = kLSLaunchAsync | kLSLaunchDontSwitch;
    LSLaunchURLSpec launchURLSpec = {
        .appURL=(CFURLRef)appURL,
        .itemURLs=(CFArrayRef)itemURLs,
        .launchFlags=launchFlags,
    };
    CFURLRef *launchedAppOut = NULL;
    OSStatus status = LSOpenFromURLSpec(&launchURLSpec, launchedAppOut);
    if (status) {
        if (error) {
            *error = [NSError errorWithDomain:NSOSStatusErrorDomain
                                         code:status
                                     userInfo:nil];
        }
        return NO;
    } else {
        return YES;
    }
}

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
