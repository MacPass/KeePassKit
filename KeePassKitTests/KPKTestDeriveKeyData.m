//
//  KPKTestDeriveKeyData.m
//  KeePassKit
//
//  Created by Michael Starke on 01/11/2016.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSData+KPKResize.h"
#import "NSData+Random.h"
#import "NSData+CommonCrypto.h"

@interface KPKTestDeriveKeyData : XCTestCase

@end

@implementation KPKTestDeriveKeyData

- (void)testExample {
  NSData *data = [NSData dataWithRandomBytes:128];
  NSData *result = [data deriveKeyWithLength:32 fromRange:NSMakeRange(0,128)];
  XCTAssertEqualObjects(result, data.SHA256Hash);
  result = [data deriveKeyWithLength:64 fromRange:NSMakeRange(0, 128)];
  XCTAssertEqualObjects(result, data.SHA512Hash);
  NSRange range = NSMakeRange(32, 64);
  result = [data deriveKeyWithLength:32 fromRange:range];
  XCTAssertEqualObjects(result, [data subdataWithRange:range].SHA256Hash);
  result = [data deriveKeyWithLength:50 fromRange:NSMakeRange(0, 128)];
  XCTAssertEqualObjects(result, [data.SHA512Hash subdataWithRange:NSMakeRange(0, 50)]);
  result = [data deriveKeyWithLength:110 fromRange:NSMakeRange(0, 128)];
}


@end
