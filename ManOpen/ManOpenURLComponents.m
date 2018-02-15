//
//  ManOpenURLComponents.m
//  ManOpen
//
//  Created by Don McCaughey on 2/3/18.
//

#import "ManOpenURLComponents.h"

#import "ManPage.h"
#import "NSDictionary+ManOpen.h"
#import "NSURL+ManOpen.h"


@implementation ManOpenURLComponents

- (instancetype)initWithAproposKeyword:(NSString *)aproposKeyword
                          manPathArray:(NSArray<NSString *> *)manPathArray
                          isBackground:(BOOL)isBackground
{
    self = [super init];
    if (self) {
        _aproposKeyword = aproposKeyword.length ? [aproposKeyword copy] : nil;
        _manPathArray = manPathArray.count ? [manPathArray copy] : nil;
        _isBackground = isBackground;
    }
    return self;
}

- (instancetype)initWithFilePath:(NSString *)filePath
                    isBackground:(BOOL)isBackground
{
    self = [super init];
    if (self) {
        _filePath = filePath.length ? [filePath copy] : nil;
        _isBackground = isBackground;
    }
    return self;
}

- (instancetype)initWithManPage:(ManPage *)manPage
                   manPathArray:(NSArray<NSString *> *)manPathArray
                   isBackground:(BOOL)isBackground
{
    self = [super init];
    if (self) {
        _manPage = [manPage retain];
        _manPathArray = manPathArray.count ? [manPathArray copy] : nil;
        _isBackground = isBackground;
    }
    return self;
}

- (instancetype)initWithURL:(NSURL *)url
{
    if (![url isManOpenScheme]) return nil;
    
    NSPredicate *notRootPredicate = [NSPredicate predicateWithFormat:@"'/' != SELF"];
    NSArray<NSString *> *pathComponents = [url.pathComponents filteredArrayUsingPredicate:notRootPredicate];
    if (!pathComponents.count) return nil;
    
    NSDictionary<NSString *, NSString *> *query = [NSDictionary dictionaryWithURLQuery:url.query];
    BOOL isBackground = [@"true" isEqual:query[@"background"].lowercaseString];
    
    NSUInteger schemeEnd = @"manopen:".length;
    NSString *resource = [url.absoluteString substringFromIndex:schemeEnd];
    if ([resource hasPrefix:@"//"]) {
        NSString *section = url.host.length ? url.host : @"";
        NSString *name = pathComponents.firstObject;
        
        NSArray<NSString *> *manPathArray = [query[@"MANPATH"] componentsSeparatedByString:@":"];
        
        if ([@"apropos" isEqualToString:section.lowercaseString]) {
            return [self initWithAproposKeyword:name
                                   manPathArray:manPathArray
                                   isBackground:isBackground];
        } else {
            ManPage *manPage = [[ManPage alloc] initWithSection:section
                                                        andName:name];
            [manPage autorelease];
            return [self initWithManPage:manPage
                            manPathArray:manPathArray
                            isBackground:isBackground];
        }
    } else {
        return [self initWithFilePath:url.path
                         isBackground:isBackground];
    }
}

- (void)dealloc
{
    [_aproposKeyword release];
    [_filePath release];
    [_manPage release];
    [_manPathArray release];
    [super dealloc];
}

- (NSString *)manPath
{
    return [_manPathArray componentsJoinedByString:@":"];
}

- (NSURL *)url
{
    NSString *urlString = nil;
    NSMutableDictionary<NSString *, NSString *> *query = [[NSMutableDictionary new] autorelease];
    if (_aproposKeyword) {
        urlString = [NSString stringWithFormat:@"manopen://apropos/%@", _aproposKeyword];
        if (_manPathArray) query[@"MANPATH"] = self.manPath;
    } else if (_manPage) {
        urlString = [NSString stringWithFormat:@"manopen://%@/%@",
                     _manPage.section ?: @"", _manPage.name];
        if (_manPathArray) query[@"MANPATH"] = self.manPath;
    } else if (_filePath) {
        urlString = [NSString stringWithFormat:@"manopen:%@", _filePath];
    }
    if (urlString) {
        if (_isBackground) query[@"background"] = @"true";
        urlString = [urlString stringByAppendingString:query.urlQuery];
        return [NSURL URLWithString:urlString];
    } else {
        return nil;
    }
}

@end
