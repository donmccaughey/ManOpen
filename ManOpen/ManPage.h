//
//  ManPage.h
//  ManOpen
//
//  Created by Don McCaughey on 1/20/18.
//

#import <Foundation/Foundation.h>


@interface ManPage : NSObject

@property (copy) NSString *name;
@property (copy) NSString *section;

+ (BOOL)isSection:(NSString *)section;

- (instancetype)initWithSection:(NSString *)section
                        andName:(NSString *)name;

- (instancetype)initWithName:(NSString *)name;

@end
