//
//  ApplicationTests.m
//  ManOpenTests
//
//  Created by Don McCaughey on 2/13/18.
//

#import <XCTest/XCTest.h>
#import "Application.h"
#import "Version.h"

@interface ApplicationTests : XCTestCase
@end


@implementation ApplicationTests

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

- (void)setUp
{
    [super setUp];
}

@end
