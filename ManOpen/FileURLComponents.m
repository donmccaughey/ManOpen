//
//  FileURLComponents.m
//  ManOpen
//
//  Created by Don McCaughey on 1/14/18.
//

#import "FileURLComponents.h"


@implementation FileURLComponents

- (instancetype)initWithHost:(NSString *)host
                     andPath:(NSString *)path
{
    self = [super init];
    if (self) {
        _host = host.length ? [host copy] : nil;
        _path = path.length ? [path copy] : nil;
    }
    return self;
}

- (instancetype)initWithURL:(NSURL *)url
{
    return [self initWithHost:url.host
                      andPath:url.path];
}

- (void)dealloc
{
    [_host release];
    [_path release];
    [super dealloc];
}

- (BOOL)isAbsolute
{
    return [_path hasPrefix:@"/"];
}

- (BOOL)isDirectory
{
    return [_path hasSuffix:@"/"];
}

- (BOOL)isLocalhost
{
    if (_host) {
        return [@"localhost" isEqualToString:_host.lowercaseString];
    } else {
        return YES;
    }
}

@end
