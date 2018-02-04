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
                               manPath:(NSArray<NSString *> *)manPath
                          isBackground:(BOOL)isBackground
{
    self = [super init];
    if (self) {
        _aproposKeyword = aproposKeyword.length ? [aproposKeyword copy] : nil;
        _manPath = manPath.count ? [manPath copy] : nil;
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
                        manPath:(NSArray<NSString *> *)manPath
                   isBackground:(BOOL)isBackground
{
    self = [super init];
    if (self) {
        _manPage = [manPage retain];
        _manPath = manPath.count ? [manPath copy] : nil;
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
        
        NSArray<NSString *> *manPath = [query[@"MANPATH"] componentsSeparatedByString:@":"];
        
        if ([@"apropos" isEqualToString:section.lowercaseString]) {
            return [self initWithAproposKeyword:name
                                        manPath:manPath
                                   isBackground:isBackground];
        } else {
            ManPage *manPage = [[ManPage alloc] initWithSection:section
                                                        andName:name];
            [manPage autorelease];
            return [self initWithManPage:manPage
                                 manPath:manPath
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
    [_manPath release];
    [super dealloc];
}

@end
