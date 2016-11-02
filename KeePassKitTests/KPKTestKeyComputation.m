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
  
  for(NSUInteger index = 0; index < sizeof(dataBytes); index++) {
    dataBytes[index] = 0x01;
  }
  
  for(NSUInteger index = 0; index < sizeof(keyBytes); index++) {
    keyBytes[index] = index;
  }
  
  NSData *key = [NSData dataWithBytesNoCopy:keyBytes length:sizeof(keyBytes) freeWhenDone:NO];
  NSData *data = [NSData dataWithBytesNoCopy:dataBytes length:sizeof(dataBytes) freeWhenDone:NO];
  
  NSData *hmac = [data headerHmacWithKey:key];
  
}

@end
