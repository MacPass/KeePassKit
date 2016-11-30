//
//  KPKTestDeriveKeyData.m
//  KeePassKit
//
//  Created by Michael Starke on 01/11/2016.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KeePassKit/KeePassKit.h"
#import "NSData+KPKKeyComputation.h"
#import "NSData+CommonCrypto.h"

@interface KPKTestDeriveKeyData : XCTestCase

@end

@implementation KPKTestDeriveKeyData

- (void)testKeyResizing {
  NSData *data = [NSData kpk_dataWithRandomBytes:128];
  NSData *result = [data kpk_resizeKeyDataTo:32];
  XCTAssertEqualObjects(result, data.SHA256Hash);
  result = [data kpk_resizeKeyDataTo:64];
  XCTAssertEqualObjects(result, data.SHA512Hash);
  NSRange range = NSMakeRange(32, 64);
  result = [data kpk_resizeKeyDataRange:range toLength:32];
  XCTAssertEqualObjects(result, [data subdataWithRange:range].SHA256Hash);
  result = [data kpk_resizeKeyDataTo:50];
  XCTAssertEqualObjects(result, [data.SHA512Hash subdataWithRange:NSMakeRange(0, 50)]);
  result = [data kpk_resizeKeyDataTo:110];
}


@end
