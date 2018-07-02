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
  NSData *data = [NSData kpk_dataWithRandomBytes:1024*1024*8 + 512]; // 8 MB Data, to use more than one block
  NSData *hashedData = data.kpk_hashedSha256Data;
  NSData *unhashedData = hashedData.kpk_unhashedSha256Data;
  XCTAssertTrue([unhashedData isEqualToData:data], @"Data needs to be the same after hashing and unhashing");
}

- (void)testHmacSha256HashingUnalignedBlock {
  /* use more than 1 block of unaligned data */
  NSData *data = [NSData kpk_dataWithRandomBytes:1024*1024*8 + 512];
  NSData *key = [NSData kpk_dataWithRandomBytes:64];
  NSError *error;
  NSData *hashedData = [data kpk_hashedHmacSha256DataWithKey:key error:&error];
  NSData *unhashedData = [hashedData kpk_unhashedHmacSha256DataWithKey:key error:&error];
  XCTAssertEqualObjects(data, unhashedData, @"Hashed and unhashed data are the same");
}

- (void)testHmacSha256HashingLessThanBlock {
  NSData *data = [NSData kpk_dataWithRandomBytes:512]; // exactly one block
  NSData *key = [NSData kpk_dataWithRandomBytes:64];
  NSError *error;
  NSData *hashedData = [data kpk_hashedHmacSha256DataWithKey:key error:&error];
  NSData *unhashedData = [hashedData kpk_unhashedHmacSha256DataWithKey:key error:&error];
  XCTAssertEqualObjects(data, unhashedData, @"Hashed and unhashed data are the same");
}

- (void)testHmacSha256HashingAlignedBlock {
  NSData *data = [NSData kpk_dataWithRandomBytes:1024*1024]; // exactly one block
  NSData *key = [NSData kpk_dataWithRandomBytes:64];
  NSError *error;
  NSData *hashedData = [data kpk_hashedHmacSha256DataWithKey:key error:&error];
  NSData *unhashedData = [hashedData kpk_unhashedHmacSha256DataWithKey:key error:&error];
  XCTAssertEqualObjects(data, unhashedData, @"Hashed and unhashed data are the same");
}

- (void)testSHA256HashingPerformance {
  NSData *data = [NSData kpk_dataWithRandomBytes:1024*1024*8 + 512]; // 8 MB Data, to use more than one block
  [self measureBlock:^{
    XCTAssertNotNil(data.kpk_hashedSha256Data);
  }];
}

- (void)testSHA256UnhashingPerformance {
  NSData *data = [NSData kpk_dataWithRandomBytes:1024*1024*8 + 512]; // 8 MB Data, to use more than one block
  NSData *hashedData = data.kpk_hashedSha256Data;
  [self measureBlock:^{
    XCTAssertNotNil(hashedData.kpk_unhashedSha256Data);
  }];
}

- (void)testHmacSha256HashingPerformance {
  NSData *data = [NSData kpk_dataWithRandomBytes:1024*1024*8 + 512];
  NSData *key = [NSData kpk_dataWithRandomBytes:64];
  [self measureBlock:^{
    XCTAssertNotNil([data kpk_hashedHmacSha256DataWithKey:key error:nil]);
  }];
}

- (void)testHmacSha256UnhashingPerformance {
  NSData *data = [NSData kpk_dataWithRandomBytes:1024*1024*8 + 512];
  NSData *key = [NSData kpk_dataWithRandomBytes:64];
  NSData *hashedData = [data kpk_hashedHmacSha256DataWithKey:key error:nil];
  [self measureBlock:^{
    XCTAssertNotNil([hashedData kpk_unhashedHmacSha256DataWithKey:key error:nil]);
  }];
}



@end
