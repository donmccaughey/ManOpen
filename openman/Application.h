//
//  Application.h
//  ManOpen
//
//  Created by Don McCaughey on 2/13/18.
//

#import <Foundation/Foundation.h>


@class Version;

@protocol LaunchServices;


@interface Application : NSObject

@property (copy) NSString *bundleIdentifier;
@property (retain) NSURL *url;
@property (retain) Version *version;

+ (instancetype)latestVersionWithLaunchServices:(id<LaunchServices>)launchServices
                               bundleIdentifier:(NSString *)bundleIdentifier
                                          error:(NSError **)error;

- (instancetype)initWithBundleIdentifier:(NSString *)bundleIdentifier
                                     URL:(NSURL *)url
                              andVersion:(Version *)version;

- (instancetype)initWithBundle:(NSBundle *)bundle;

- (instancetype)initWithURL:(NSURL *)url;

@end
