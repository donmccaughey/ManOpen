//
//  Application.m
//  ManOpen
//
//  Created by Don McCaughey on 2/13/18.
//

#import "Application.h"

#import "LaunchServices.h"
#import "Version.h"


@implementation Application

+ (instancetype)latestVersionWithLaunchServices:(id<LaunchServices>)launchServices
                               bundleIdentifier:(NSString *)bundleIdentifier
                                          error:(NSError **)error
{
    NSArray<Application *> *applications = [launchServices applicationsForBundleIdentifier:bundleIdentifier
                                                                                     error:error];
    if (applications.count) {
        NSArray<NSSortDescriptor *> *sortByVersion = @[
                                                       [NSSortDescriptor sortDescriptorWithKey:@"version" ascending:NO],
                                                       ];
        NSArray<Application *> *sorted = [applications sortedArrayUsingDescriptors:sortByVersion];
        return sorted.firstObject;
    } else {
        return nil;
    }
}

- (instancetype)initWithBundleIdentifier:(NSString *)bundleIdentifier
                                     URL:(NSURL *)url
                              andVersion:(Version *)version
{
    self = [super init];
    if (self) {
        _bundleIdentifier = [bundleIdentifier copy];
        _url = [url retain];
        _version = [version retain];
    }
    return self;
}

- (instancetype)initWithBundle:(NSBundle *)bundle
{
    if (!bundle) return nil;
    
    NSString *versionString = [bundle objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
    Version *version = [[[Version alloc] initWithVersion:versionString] autorelease];
    return [self initWithBundleIdentifier:bundle.bundleIdentifier
                                      URL:bundle.bundleURL
                               andVersion:version];
}

- (instancetype)initWithURL:(NSURL *)url
{
    NSBundle *bundle = [NSBundle bundleWithURL:url];
    return [self initWithBundle:bundle];
}

- (void)dealloc
{
    [_bundleIdentifier release];
    [_url release];
    [_version release];
    [super dealloc];
}

@end
