//
//  ManPage.m
//  ManOpen
//
//  Created by Don McCaughey on 1/20/18.
//

#import "ManPage.h"


@implementation ManPage

+ (BOOL)isSection:(NSString *)section
{
    if (!section.length) return NO;
    
    if ([@"n" isEqualToString:section]) return YES;
    if ([@"x" isEqualToString:section]) return YES;
    
    unichar firstCharacter = [section characterAtIndex:0];
    if ([[NSCharacterSet decimalDigitCharacterSet] characterIsMember:firstCharacter]) return YES;
    
    return NO;
}

- (instancetype)init
{
    return [self initWithSection:nil
                         andName:nil];
}

- (instancetype)initWithSection:(NSString *)section
                        andName:(NSString *)name
{
    self = [super init];
    if (self) {
        _name = name.length ? [name copy] : nil;
        _section = [[self class] isSection:section] ? [section copy] : nil;
    }
    return self;
}

- (instancetype)initWithName:(NSString *)name
{
    return [self initWithSection:nil
                         andName:name];
}

- (NSString *)description
{
    if (_section && _name) {
        return [NSString stringWithFormat:@"%@(%@)", _name, _section];
    } else if (_name) {
        return _name;
    } else {
        return @"";
    }
}

@end
