//
//  Application.m
//  ManOpen
//
//  Created by Don McCaughey on 2/13/18.
//

#import "Application.h"

#import "Version.h"


@implementation Application

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

- (instancetype)initWithURL:(NSURL *)url
{
    NSBundle *bundle = [NSBundle bundleWithURL:url];
    if (bundle) {
        NSString *versionString = [bundle objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
        Version *version = [[[Version alloc] initWithVersion:versionString] autorelease];
        return [self initWithBundleIdentifier:bundle.bundleIdentifier
                                          URL:url
                                   andVersion:version];
    } else {
        return nil;
    }
}

- (void)dealloc
{
    [_bundleIdentifier release];
    [_url release];
    [_version release];
    [super dealloc];
}

@end
