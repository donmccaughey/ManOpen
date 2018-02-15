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
@property (readonly) NSString *manPath;
@property (copy) NSArray<NSString *> *manPathArray;
@property (readonly) NSURL *url;

- (instancetype)initWithAproposKeyword:(NSString *)aproposKeyword
                          manPathArray:(NSArray<NSString *> *)manPathArray
                          isBackground:(BOOL)isBackground;

- (instancetype)initWithFilePath:(NSString *)filePath
                    isBackground:(BOOL)isBackground;

- (instancetype)initWithManPage:(ManPage *)manPage
                   manPathArray:(NSArray<NSString *> *)manPathArray
                   isBackground:(BOOL)isBackground;

- (instancetype)initWithURL:(NSURL *)url;

@end
