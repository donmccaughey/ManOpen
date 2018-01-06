//
//  NSURL+ManOpen.h
//  ManOpen
//
//  Created by Don McCaughey on 12/24/17.
//

#import <Foundation/Foundation.h>


@interface NSURL (ManOpen)

@property (readonly) BOOL isFileScheme;
@property (readonly) BOOL isManOpenScheme;
@property (readonly) BOOL isXManPageScheme;

@end
