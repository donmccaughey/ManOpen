/*
 * The FOUNDATION_STATIC_INLINE #define appeared in Rhapsody, so if it's
 * not there we're on OPENSTEP.
 */
#import <Foundation/NSObjCRuntime.h>
#ifndef FOUNDATION_STATIC_INLINE
#define OPENSTEP
#else
  /* Cocoa (MacOS X) removed a bunch of defines from NSDebug.h */
  #import <Foundation/NSDebug.h>
  #ifndef NSZoneMallocEvent
  #define MACOS_X
  #endif
#endif

#if !defined(MAC_OS_X_VERSION_10_5) || MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_5
// compiling against 10.4 or before headers
typedef int NSInteger;
typedef unsigned NSUInteger;
typedef float CGFloat;
typedef NSUInteger NSStringCompareOptions;
#endif

#ifndef NSFoundationVersionNumber10_4
#define NSFoundationVersionNumber10_4 567.0
#endif
#ifndef NSFoundationVersionNumber10_5
#define NSFoundationVersionNumber10_5 677.00
#endif
#ifndef NSFoundationVersionNumber10_6
#define NSFoundationVersionNumber10_6 751.00
#endif
#define IsLeopard()     (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber10_4)
#define IsSnowLeopard() (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber10_5)
#define IsLion()        (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber10_6)
