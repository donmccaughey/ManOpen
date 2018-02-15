//
//  LaunchServicesTests.m
//  openmanTests
//
//  Created by Don McCaughey on 2/14/18.
//

#import <XCTest/XCTest.h>
#import "LaunchServices.h"
#import "Application.h"
#import "Version.h"


@interface LaunchServicesTests : XCTestCase
@end


@implementation LaunchServicesTests

#pragma mark - applicationsForBundleIdentifier:error:

- (void)testApplicationsForBundleIdentifierError
{
    LaunchServices *launchServices = [[LaunchServices new] autorelease];
    NSError *error = nil;
    NSArray<Application *> *applications = [launchServices applicationsForBundleIdentifier:@"com.apple.dt.Xcode"
                                                                                     error:&error];
    XCTAssertTrue(applications.count > 0);
    XCTAssertNil(error);
    
    for (Application *application in applications) {
        XCTAssertEqualObjects(@"com.apple.dt.Xcode", application.bundleIdentifier);
        XCTAssertNotNil(application.url);
        XCTAssertTrue(application.version.major > 0);
    }
}

- (void)testApplicationsForBundleIdentifierError_when_no_apps_found
{
    LaunchServices *launchServices = [[LaunchServices new] autorelease];
    NSError *error = nil;
    NSArray<Application *> *applications = [launchServices applicationsForBundleIdentifier:@"com.example.NotAnApp"
                                                                                     error:&error];
    XCTAssertEqual(0, applications.count);
    XCTAssertNil(error);
}

- (void)testApplicationsForBundleIdentifierError_when_invalid_bundle_ID
{
    LaunchServices *launchServices = [[LaunchServices new] autorelease];
    NSError *error = nil;
    NSArray<Application *> *applications = [launchServices applicationsForBundleIdentifier:nil
                                                                                     error:&error];
    XCTAssertNil(applications);
    XCTAssertNotNil(error);
}

#pragma mark - bundlesForBundleIdentifier:error:

- (void)testBundlesForBundleIdentifierError
{
    LaunchServices *launchServices = [[LaunchServices new] autorelease];
    NSError *error = nil;
    NSArray<NSBundle *> *bundles = [launchServices bundlesForBundleIdentifier:@"com.apple.dt.Xcode"
                                                                        error:&error];
    XCTAssertTrue(bundles.count > 0);
    XCTAssertNil(error);
}

- (void)testBundlesForBundleIdentifierError_when_no_apps_found
{
    LaunchServices *launchServices = [[LaunchServices new] autorelease];
    NSError *error = nil;
    NSArray<NSBundle *> *bundles = [launchServices bundlesForBundleIdentifier:@"com.example.NotAnApp"
                                                                        error:&error];
    XCTAssertEqual(0, bundles.count);
    XCTAssertNil(error);
}

- (void)testBundlesForBundleIdentifierError_when_invalid_bundle_ID
{
    LaunchServices *launchServices = [[LaunchServices new] autorelease];
    NSError *error = nil;
    NSArray<NSBundle *> *bundles = [launchServices bundlesForBundleIdentifier:nil
                                                                        error:&error];
    XCTAssertNil(bundles);
    XCTAssertNotNil(error);
}

#pragma mark - URLsForBundleIdentifier:error:

- (void)testURLsForBundleIdentifierError
{
    LaunchServices *launchServices = [[LaunchServices new] autorelease];
    NSError *error = nil;
    NSArray<NSURL *> *urls = [launchServices URLsForBundleIdentifier:@"com.apple.dt.Xcode"
                                                               error:&error];
    XCTAssertTrue(urls.count > 0);
    XCTAssertNil(error);
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
