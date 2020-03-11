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

- (void)testHmacOTP {
  /* Test values from https://tools.ietf.org/html/rfc4226#appendix-D */
  NSData *keyData = [@"12345678901234567890" dataUsingEncoding:NSUTF8StringEncoding];
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
  
  NSArray <NSNumber *> *decimalResults = @[ @1284755224,
                                            @1094287082,
                                            @137359152,
                                            @1726969429,
                                            @1640338314,
                                            @868254676,
                                            @1918287922,
                                            @82162583,
                                            @673399871,
                                            @645520489 ];
  
  NSArray <NSString *> *stringResults = @[ @"755224",
                                           @"287082",
                                           @"359152",
                                           @"969429",
                                           @"338314",
                                           @"254676",
                                           @"287922",
                                           @"162583",
                                           @"399871",
                                           @"520489" ];
  
  
  KPKOTPGenerator *generator = [[KPKOTPGenerator alloc] init];
  generator.key = keyData;
  generator.type = KPKOTPGeneratorHmacOTP;
  generator.hashAlgorithm = KPKOTPHashAlgorithmSha1;
  
  for(NSString *string in hexResults) {
    NSUInteger index = [hexResults indexOfObject:string];
    generator.counter = index;
    XCTAssertEqualObjects(string.kpk_dataFromHexString, generator.data);
  }
  
  for(NSNumber *number in decimalResults) {
    NSUInteger index = [decimalResults indexOfObject:number];
    generator.counter = index;
    NSUInteger hmacDecimal = generator.data.unsignedInteger;
    NSUInteger actual = number.unsignedIntegerValue;
    XCTAssertEqual(actual, hmacDecimal);
  }
  generator.numberOfDigits = 6;
  for(NSString *string in stringResults) {
    NSUInteger index = [stringResults indexOfObject:string];
    generator.counter = index;
    XCTAssertEqualObjects(string, generator.string);
  }
  
}

- (void)testTOTP {
  /* Test data base on https://tools.ietf.org/html/rfc6238#appendix-B */
  NSDictionary<NSNumber *, NSString *> *keyData = @{ @(KPKOTPHashAlgorithmSha1)   : @"12345678901234567890",
                                                     @(KPKOTPHashAlgorithmSha256) : @"12345678901234567890123456789012",
                                                     @(KPKOTPHashAlgorithmSha512) : @"1234567890123456789012345678901234567890123456789012345678901234" };
  
  NSDictionary *values = @{ @59          : @{ @(KPKOTPHashAlgorithmSha1)   : @"94287082",
                                              @(KPKOTPHashAlgorithmSha256) : @"46119246",
                                              @(KPKOTPHashAlgorithmSha512) : @"90693936" },
                            @1111111109  : @{ @(KPKOTPHashAlgorithmSha1)   : @"07081804",
                                              @(KPKOTPHashAlgorithmSha256) : @"68084774",
                                              @(KPKOTPHashAlgorithmSha512) : @"25091201" },
                            @1111111111  : @{ @(KPKOTPHashAlgorithmSha1)   : @"14050471",
                                              @(KPKOTPHashAlgorithmSha256) : @"67062674",
                                              @(KPKOTPHashAlgorithmSha512) : @"99943326" },
                            @1234567890  : @{ @(KPKOTPHashAlgorithmSha1)   : @"89005924",
                                              @(KPKOTPHashAlgorithmSha256) : @"91819424",
                                              @(KPKOTPHashAlgorithmSha512) : @"93441116" },
                            @2000000000  : @{ @(KPKOTPHashAlgorithmSha1)   : @"69279037",
                                              @(KPKOTPHashAlgorithmSha256) : @"90698825",
                                              @(KPKOTPHashAlgorithmSha512) : @"38618901" },
                            @20000000000 : @{ @(KPKOTPHashAlgorithmSha1)   : @"65353130",
                                              @(KPKOTPHashAlgorithmSha256) : @"77737706",
                                              @(KPKOTPHashAlgorithmSha512) : @"47863826" },
  };
  
  KPKOTPGenerator *generator = [[KPKOTPGenerator alloc] init];
  generator.type = KPKOTPGeneratorTOTP;
  generator.timeBase = 0;
  generator.timeSlice = 30;
  generator.numberOfDigits = 8;
  
  for(NSNumber *time in values) {
    generator.time = time.unsignedIntegerValue;
    NSDictionary *results = values[time];
    for(NSNumber *algorithm in results) {
      KPKOTPHashAlgorithm hash = (KPKOTPHashAlgorithm)algorithm.unsignedIntegerValue;
      generator.hashAlgorithm = hash;
      generator.key = [keyData[algorithm] dataUsingEncoding:NSUTF8StringEncoding];
      NSString *result = results[algorithm];
      XCTAssertEqualObjects(result, generator.string);
    }
  }
}

@end
