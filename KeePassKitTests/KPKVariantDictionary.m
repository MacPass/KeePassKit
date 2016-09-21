//
//  KPKVariantDictionary.m
//  KeePassKit
//
//  Created by Michael Starke on 21/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>
@import KeePassKit;

@interface KPKVariantDictionary : XCTestCase

@end

@implementation KPKVariantDictionary

- (void)setUp {
  [super setUp];
  // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the class.
  [super tearDown];
}

- (void)testInvalidContent {
  XCTAssertTrue( @{ @"String" : @"String" }.isValidVariantDictionary );
  XCTAssertTrue( @{ @"String" : [[NSMutableString alloc] init] }.isValidVariantDictionary );
  XCTAssertTrue( @{ @"Number" : [KPKNumber numberWithBool:NO] }.isValidVariantDictionary );
  XCTAssertTrue( @{ @"Data" : [NSData data] }.isValidVariantDictionary );
  XCTAssertTrue( @{ @"Data" : [NSMutableData data] }.isValidVariantDictionary );
  
  XCTAssertFalse( @{ @(1) : @"" }.isValidVariantDictionary, @"Number as key is not allowed" );
  XCTAssertFalse( @{ [NSData data] : @"" }.isValidVariantDictionary, @"Data as key is not allowed" );
  XCTAssertFalse( @{ [KPKNumber numberWithBool:YES] : @"" }.isValidVariantDictionary, @"Data as key is not allowed" );
  
  
  uint8_t bytes[] = {0,1,2,3};
  NSDictionary *dict =  @{ @"1" : @"String",
                           @"2" : [KPKNumber numberWithBool:NO],
                           @"3" : [KPKNumber numberWithInteger32:-32],
                           @"4" : [KPKNumber numberWithUnsignedInteger32:32],
                           @"3" : [NSData dataWithBytes:bytes length:4] };

  XCTAssertTrue(dict.isValidVariantDictionary);
  NSData *data = dict.variantDictionaryData;
  XCTAssertNotNil(data);
  NSDictionary *dictFromData = [[NSDictionary alloc] initWithVariantDictionaryData:data];
  XCTAssertEqual(dict.count, dictFromData.count);
  for(NSString *key in dict) {
    XCTAssertNotNil(dictFromData[key]);
    XCTAssertEqualObjects(dictFromData[key], dict[key]);
  }
}

@end
