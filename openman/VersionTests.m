//
//  VersionTests.m
//  openmanTests
//
//  Created by Don McCaughey on 2/13/18.
//

#import <XCTest/XCTest.h>
#import "Version.h"


@interface VersionTests : XCTestCase
@end


@implementation VersionTests

- (void)testInit
{
    Version *version = [[Version new] autorelease];
    XCTAssertEqual(0, version.major);
    XCTAssertEqual(0, version.minor);
    XCTAssertEqual(0, version.patch);
    XCTAssertEqualObjects(@"0.0", version.description);
    XCTAssertEqualObjects(@"v0.0.0", version.debugDescription);
}

- (void)testInitWithMajorMinorPatch
{
    Version *version = [[[Version alloc] initWithMajor:1 minor:2 patch:3] autorelease];
    XCTAssertEqual(1, version.major);
    XCTAssertEqual(2, version.minor);
    XCTAssertEqual(3, version.patch);
    XCTAssertEqualObjects(@"1.2.3", version.description);
    XCTAssertEqualObjects(@"v1.2.3", version.debugDescription);
}

- (void)testInitWithMajorMinorPatch_for_patch_zero
{
    Version *version = [[[Version alloc] initWithMajor:11 minor:12 patch:0] autorelease];
    XCTAssertEqual(11, version.major);
    XCTAssertEqual(12, version.minor);
    XCTAssertEqual(0, version.patch);
    XCTAssertEqualObjects(@"11.12", version.description);
    XCTAssertEqualObjects(@"v11.12.0", version.debugDescription);
}

- (void)testInitWithVersion_when_nil
{
    Version *version = [[Version alloc] initWithVersion:nil];
    XCTAssertNil(version);
}

- (void)testInitWithVersion_when_empty
{
    Version *version = [[Version alloc] initWithVersion:@""];
    XCTAssertNil(version);
}

- (void)testInitWithVersion_when_not_a_version
{
    Version *version = [[Version alloc] initWithVersion:@" "];
    XCTAssertNil(version);
    
    version = [[Version alloc] initWithVersion:@"foo"];
    XCTAssertNil(version);

    version = [[Version alloc] initWithVersion:@"1.foo"];
    XCTAssertNil(version);
    
    version = [[Version alloc] initWithVersion:@"1.2.foo"];
    XCTAssertNil(version);
    
    version = [[Version alloc] initWithVersion:@"1.2.3a"];
    XCTAssertNil(version);
    
    version = [[Version alloc] initWithVersion:@"1.2.3.4"];
    XCTAssertNil(version);
    
    version = [[Version alloc] initWithVersion:@".2.3.4"];
    XCTAssertNil(version);

    version = [[Version alloc] initWithVersion:@"-1.2.3"];
    XCTAssertNil(version);
    
    version = [[Version alloc] initWithVersion:@"1.-2.3"];
    XCTAssertNil(version);
    
    version = [[Version alloc] initWithVersion:@"1.2.-3"];
    XCTAssertNil(version);

    version = [[Version alloc] initWithVersion:@"1. 2"];
    XCTAssertNil(version);

    version = [[Version alloc] initWithVersion:@"1.2 .3"];
    XCTAssertNil(version);
    
    version = [[Version alloc] initWithVersion:@" 1.2.3"];
    XCTAssertNil(version);
    
    version = [[Version alloc] initWithVersion:@"1.2.3 "];
    XCTAssertNil(version);
}

- (void)testInitWithVersion_with_one_part
{
    Version *version = [[[Version alloc] initWithVersion:@"8"] autorelease];
    XCTAssertEqual(8, version.major);
    XCTAssertEqual(0, version.minor);
    XCTAssertEqual(0, version.patch);
    XCTAssertEqualObjects(@"8.0", version.description);
    XCTAssertEqualObjects(@"v8.0.0", version.debugDescription);
}

- (void)testInitWithVersion_with_two_parts
{
    Version *version = [[[Version alloc] initWithVersion:@"4.5"] autorelease];
    XCTAssertEqual(4, version.major);
    XCTAssertEqual(5, version.minor);
    XCTAssertEqual(0, version.patch);
    XCTAssertEqualObjects(@"4.5", version.description);
    XCTAssertEqualObjects(@"v4.5.0", version.debugDescription);
}

- (void)testInitWithVersion_with_three_parts
{
    Version *version = [[[Version alloc] initWithVersion:@"1.2.3"] autorelease];
    XCTAssertEqual(1, version.major);
    XCTAssertEqual(2, version.minor);
    XCTAssertEqual(3, version.patch);
    XCTAssertEqualObjects(@"1.2.3", version.description);
    XCTAssertEqualObjects(@"v1.2.3", version.debugDescription);
}

- (void)testInitWithVersion_with_leading_zeros
{
    Version *version = [[[Version alloc] initWithVersion:@"01.002.0003"] autorelease];
    XCTAssertEqual(1, version.major);
    XCTAssertEqual(2, version.minor);
    XCTAssertEqual(3, version.patch);
    XCTAssertEqualObjects(@"1.2.3", version.description);
    XCTAssertEqualObjects(@"v1.2.3", version.debugDescription);
}

- (void)testEqualTo_and_hash
{
    Version *version1 = [[[Version alloc] initWithVersion:@"1.2.3"] autorelease];
    Version *version2 = [[[Version alloc] initWithVersion:@"1.2.3"] autorelease];
    
    XCTAssertFalse([version1 isEqual:nil]);
    XCTAssertEqual(version1, version1);
    
    XCTAssertEqual(version1.hash, version2.hash);
    XCTAssertEqualObjects(version1, version2);
    XCTAssertEqualObjects(version2, version1);
    
    version1 = [[[Version alloc] initWithVersion:@"1.2.3"] autorelease];
    version2 = [[[Version alloc] initWithVersion:@"1.2.4"] autorelease];
    XCTAssertNotEqualObjects(version1, version2);
    XCTAssertNotEqualObjects(version2, version1);
    
    version1 = [[[Version alloc] initWithVersion:@"1.2.3"] autorelease];
    version2 = [[[Version alloc] initWithVersion:@"1.5.3"] autorelease];
    XCTAssertNotEqualObjects(version1, version2);
    XCTAssertNotEqualObjects(version2, version1);
    
    version1 = [[[Version alloc] initWithVersion:@"1.2.3"] autorelease];
    version2 = [[[Version alloc] initWithVersion:@"6.2.3"] autorelease];
    XCTAssertNotEqualObjects(version1, version2);
    XCTAssertNotEqualObjects(version2, version1);
}

- (void)testCompare
{
    Version *version1 = [[[Version alloc] initWithVersion:@"1.2.3"] autorelease];
    Version *version2 = [[[Version alloc] initWithVersion:@"1.2.3"] autorelease];
    
    XCTAssertThrows([version1 compare:nil]);
    
    XCTAssertEqual(NSOrderedSame, [version1 compare:version2]);
    XCTAssertEqual(NSOrderedSame, [version2 compare:version1]);
    
    version1 = [[[Version alloc] initWithVersion:@"1.2.3"] autorelease];
    version2 = [[[Version alloc] initWithVersion:@"1.2.4"] autorelease];
    XCTAssertEqual(NSOrderedAscending, [version1 compare:version2]);
    XCTAssertEqual(NSOrderedDescending, [version2 compare:version1]);
    
    version1 = [[[Version alloc] initWithVersion:@"1.2.3"] autorelease];
    version2 = [[[Version alloc] initWithVersion:@"1.3.3"] autorelease];
    XCTAssertEqual(NSOrderedAscending, [version1 compare:version2]);
    XCTAssertEqual(NSOrderedDescending, [version2 compare:version1]);
    
    version1 = [[[Version alloc] initWithVersion:@"1.2.3"] autorelease];
    version2 = [[[Version alloc] initWithVersion:@"2.2.3"] autorelease];
    XCTAssertEqual(NSOrderedAscending, [version1 compare:version2]);
    XCTAssertEqual(NSOrderedDescending, [version2 compare:version1]);
}

@end
