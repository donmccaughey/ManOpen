//
//  ManOpenURLComponents.h
//  ManOpen
//
//  Created by Don McCaughey on 2/3/18.
//

#import <Foundation/Foundation.h>


@class ManPage;


@interface ManOpenURLComponents : NSObject

@property (copy) NSString *aproposKeyword;
@property (copy) NSString *filePath;
@property (assign) BOOL isBackground;
@property (retain) ManPage *manPage;
@property (copy) NSArray<NSString *> *manPath;
@property (readonly) NSString *manPathString;

- (instancetype)initWithAproposKeyword:(NSString *)aproposKeyword
                               manPath:(NSArray<NSString *> *)manPath
                          isBackground:(BOOL)isBackground;

- (instancetype)initWithFilePath:(NSString *)filePath
                    isBackground:(BOOL)isBackground;

- (instancetype)initWithManPage:(ManPage *)manPage
                        manPath:(NSArray<NSString *> *)manPath
                   isBackground:(BOOL)isBackground;

- (instancetype)initWithURL:(NSURL *)url;

@end
