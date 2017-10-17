
#import <Foundation/NSData.h>

@interface NSData (Utils)

- (BOOL)isNroffData;
- (BOOL)isRTFData;
- (BOOL)isGzipData;
- (BOOL)isBinaryData;

@end

#import <Foundation/NSFileHandle.h>

@interface NSFileHandle (Utils)

- (NSData *)readDataToEndOfFileIgnoreInterrupt;

@end

