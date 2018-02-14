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
    Application *application = [[[Application alloc] initWithBundleIdentifier:@"com.example.MyApp"
                                                                          URL:url
                                                                   andVersion:version] autorelease];
    XCTAssertEqualObjects(@"com.example.MyApp", application.bundleIdentifier);
    XCTAssertEqualObjects(url, application.url);
    XCTAssertEqualObjects(version, application.version);
}

- (void)testInitWithURL
{
    NSURL *url = [NSURL URLWithString:@"file:///Applications/Xcode.app"];
    Application *application = [[[Application alloc] initWithURL:url] autorelease];
    XCTAssertEqualObjects(@"com.apple.dt.Xcode", application.bundleIdentifier);
    XCTAssertEqualObjects(url, application.url);
    XCTAssertNotNil(application.version);
    XCTAssertTrue(application.version.major >= 1);
}

- (void)testInitWithURL_when_invalid_file
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
