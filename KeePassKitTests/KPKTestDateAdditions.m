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
  XCTAssertEqualObjects(date.kpk_kdbxString, [self.dateFormatter stringFromDate:date]);

  NSLog(@"%@", [self.dateFormatter dateFromString:date.kpk_kdbxString]);
  NSLog(@"%@", [NSDate kpk_dateFromKdbxString:date.kpk_kdbxString]);
  XCTAssertEqualObjects([self.dateFormatter dateFromString:date.kpk_kdbxString], [NSDate kpk_dateFromKdbxString:date.kpk_kdbxString]);
}


@end
