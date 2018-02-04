//
//  XManPageURLComponents.h
//  ManOpen
//
//  Created by Don McCaughey on 2/3/18.
//

#import <Foundation/Foundation.h>


@class ManPage;


@interface XManPageURLComponents : NSObject

@property (copy) NSString *aproposKeyword;
@property (copy) NSArray<ManPage *> *manPages;

- (instancetype)initWithAproposKeyword:(NSString *)aproposKeyword;

- (instancetype)initWithManPages:(NSArray<ManPage *> *)manPages;

- (instancetype)initWithURL:(NSURL *)url;

@end
