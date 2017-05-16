//
//  KPKTestPerformance.m
//  MacPass
//
//  Created by Michael Starke on 21/10/15.
//  Copyright © 2015 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "KeePassKit.h"

NSUInteger const _kKPKEntryCount = 1000;

@interface KPKTestPerformance : XCTestCase {
  KPKEntry *testEntry;
  NSMutableDictionary *benchmarkDict;
}
@end

@implementation KPKTestPerformance

- (void)setUp {
  [super setUp];
  testEntry = [[KPKEntry alloc] init];
  benchmarkDict = [[NSMutableDictionary alloc] init];
  NSUInteger count = _kKPKEntryCount;
  while(count-- > 0) {
    [testEntry addCustomAttribute:[[KPKAttribute alloc] initWithKey:@(count).stringValue
                                                              value:@(count).stringValue]];
    benchmarkDict[@(count).stringValue] = @(count).stringValue;
  }
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the class.
  [super tearDown];
}

- (void)testAttributeLookupPerformanceA {
  [self measureBlock:^{
    id result = [testEntry customAttributeForKey:@(0).stringValue];
  }];
}
- (void)testDictLockupPerformanceA {
  [self measureBlock:^{
    id result = benchmarkDict[@(0).stringValue];
  }];
}

- (void)testAttributeLookupPerformanceB {
  [self measureBlock:^{
    id result = [testEntry customAttributeForKey:@(_kKPKEntryCount - 1).stringValue];
  }];
}
- (void)testDictLockupPerformanceB {
  [self measureBlock:^{
    id result = benchmarkDict[@(_kKPKEntryCount - 1).stringValue];
  }];
}

- (void)testAttributeLookupPerformanceC {
  [self measureBlock:^{
    [testEntry customAttributeForKey:kKPKTitleKey];
  }];
}

- (void)testCacheMissAfterKeyChange {
  KPKAttribute *attribute = testEntry.customAttributes[10];
  NSString *value = [attribute.value copy];
  NSString *changedKey = @"ChangedKey";
  attribute.key = changedKey;
  XCTAssertEqualObjects([testEntry customAttributeForKey:changedKey].value, value);
}


@end
