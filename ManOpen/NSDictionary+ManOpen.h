//
//  NSDictionary+ManOpen.h
//  ManOpen
//
//  Created by Don McCaughey on 12/25/17.
//

#import <Foundation/Foundation.h>


@interface NSDictionary (ManOpen)

+ (NSDictionary<NSString *, NSString *> *)dictionaryWithURLQuery:(NSString *)urlQuery;

@end
