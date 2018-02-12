//
//  XManPageURLComponents.m
//  ManOpen
//
//  Created by Don McCaughey on 2/3/18.
//

#import "XManPageURLComponents.h"

#import "ManPage.h"
#import "NSURL+ManOpen.h"


@implementation XManPageURLComponents

- (instancetype)initWithAproposKeyword:(NSString *)aproposKeyword
{
    self = [super init];
    if (self) {
        _aproposKeyword = aproposKeyword.length ? [aproposKeyword copy] : nil;
        _manPages = nil;
    }
    return self;
}

- (instancetype)initWithManPages:(NSArray<ManPage *> *)manPages
{
    self = [super init];
    if (self) {
        _manPages = manPages.count ? [manPages copy] : nil;
    }
    return self;
}

- (instancetype)initWithURL:(NSURL *)url
{
    if (!url.isXManPageScheme) return nil;
    
    NSString *resourceSpecifier = url.resourceSpecifier;
    NSString *aproposSuffix = @";type=a";
    BOOL isApropos = [resourceSpecifier hasSuffix:aproposSuffix];
    if (isApropos) {
        NSUInteger index = resourceSpecifier.length - aproposSuffix.length;
        resourceSpecifier = [resourceSpecifier substringToIndex:index];
    }
    
    NSPredicate *notRootPredicate = [NSPredicate predicateWithFormat:@"'/' != SELF"];
    NSArray<NSString *> *pathComponents = [resourceSpecifier.pathComponents filteredArrayUsingPredicate:notRootPredicate];
    if (!pathComponents.count) return nil;
    
    NSMutableArray<ManPage *> *manPages = [[NSMutableArray new] autorelease];
    if (1 == pathComponents.count) {
        ManPage *manPage = [[ManPage alloc] initWithName:pathComponents.firstObject];
        [manPages addObject:manPage];
        [manPage release];
    } else {
        NSString *section = nil;
        for (NSString *pathComponent in pathComponents) {
            if (!section && [ManPage isSection:pathComponent]) {
                section = pathComponent;
            } else {
                ManPage *manPage = [[ManPage alloc] initWithSection:section
                                                            andName:pathComponent];
                [manPages addObject:manPage];
                [manPage release];
                section = nil;
            }
        }
    }
    
    if (isApropos) {
        return [self initWithAproposKeyword:manPages.firstObject.name];
    } else {
        return [self initWithManPages:manPages];
    }
}

- (void)dealloc
{
    [_aproposKeyword release];
    [_manPages release];
    [super dealloc];
}

@end
