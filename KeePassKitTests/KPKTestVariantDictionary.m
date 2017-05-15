//
//  KPKVariantDictionary.m
//  KeePassKit
//
//  Created by Michael Starke on 21/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "KeePassKit/KeePassKit.h"

@interface KPKTestVariantDictionary : XCTestCase

@end

@implementation KPKTestVariantDictionary

- (void)setUp {
  [super setUp];
  // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the class.
  [super tearDown];
}

- (void)testInvalidContent {
  XCTAssertTrue( @{ @"String" : @"String" }.kpk_isValidVariantDictionary );
  XCTAssertTrue( @{ @"String" : [[NSMutableString alloc] init] }.kpk_isValidVariantDictionary );
  XCTAssertTrue( @{ @"Number" : [KPKNumber numberWithBool:NO] }.kpk_isValidVariantDictionary );
  XCTAssertTrue( @{ @"Data" : [NSData data] }.kpk_isValidVariantDictionary );
  XCTAssertTrue( @{ @"Data" : [NSMutableData data] }.kpk_isValidVariantDictionary );
  
  XCTAssertFalse( @{ @(1) : @"" }.kpk_isValidVariantDictionary, @"Number as key is not allowed" );
  XCTAssertFalse( @{ [NSData data] : @"" }.kpk_isValidVariantDictionary, @"Data as key is not allowed" );
  XCTAssertFalse( @{ [KPKNumber numberWithBool:YES] : @"" }.kpk_isValidVariantDictionary, @"Data as key is not allowed" );
  
  
  uint8_t bytes[] = {0,1,2,3};
  NSDictionary *dict =  @{ @"1" : @"String",
                           @"2" : [KPKNumber numberWithBool:NO],
                           @"3" : [KPKNumber numberWithInteger32:-32],
                           @"4" : [KPKNumber numberWithUnsignedInteger32:32],
                           @"5" : [NSData dataWithBytes:bytes length:4] };
  
  XCTAssertTrue(dict.kpk_isValidVariantDictionary);
  NSData *data = dict.kpk_variantDictionaryData;
  XCTAssertNotNil(data);
  NSDictionary *dictFromData = [[NSDictionary alloc] initWithVariantDictionaryData:data];
  XCTAssertEqual(dict.count, dictFromData.count);
  for(NSString *key in dict) {
    XCTAssertNotNil(dictFromData[key]);
    XCTAssertEqualObjects(dictFromData[key], dict[key]);
  }
}

- (void)testInvalidParameters {
  NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
  
  [dict setData:[NSData data] forKey:@"Data"];
  XCTAssertThrows([dict setData:(id)@"No Data" forKey:@"NoData"]);
  
  [dict setString:@"String" forKey:@"String"];
  XCTAssertThrows([dict setString:(id)[NSData data] forKey:@"NoString"]);
}

@end
