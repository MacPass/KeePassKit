//
//  KPKTestKeyComputation.m
//  KeePassKit
//
//  Created by Michael Starke on 02/11/2016.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSData+KPKKeyComputation.h"

@interface KPKTestKeyComputation : XCTestCase

@end

@implementation KPKTestKeyComputation

- (void)testHeaderHmac {
  uint8_t dataBytes[64] = {0x00};
  uint8_t keyBytes[32] = {0x00};
  uint8_t hmacBytes[32] = {
    0xe9, 0xec, 0xbb, 0xe4,
    0xbe, 0x33, 0x2d, 0x73,
    0x87, 0x4b, 0xc4, 0xd1,
    0x31, 0xcc, 0x86, 0x2b,
    0x5c, 0xc0, 0xe7, 0x07,
    0x18, 0x45, 0x48, 0x99,
    0x14, 0xaa, 0x41, 0x9d,
    0xfd, 0x77, 0xed, 0xdb
  };
  
  for(NSUInteger index = 0; index < sizeof(dataBytes); index++) {
    dataBytes[index] = 0x01;
  }
  
  for(NSUInteger index = 0; index < sizeof(keyBytes); index++) {
    keyBytes[index] = index;
  }
  
  NSData *key = [NSData dataWithBytesNoCopy:keyBytes length:sizeof(keyBytes) freeWhenDone:NO];
  NSData *data = [NSData dataWithBytesNoCopy:dataBytes length:sizeof(dataBytes) freeWhenDone:NO];
  
  NSData *hmac = [data kpk_headerHmacWithKey:key];
  XCTAssertEqual(hmac.length, 32);
  XCTAssertEqual(0, memcmp(hmac.bytes, hmacBytes, 32));
}

@end
