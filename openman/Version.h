//
//  Version.h
//  openman
//
//  Created by Don McCaughey on 2/13/18.
//

#import <Foundation/Foundation.h>


@interface Version : NSObject

@property NSUInteger major;
@property NSUInteger minor;
@property NSUInteger patch;

- (instancetype)initWithMajor:(NSUInteger)major
                        minor:(NSUInteger)minor
                        patch:(NSUInteger)patch;

- (instancetype)initWithVersion:(NSString *)version;

- (NSComparisonResult)compare:(Version *)version;

@end
