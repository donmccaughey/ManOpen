//
//  MVAppInfo.m
//  ManOpen
//
//  Created by Don McCaughey on 2/15/18.
//

#import "MVAppInfo.h"


@implementation MVAppInfo

static NSMutableArray *allApps = nil;

- (id)initWithBundleID:(NSString *)aBundleID
{
    bundleID = [aBundleID retain];
    return self;
}

- (void)dealloc
{
    [appURL release];
    [displayName release];
    [bundleID release];
    [super dealloc];
}

- (BOOL)isEqualToBundleID:(NSString *)aBundleID
{
    return [bundleID caseInsensitiveCompare:aBundleID] == NSOrderedSame;
}
- (BOOL)isEqual:(id)other
{
    return [self isEqualToBundleID:[other bundleID]];
}
- (NSUInteger)hash
{
    return [[bundleID lowercaseString] hash];
}
- (NSComparisonResult)compareDisplayName:(id)other
{
    return [[self displayName] localizedCaseInsensitiveCompare:[other displayName]];
}

- (NSString *)bundleID
{
    return bundleID;
}

- (NSURL *)appURL
{
    if (appURL == nil)
    {
        NSString *path = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:bundleID];
        if (path != nil)
            appURL = [[NSURL fileURLWithPath:path] retain];
    }
    
    return appURL;
}

- (NSString *)displayName
{
    if (displayName == nil)
    {
        NSURL *url = [self appURL];
        NSDictionary *infoDict = [(id)CFBundleCopyInfoDictionaryForURL((CFURLRef)url) autorelease];
        NSString *appVersion;
        NSString *niceName = nil;
        
        if (infoDict == nil)
            infoDict = [[NSBundle bundleWithPath:[url path]] infoDictionary];
        
        LSCopyDisplayNameForURL((CFURLRef)url, (CFStringRef*)&niceName);
        [niceName autorelease];
        if (niceName == nil)
            niceName = [[url path] lastPathComponent];
        
        appVersion = [infoDict objectForKey:@"CFBundleShortVersionString"];
        if (appVersion != nil)
            niceName = [NSString stringWithFormat:@"%@ (%@)", niceName, appVersion];
        
        displayName = [niceName retain];
    }
    
    return displayName;
}

+ (void)sortApps
{
    [allApps sortUsingSelector:@selector(compareDisplayName:)];
}
+ (void)addAppWithID:(NSString *)aBundleID sort:(BOOL)shouldResort
{
    MVAppInfo *info = [[MVAppInfo alloc] initWithBundleID:aBundleID];
    if (![allApps containsObject:info])
    {
        [allApps addObject:info];
        if (shouldResort)
            [self sortApps];
    }
    [info release];
}

+ (NSArray *)allManViewerApps
{
    if (allApps == nil)
    {
        /* Ensure our app is registered */
        //        NSString *appPath = [[NSBundle mainBundle] bundlePath];
        //        NSURL *url = [NSURL fileURLWithPath:appPath];
        //        LSRegisterURL((CFURLRef)url, false);
        
        NSArray *allBundleIDs = [(id)LSCopyAllHandlersForURLScheme((CFStringRef)URL_SCHEME) autorelease];
        NSUInteger i;
        
        allApps = [[NSMutableArray alloc] initWithCapacity:[allBundleIDs count]];
        for (i = 0; i<[allBundleIDs count]; i++) {
            [self addAppWithID:[allBundleIDs objectAtIndex:i] sort:NO];
        }        
        [self sortApps];
    }
    
    return allApps;
}

+ (NSUInteger)indexOfBundleID:(NSString*)bundleID
{
    NSArray *apps = [self allManViewerApps];
    NSUInteger i, count = [apps count];
    
    for (i=0; bundleID != nil && i<count; i++) {
        if ([[apps objectAtIndex:i] isEqualToBundleID:bundleID])
            return i;
    }
    
    return NSNotFound;
}

@end
