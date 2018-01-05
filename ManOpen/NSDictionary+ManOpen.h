//
//  NSDictionary+ManOpen.h
//  ManOpen
//
//  Created by Don McCaughey on 12/25/17.
//

#import <Foundation/Foundation.h>


@interface NSDictionary (ManOpen)

+ (nonnull NSDictionary<NSString *, NSString *> *)dictionaryWithURLQuery:(nullable NSString *)urlQuery;

@end
