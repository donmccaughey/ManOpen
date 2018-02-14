//
//  Application.h
//  ManOpen
//
//  Created by Don McCaughey on 2/13/18.
//

#import <Foundation/Foundation.h>


@class Version;


@interface Application : NSObject

@property (copy) NSString *bundleIdentifier;
@property (retain) NSURL *url;
@property (retain) Version *version;

- (instancetype)initWithBundleIdentifier:(NSString *)bundleIdentifier
                                     URL:(NSURL *)url
                              andVersion:(Version *)version;

- (instancetype)initWithURL:(NSURL *)url;

@end
