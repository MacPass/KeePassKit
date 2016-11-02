//
//  KPKTestDeriveKeyData.m
//  KeePassKit
//
//  Created by Michael Starke on 01/11/2016.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSData+KPKKeyComputation.h"
#import "NSData+Random.h"
#import "NSData+CommonCrypto.h"

@interface KPKTestDeriveKeyData : XCTestCase

@end

@implementation KPKTestDeriveKeyData

- (void)testKeyResizing {
  NSData *data = [NSData dataWithRandomBytes:128];
  NSData *result = [data resizeKeyDataTo:32];
  XCTAssertEqualObjects(result, data.SHA256Hash);
  result = [data resizeKeyDataTo:64];
  XCTAssertEqualObjects(result, data.SHA512Hash);
  NSRange range = NSMakeRange(32, 64);
  result = [data resizeKeyDataRange:range toLength:32];
  XCTAssertEqualObjects(result, [data subdataWithRange:range].SHA256Hash);
  result = [data resizeKeyDataTo:50];
  XCTAssertEqualObjects(result, [data.SHA512Hash subdataWithRange:NSMakeRange(0, 50)]);
  result = [data resizeKeyDataTo:110];
}


@end
