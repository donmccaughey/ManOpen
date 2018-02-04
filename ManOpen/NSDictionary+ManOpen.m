//
//  NSDictionary+ManOpen.m
//  ManOpen
//
//  Created by Don McCaughey on 12/25/17.
//

#import "NSDictionary+ManOpen.h"


@implementation NSDictionary (ManOpen)

+ (nonnull NSDictionary<NSString *, NSString *> *)dictionaryWithURLQuery:(nullable NSString *)urlQuery
{
    if (!urlQuery) {
        return nil;
    }
    
    urlQuery = [urlQuery stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSArray<NSString *> *parts = [urlQuery componentsSeparatedByString:@"&"];
    NSMutableDictionary<NSString *, NSString *> *dictionary = [NSMutableDictionary new];
    for (NSString *part in parts) {
        NSRange range = [part rangeOfString:@"="];
        if (NSNotFound == range.location) {
            if (part.length) dictionary[part] = @"";
        } else {
            NSString *key = [part substringToIndex:range.location];
            key = key.stringByRemovingPercentEncoding ?: key;
            key = [key stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSString *value = [part substringFromIndex:range.location + 1];
            value = value.stringByRemovingPercentEncoding ?: value;
            value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            dictionary[key] = value;
        }
    }
    return [dictionary copy];
}

@end
