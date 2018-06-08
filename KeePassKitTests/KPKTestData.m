//
//  KPKTestData.m
//  KeePassKit
//
//  Created by Michael Starke on 07.04.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "KeePassKit.h"
#import "KeePassKit_Private.h"

@interface KPKTestData : XCTestCase

@end

@implementation KPKTestData

- (void)testDataStorage {
  NSData *randomData = [NSData kpk_dataWithRandomBytes:1024];
  KPKData *data = [[KPKData alloc] initWithData:randomData];
  XCTAssertEqualObjects(data.data, randomData);
  
  data = [[KPKData alloc] init];
  XCTAssertNil(data.data);
  data.data = randomData;
  XCTAssertEqualObjects(data.data, randomData);
}

- (void)testDataUpdate {
  KPKData *data =   data = [[KPKData alloc] init];
  XCTAssertNil(data.data);
  
  NSData *randomData = [NSData kpk_dataWithRandomBytes:1024];
  data.data = randomData;
  XCTAssertEqualObjects(data.data, randomData);

  NSData *randomData2 = [NSData kpk_dataWithRandomBytes:512];
  data.data = randomData2;
  XCTAssertEqualObjects(data.data, randomData2);
}

- (void)testDataProtection {
  NSData *randomData = [NSData kpk_dataWithRandomBytes:1024];
  KPKData *data = [[KPKData alloc] initWithData:randomData];
  
  XCTAssertEqual(data.length, randomData.length);
  XCTAssertNotEqualObjects(data.xoredData, randomData);
  XCTAssertNotEqualObjects(data.xorPad, randomData);
}

- (void)testDataPerformance {
  KPKData *data = [[KPKData alloc] initWithData:[NSData kpk_dataWithRandomBytes:1024*1024]];
  [self measureBlock:^{
    for(NSUInteger count = 0; count < 100; count++) {
      XCTAssertNotNil(data.data);
    }
  }];
}

@end
