//
//  LaunchServicesFake.h
//  openmanTests
//
//  Created by Don McCaughey on 2/14/18.
//

#import "LaunchServices.h"


@class Application;


@interface LaunchServicesFake : NSObject <LaunchServices>

@property (retain) NSError *errorOut;
@property (copy) NSArray<Application *> *return_applications;

@end
