//
//  LaunchServices.h
//  ManOpen
//
//  Created by Don McCaughey on 2/14/18.
//

#import <Foundation/Foundation.h>


@class Application;


@protocol LaunchServices <NSObject>

- (NSArray<Application *> *)applicationsForBundleIdentifier:(NSString *)bundleIdentifier
                                                      error:(NSError **)error;

- (BOOL)openItemURLs:(NSArray<NSURL *> *)itemURLs
       inApplication:(Application *)application
               error:(NSError **)error;

@end


@interface LaunchServices : NSObject <LaunchServices>

- (NSArray<NSBundle *> *)bundlesForBundleIdentifier:(NSString *)bundleIdentifier
                                              error:(NSError **)error;

- (BOOL)openItemURLs:(NSArray<NSURL *> *)itemURLs
            inAppURL:(NSURL *)appURL
               error:(NSError **)error;

- (NSArray<NSURL *> *)URLsForBundleIdentifier:(NSString *)bundleIdentifier
                                        error:(NSError **)error;

@end
