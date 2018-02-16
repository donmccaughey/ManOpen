//
//  MVAppInfo.h
//  ManOpen
//
//  Created by Don McCaughey on 2/15/18.
//

#import <Cocoa/Cocoa.h>


#define URL_SCHEME @"x-man-page"
#define URL_SCHEME_PREFIX URL_SCHEME @":"


/* Little class to store info on the possible man page viewers, for easier sorting by display name */
@interface MVAppInfo : NSObject
{
    NSString *bundleID;
    NSString *displayName;
    NSURL *appURL;
}

+ (NSArray *)allManViewerApps;
+ (void)addAppWithID:(NSString *)aBundleID sort:(BOOL)shouldResort;
+ (NSUInteger)indexOfBundleID:(NSString*)bundleID;
- (NSString *)bundleID;
- (NSString *)displayName;
- (NSURL *)appURL;

@end
