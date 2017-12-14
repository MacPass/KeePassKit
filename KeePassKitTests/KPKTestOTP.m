//
//  KPKTestOTP.m
//  KeePassKit
//
//  Created by Michael Starke on 10.12.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSString+KPKHexdata.h"
#import "KPKOTPGenerator.h"

@interface KPKTestOTP : XCTestCase

@end

@implementation KPKTestOTP

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testHmacOTP {
  uint8_t key[] = {
    0x31, 0x32, 0x33, 0x34,
    0x35, 0x36, 0x37, 0x38,
    0x39, 0x30, 0x31, 0x32,
    0x33, 0x34, 0x35, 0x36,
    0x37, 0x38, 0x39, 0x30 };

  NSData *keyData = [NSData dataWithBytesNoCopy:key length:sizeof(key) freeWhenDone:NO];
  NSArray <NSString *> *hexResults = @[ @"4c93cf18",
                                     @"41397eea",
                                     @"82fef30",
                                     @"66ef7655",
                                     @"61c5938a",
                                     @"33c083d4",
                                     @"7256c032",
                                     @"4e5b397",
                                     @"2823443f",
                                     @"2679dc69" ];
  
  NSArray <NSNumber *> *decimalResults= @[ @1284755224,
                                           @1094287082,
                                           @137359152,
                                           @1726969429,
                                           @1640338314,
                                           @868254676,
                                           @1918287922,
                                           @82162583,
                                           @673399871,
                                           @645520489 ];

  
  for(NSString *string in hexResults) {
    NSUInteger index = [hexResults indexOfObject:string];
    NSData *hmacOTP = [KPKOTPGenerator HMACOTPWithKey:keyData counter:index];
    NSData *actual = string.kpk_dataFromHexString;
    XCTAssertEqualObjects(actual, hmacOTP);
  }

  for(NSNumber *number in decimalResults) {
    NSUInteger index = [decimalResults indexOfObject:number];
    NSData *hmacOTP = [KPKOTPGenerator HMACOTPWithKey:keyData counter:index];
    NSUInteger hmacDecimal = hmacOTP.unsignedInteger;
    NSUInteger actual = number.unsignedIntegerValue;
    XCTAssertEqual(actual, hmacDecimal);
  }

}

/* Table 2 details for each count the truncated values (both in
 hexadecimal and decimal) and then the HOTP value.
 
 Truncated
 Count    Hexadecimal    Decimal        HOTP
 0        4c93cf18       1284755224     755224
 1        41397eea       1094287082     287082
 2         82fef30        137359152     359152
 3        66ef7655       1726969429     969429
 4        61c5938a       1640338314     338314
 5        33c083d4        868254676     254676
 6        7256c032       1918287922     287922
 7         4e5b397         82162583     162583
 8        2823443f        673399871     399871
 9        2679dc69        645520489     520489
 
 
 */

@end
