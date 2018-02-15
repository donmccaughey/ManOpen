//
//  ApplicationTests.m
//  ManOpenTests
//
//  Created by Don McCaughey on 2/13/18.
//

#import <XCTest/XCTest.h>
#import "Application.h"
#import "LaunchServicesFake.h"
#import "Version.h"


@interface ApplicationTests : XCTestCase

@property (retain) LaunchServicesFake *launchServicesFake;
@property (retain) Application *application1;
@property (retain) Application *application2;
@property (retain) Application *application3;

@end


@implementation ApplicationTests

#pragma mark - latestVersionWithBundleIdentifier:

- (void)testLatestVersionWithLaunchServicesBundleIdentifier_when_not_found
{
    _launchServicesFake.errorOut = nil;
    _launchServicesFake.return_applications = @[];
    
    NSError *error = nil;
    Application *application = [Application latestVersionWithLaunchServices:_launchServicesFake
                                                           bundleIdentifier:@"cc.donm.ManOpen"
                                                                        error:&error];
    
    XCTAssertNil(application);
    XCTAssertNil(error);
}

- (void)testLatestVersionWithLaunchServicesBundleIdentifier_when_error_returned
{
    _launchServicesFake.errorOut = [NSError errorWithDomain:NSCocoaErrorDomain
                                                       code:-1
                                                   userInfo:nil];
    _launchServicesFake.return_applications = nil;
    
    NSError *error = nil;
    Application *application = [Application latestVersionWithLaunchServices:_launchServicesFake
                                                           bundleIdentifier:@"cc.donm.ManOpen"
                                                                      error:&error];
    
    XCTAssertNil(application);
    XCTAssertNotNil(error);
}

- (void)testLatestVersionWithLaunchServicesBundleIdentifier_when_one_found
{
    _launchServicesFake.errorOut = nil;
    _launchServicesFake.return_applications = @[ _application1 ];
    
    NSError *error = nil;
    Application *application = [Application latestVersionWithLaunchServices:_launchServicesFake
                                                           bundleIdentifier:@"cc.donm.ManOpen"
                                                                      error:&error];
    
    XCTAssertNotNil(application);
    XCTAssertEqualObjects(@"2.6", application.version.description);
    XCTAssertNil(error);
}

- (void)testLatestVersionWithLaunchServicesBundleIdentifier_when_three_found
{
    _launchServicesFake.errorOut = nil;
    _launchServicesFake.return_applications = @[ _application1, _application2, _application3 ];
    
    NSError *error = nil;
    Application *application = [Application latestVersionWithLaunchServices:_launchServicesFake
                                                           bundleIdentifier:@"cc.donm.ManOpen"
                                                                      error:&error];
    
    XCTAssertNotNil(application);
    XCTAssertEqualObjects(@"2.8", application.version.description);
    XCTAssertNil(error);
}

#pragma mark - initWithBundleIdentifier:URL:andVersion:

- (void)testInitWithBundleIdentifierURLandVersion
{
    NSURL *url = [NSURL URLWithString:@"file:///Applications/MyApp.app"];
    Version *version = [[[Version alloc] initWithVersion:@"1.2.3"] autorelease];
    Application *application = [[Application alloc] initWithBundleIdentifier:@"com.example.MyApp"
                                                                          URL:url
                                                                   andVersion:version];
    [application autorelease];
    XCTAssertEqualObjects(@"com.example.MyApp", application.bundleIdentifier);
    XCTAssertEqualObjects(url, application.url);
    XCTAssertEqualObjects(version, application.version);
}

#pragma mark - initWithBundle:

- (void)testInitWithBundle
{
    NSBundle *bundle = [NSBundle bundleWithIdentifier:@"com.apple.dt.Xcode"];
    XCTAssertNotNil(bundle);
    
    Application *application = [[[Application alloc] initWithBundle:bundle] autorelease];
    XCTAssertNotNil(application);
    XCTAssertEqualObjects(@"com.apple.dt.Xcode", application.bundleIdentifier);
    XCTAssertNotNil(application.url);
    XCTAssertNotNil(application.version);
    XCTAssertTrue(application.version.major > 0);
}

- (void)testInitWithBundle_when_nil
{
    Application *application = [[Application alloc] initWithBundle:nil];
    XCTAssertNil(application);
}

#pragma mark - initWithURL:

- (void)testInitWithURL
{
    NSURL *url = [NSURL URLWithString:@"file:///Applications/Xcode.app"];
    Application *application = [[[Application alloc] initWithURL:url] autorelease];
    XCTAssertEqualObjects(@"com.apple.dt.Xcode", application.bundleIdentifier);
    XCTAssertNotNil(application.url);
    XCTAssertNotNil(application.version);
    XCTAssertTrue(application.version.major > 0);
}

- (void)testInitWithURL_when_invalid_path
{
    NSURL *url = [NSURL URLWithString:@"file:///not/a/real.app"];
    Application *application = [[Application alloc] initWithURL:url];
    XCTAssertNil(application);
}

- (void)testInitWithURL_when_invalid_scheme
{
    NSURL *url = [NSURL URLWithString:@"http://www.example.com"];
    XCTAssertThrows(
                    [[Application alloc] initWithURL:url]
                    );
}

#pragma mark - setUp

- (void)setUp
{
    [super setUp];
    _launchServicesFake = [LaunchServicesFake new];
    
    NSURL *url1 = [NSURL URLWithString:@"file:///Applications/ManOpen.app/"];
    Version *version1 = [[[Version alloc] initWithVersion:@"2.6"] autorelease];
    _application1 = [[Application alloc] initWithBundleIdentifier:@"cc.donm.ManOpen"
                                                              URL:url1
                                                       andVersion:version1];
    
    NSURL *url2 = [NSURL URLWithString:@"file:///Applications/ManOpen-2.7.app/"];
    Version *version2 = [[[Version alloc] initWithVersion:@"2.7"] autorelease];
    _application2 = [[Application alloc] initWithBundleIdentifier:@"cc.donm.ManOpen"
                                                              URL:url2
                                                       andVersion:version2];
    
    NSURL *url3 = [NSURL URLWithString:@"file:///Applications/ManOpen-2.8.app/"];
    Version *version3 = [[[Version alloc] initWithVersion:@"2.8"] autorelease];
    _application3 = [[Application alloc] initWithBundleIdentifier:@"cc.donm.ManOpen"
                                                              URL:url3
                                                       andVersion:version3];
}

- (void)tearDown
{
    [super tearDown];
    [_launchServicesFake release];
    [_application1 release];
    [_application2 release];
    [_application3 release];
}

@end
