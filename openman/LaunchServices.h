//
//  LaunchServices.h
//  ManOpen
//
//  Created by Don McCaughey on 2/14/18.
//

#import <Foundation/Foundation.h>


@protocol LaunchServices <NSObject>

- (NSArray<NSURL *> *)URLsForBundleIdentifier:(NSString *)bundleIdentifier
                                        error:(NSError **)error;

@end


@interface LaunchServices : NSObject <LaunchServices>

@end

