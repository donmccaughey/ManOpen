//
//  LaunchServicesTests.m
//  openmanTests
//
//  Created by Don McCaughey on 2/14/18.
//

#import <XCTest/XCTest.h>
#import "LaunchServices.h"


@interface LaunchServicesTests : XCTestCase
@end


@implementation LaunchServicesTests

- (void)testURLsForBundleIdentifierError
{
    LaunchServices *launchServices = [[LaunchServices new] autorelease];
    NSError *error = nil;
    NSArray<NSURL *> *urls = [launchServices URLsForBundleIdentifier:@"com.apple.dt.Xcode"
                                                               error:&error];
    XCTAssertTrue(urls.count >= 1);
    XCTAssertNil(error);

    NSURL *expectedURL = [NSURL URLWithString:@"file:///Applications/Xcode.app/"];
    XCTAssertTrue([urls containsObject:expectedURL]);
}

- (void)testURLsForBundleIdentifierError_when_no_apps_found
{
    LaunchServices *launchServices = [[LaunchServices new] autorelease];
    NSError *error = nil;
    NSArray<NSURL *> *urls = [launchServices URLsForBundleIdentifier:@"com.example.NotAnApp"
                                                               error:&error];
    XCTAssertNotNil(urls);
    XCTAssertEqual(0, urls.count);
    XCTAssertNil(error);
}

- (void)testURLsForBundleIdentifierError_when_invalid_bundle_ID
{
    LaunchServices *launchServices = [[LaunchServices new] autorelease];
    NSError *error = nil;
    NSArray<NSURL *> *urls = [launchServices URLsForBundleIdentifier:nil
                                                               error:&error];
    XCTAssertNil(urls);
    XCTAssertNotNil(error);
}

@end
