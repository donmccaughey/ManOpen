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
        _url = url;
        _version = version;
    }
    return self;
}

- (instancetype)initWithURL:(NSURL *)url
{
    NSBundle *bundle = [NSBundle bundleWithURL:url];
    NSString *versionString = [bundle objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
    Version *version = [[Version alloc] initWithVersion:versionString];
    
    return [self initWithBundleIdentifier:bundle.bundleIdentifier
                                      URL:url
                               andVersion:version];
}

@end
