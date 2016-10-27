//
//  KPKHashedDataTest.m
//  MacPass
//
//  Created by Michael Starke on 08.08.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

@import XCTest;

#import "KeePassKit.h"

@interface KPKTestHashedData : XCTestCase

@end

@implementation KPKTestHashedData

- (void)testSHA256Hashing {
  NSData *data = [NSData dataWithRandomBytes:10000];
  NSData *hashedData = data.hashedSha256Data;
  NSData *unhashedData = hashedData.unhashedSha256Data;
  XCTAssertTrue([unhashedData isEqualToData:data], @"Data needs to be the same after hashing and unhashing");
}
@end
