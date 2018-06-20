//
//  KPKTestDateAdditions.m
//  KeePassKitTests
//
//  Created by Michael Starke on 29.09.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KeePassKit_Private.h"

@interface KPKTestDateAdditions : XCTestCase
@property (strong) NSDateFormatter *dateFormatter;
@end

@implementation KPKTestDateAdditions

- (void)setUp {
  [super setUp];
  self.dateFormatter = [[NSDateFormatter alloc] init];
  self.dateFormatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'";
  self.dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
}

- (void)tearDown {
  [super tearDown];
}

- (void)testKdbxDateFormat {
  NSDate *date = [NSDate date];
  NSDate *lowPrecisionDate = [NSDate dateWithTimeIntervalSinceReferenceDate:floor(date.timeIntervalSinceReferenceDate)];
  XCTAssertEqualObjects(date.kpk_UTCString, [self.dateFormatter stringFromDate:date]);

  NSLog(@"%@", [self.dateFormatter dateFromString:date.kpk_UTCString]);
  NSLog(@"%@", [NSDate kpk_dateFromUTCString:date.kpk_UTCString]);
  XCTAssertEqualObjects([self.dateFormatter dateFromString:date.kpk_UTCString], [NSDate kpk_dateFromUTCString:date.kpk_UTCString]);
  XCTAssertEqualObjects(lowPrecisionDate, [self.dateFormatter dateFromString:date.kpk_UTCString]);
  XCTAssertEqualObjects(lowPrecisionDate, [NSDate kpk_dateFromUTCString:date.kpk_UTCString]);
}

- (void)testDateFormatterPerformance {
  NSDate *date = [NSDate date];
  [self measureBlock:^{
  XCTAssertNotNil([self.dateFormatter dateFromString:date.kpk_UTCString]);
  }];
}

- (void)testDateAdditionPerformance {
  NSDate *date = [NSDate date];
  [self measureBlock:^{
  XCTAssertNotNil([NSDate kpk_dateFromUTCString:date.kpk_UTCString]);
  }];
}


@end
