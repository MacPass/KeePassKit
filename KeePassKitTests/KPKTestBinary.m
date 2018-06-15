//
//  KPKTestBinary.m
//  KeePassKit
//
//  Created by Michael Starke on 15.06.18.
//  Copyright © 2018 HicknHack Software GmbH. All rights reserved.
//

@import XCTest;
@import KeePassKit;

@interface KPKTestBinary : XCTestCase

@end

@implementation KPKTestBinary

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    [super tearDown];
}

- (void)testBinaryEquality {
  NSData *randomData = [NSData kpk_dataWithRandomBytes:1024*1024+10];
  KPKBinary *binary1 = [[KPKBinary alloc] initWithName:@"binary1" data:randomData];
  KPKBinary *binary2 = [[KPKBinary alloc] initWithName:@"binary1" data:randomData];
  XCTAssertEqualObjects(binary1, binary2);
  
  binary1.protect = YES;
  XCTAssertEqualObjects(binary1.data, binary2.data);

  binary2.protect = YES;
  XCTAssertEqualObjects(binary1, binary2);
}

@end
