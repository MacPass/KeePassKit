//
//  KPKTestTypedNumber.m
//  KeePassKit
//
//  Created by Michael Starke on 13/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

@import XCTest;
@import KeePassKit;

@interface KPKTestKPKNumber : XCTestCase

@end

@implementation KPKTestKPKNumber

- (void)testTypedNumber {
  KPKNumber *int32 = [[KPKNumber alloc] initWithInteger32:INT32_MIN];
  XCTAssertEqual(INT32_MIN, int32.integer32Value, @"Value is INT32_MIN!");
  XCTAssertEqual(KPKNumberTypeInteger32, int32.type, @"Type is int32!");

  KPKNumber *uint32 = [[KPKNumber alloc] initWithUnsignedInteger32:UINT32_MAX];
  XCTAssertEqual(UINT32_MAX, uint32.unsignedInteger32Value, @"Value is UINT32_MAX!");
  XCTAssertEqual(KPKNumberTypeUnsignedInteger32, uint32.type, @"Type is uint32!");
  
  KPKNumber *int64 = [[KPKNumber alloc] initWithInteger64:INT64_MIN];
  XCTAssertEqual(INT64_MIN, int64.integer64Value, @"Value is INT64_MIN!");
  XCTAssertEqual(KPKNumberTypeInteger64, int64.type, @"Type is int64!");
  
  KPKNumber *uint64 = [[KPKNumber alloc] initWithUnsignedInteger64:UINT64_MAX];
  XCTAssertEqual(UINT64_MAX, uint64.unsignedInteger64Value, @"Value is UINT64_MAX!");
  XCTAssertEqual(KPKNumberTypeUnsignedInteger64, uint64.type, @"Tpye is uint64");
  
  KPKNumber *b = [[KPKNumber alloc] initWithBool:YES];
  XCTAssertEqual(YES, b.boolValue, @"Value is YES!");
  XCTAssertEqual(KPKNumberTypeBool, b.type, @"Tpye is bool");

  KPKNumber *one_int32 = [[KPKNumber alloc] initWithInteger32:1];
  XCTAssertEqual(1, one_int32.integer32Value, @"Value is 1");
  XCTAssertEqual(KPKNumberTypeInteger32, one_int32.type, @"Type is int32!");
  
  KPKNumber *one_uint32 = [[KPKNumber alloc] initWithUnsignedInteger32:1];
  XCTAssertEqual(1, one_uint32.unsignedInteger32Value, @"Value is 1");
  XCTAssertEqual(KPKNumberTypeUnsignedInteger32, one_uint32.type, @"Type is int32!");
  
  KPKNumber *one_int64 = [[KPKNumber alloc] initWithInteger64:1];
  XCTAssertEqual(1, one_int64.integer64Value, @"Value is 1");
  XCTAssertEqual(KPKNumberTypeInteger64, one_int64.type, @"Type is int64!");
  
  KPKNumber *one_uint64 = [[KPKNumber alloc] initWithUnsignedInteger64:1];
  XCTAssertEqual(1, one_uint64.unsignedInteger64Value, @"Value is 1");
  XCTAssertEqual(KPKNumberTypeUnsignedInteger64, one_uint64.type, @"Type is int32!");
}


@end
