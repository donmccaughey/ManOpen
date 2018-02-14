//
//  Version.m
//  openman
//
//  Created by Don McCaughey on 2/13/18.
//

#import "Version.h"


@implementation Version

- (instancetype)init
{
    return [self initWithMajor:0
                         minor:0
                         patch:0];
}

- (instancetype)initWithMajor:(NSUInteger)major
                        minor:(NSUInteger)minor
                        patch:(NSUInteger)patch
{
    self = [super init];
    if (self) {
        _major = major;
        _minor = minor;
        _patch = patch;
    }
    return self;
}

- (instancetype)initWithVersion:(NSString *)version
{
    if (!version.length) return nil;
    
    NSInteger major = 0;
    NSInteger minor = 0;
    NSInteger patch = 0;

    static NSString *pattern =
        @"^"                // (anchored)
        "(\\d+)"            // major number
        "(?:"               // (non-capturing group)
            "\\."           //      dot
            "(\\d+)"        //      minor number
            "(?:"           //      (non-capturing group)
                "\\."       //          dot
                "(\\d+)"    //          patch number
            ")?"            //      (optional)
        ")?"                // (optional)
        "$"                 // (anchored)
    ;
    static NSRegularExpression *regex = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                          options:0
                                                            error:nil];
        [regex retain];
        NSAssert(regex, @"Expected to initialize regular expression");
    });

    NSRange range = NSMakeRange(0, version.length);
    NSTextCheckingResult *match = [regex firstMatchInString:version
                                                    options:NSMatchingAnchored
                                                      range:range];
    if (!match) return nil;
    
    NSString *majorString = [version substringWithRange:[match rangeAtIndex:1]];
    major = majorString.integerValue;
    
    if ([match rangeAtIndex:2].length) {
        NSString *minorString = [version substringWithRange:[match rangeAtIndex:2]];
        minor = minorString.integerValue;
    }
    
    if ([match rangeAtIndex:3].length) {
        NSString *patchString = [version substringWithRange:[match rangeAtIndex:3]];
        patch = patchString.integerValue;
    }
    
    return [self initWithMajor:major
                         minor:minor
                         patch:patch];
}

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"v%lu.%lu.%lu",
            (unsigned long)_major, (unsigned long)_minor, (unsigned long)_patch];
}

- (NSString *)description
{
    if (_patch) {
        return [NSString stringWithFormat:@"%lu.%lu.%lu",
                (unsigned long)_major, (unsigned long)_minor, (unsigned long)_patch];
    } else {
        return [NSString stringWithFormat:@"%lu.%lu",
                (unsigned long)_major, (unsigned long)_minor];
    }
}

- (NSUInteger)hash
{
    // From https://stackoverflow.com/a/2816747
    NSUInteger const prime = 92821;
    NSUInteger hash = prime + _major;
    hash = prime * hash + _minor;
    hash = prime * hash + _patch;
    return hash;
}

- (BOOL)isEqual:(id)object
{
    if (self == object) return YES;
    if (![object isKindOfClass:[Version class]]) return NO;
    return NSOrderedSame == [self compare:object];
}

- (NSComparisonResult)compare:(Version *)version
{
    if (!version) {
        [NSException raise:NSInvalidArgumentException
                    format:@"version cannot be nil"];
    }
    if (_major != version->_major) {
        return (_major < version->_major) ? NSOrderedAscending : NSOrderedDescending;
    }
    if (_minor != version->_minor) {
        return (_minor < version->_minor) ? NSOrderedAscending : NSOrderedDescending;
    }
    if (_patch != version->_patch) {
        return (_patch < version->_patch) ? NSOrderedAscending : NSOrderedDescending;
    }
    return NSOrderedSame;
}

@end
