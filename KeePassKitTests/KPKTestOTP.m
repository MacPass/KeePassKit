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
#import "KPKHmacOTPGenerator.h"
#import "KPKTimeOTPGenerator.h"
#import "KPKSteamOTPGenerator.h"
#import "NSURL+KPKAdditions.h"
#import "KPKEntry.h"
#import "KPKAttribute.h"

@interface KPKTestOTP : XCTestCase

@end

@implementation KPKTestOTP

- (void)testDefaultTimeGenerator {
  KPKTimeOTPGenerator *generator = [[KPKTimeOTPGenerator alloc] init];
  XCTAssertNotNil(generator.key);
  XCTAssertEqual(generator.key.length, 0);
  XCTAssertEqual(generator.hashAlgorithm, KPKOTPHashAlgorithmSha1);
  XCTAssertEqual(generator.defaultHashAlgoritm, KPKOTPHashAlgorithmSha1);
  XCTAssertEqual(generator.numberOfDigits, 6);
  XCTAssertEqual(generator.defaultNumberOfDigits, 6);
  XCTAssertEqual(generator.time, 0);
  XCTAssertEqual(generator.timeSlice, 30);
  XCTAssertEqual(generator.defaultTimeSlice, 30);
  XCTAssertEqual(generator.timeBase, 0);
}

- (void)testDefaultSteamGenerator {
  KPKHmacOTPGenerator *generator = [[KPKHmacOTPGenerator alloc] init];
  XCTAssertNotNil(generator.key);
  XCTAssertEqual(generator.key.length, 0);
  XCTAssertEqual(generator.hashAlgorithm, KPKOTPHashAlgorithmSha1);
  XCTAssertEqual(generator.defaultHashAlgoritm, KPKOTPHashAlgorithmSha1);
  XCTAssertEqual(generator.counter, 0);
}

- (void)testDefaultHmacGenerator {
  KPKSteamOTPGenerator *generator = [[KPKSteamOTPGenerator alloc] init];
  XCTAssertNotNil(generator.key);
  XCTAssertEqual(generator.key.length, 0);
  XCTAssertEqual(generator.hashAlgorithm, KPKOTPHashAlgorithmSha1);
  XCTAssertEqual(generator.defaultHashAlgoritm, KPKOTPHashAlgorithmSha1);
  XCTAssertEqual(generator.numberOfDigits, 5);
  XCTAssertEqual(generator.defaultNumberOfDigits, 5);
  XCTAssertEqual(generator.time, 0);
  XCTAssertEqual(generator.timeSlice, 30);
  XCTAssertEqual(generator.defaultTimeSlice, 30);
  XCTAssertEqual(generator.timeBase, 0);
}

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
  
  
  KPKHmacOTPGenerator *generator = [[KPKHmacOTPGenerator alloc] init];
  generator.key = keyData;
  generator.hashAlgorithm = KPKOTPHashAlgorithmSha1;
  
  for(NSString *string in hexResults) {
    NSUInteger index = [hexResults indexOfObject:string];
    generator.counter = index;
    XCTAssertEqualObjects(string.kpk_dataFromHexString, generator.data);
  }
  
  for(NSNumber *number in decimalResults) {
    NSUInteger index = [decimalResults indexOfObject:number];
    generator.counter = index;
    NSUInteger hmacDecimal = generator.data.kpk_unsignedInteger;
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

- (void)testHmacOTPWithEmpyKey {
  KPKHmacOTPGenerator *generator = [[KPKHmacOTPGenerator alloc] init];
  NSString *string = generator.string;
  XCTAssertNotNil(string);
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
  
  KPKTimeOTPGenerator *generator = [[KPKTimeOTPGenerator alloc] init];
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

- (void)testURLTimeOTPParsing {
  KPKEntry *entry = [[KPKEntry alloc] init];
  NSData *keyData = [@"ThisIsMySecret" dataUsingEncoding:NSUTF8StringEncoding];
  NSString *issuer = @"KeePassKitTest:me@test.com";
  NSInteger period = 30;
  NSInteger digits = 6;
  KPKOTPHashAlgorithm algorithm = KPKOTPHashAlgorithmSha1;
  
  NSURL *otpURL = [NSURL URLWithTimeOTPKey:keyData algorithm:algorithm issuer:issuer period:period digits:digits];
  XCTAssertNotNil(otpURL);
    
  
  KPKAttribute *otpAttribute = [[KPKAttribute alloc] initWithKey:kKPKAttributeKeyOTPOAuthURL value:otpURL.absoluteString];
  [entry addCustomAttribute:otpAttribute];
  
  KPKTimeOTPGenerator *totpGenerator = [[KPKTimeOTPGenerator alloc] initWithAttributes:entry.attributes];
  XCTAssertNotNil(totpGenerator);
  XCTAssertEqualObjects(totpGenerator.key, keyData);
  XCTAssertEqual(totpGenerator.hashAlgorithm, algorithm);
  XCTAssertEqual(totpGenerator.timeSlice, period);
  XCTAssertEqual(totpGenerator.numberOfDigits, digits);
}

- (void)testHmacCounterUpdate {
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
    
  KPKEntry *entry = [[KPKEntry alloc] init];
  NSString *keyString = @"12345678901234567890";

  KPKAttribute *secret = [[KPKAttribute alloc] initWithKey:kKPKAttributeKeyHmacOTPSecret value:keyString];
  [entry addCustomAttribute:secret];
  
  XCTAssertTrue(entry.hasHmacOTP);
  XCTAssertFalse(entry.hasTimeOTP);
  
  NSUInteger counter = 0;
  for(NSString *string in stringResults) {
    KPKAttribute *counterAttribute = [entry attributeWithKey:kKPKAttributeKeyHmacOTPCounter];
    XCTAssertEqual(counterAttribute.evaluatedValue.integerValue, counter);
    
    NSString *hmac = [entry generateHmacOTPUpdateCounter:YES];
    counter++;
    
    XCTAssertEqualObjects(string, hmac);
    /* search the attribute again, since we might have added it */
    counterAttribute = [entry attributeWithKey:kKPKAttributeKeyHmacOTPCounter];
    XCTAssertEqual(counterAttribute.evaluatedValue.integerValue, counter);
  }
  
}

- (void)testEntryOTPproperties {
  KPKEntry *entry = [[KPKEntry alloc] init];
  KPKAttribute *otpAttribute = [[KPKAttribute alloc] initWithKey:kKPKAttributeKeyOTPOAuthURL value:@"This-is-no-valid-URL"];
  [entry addCustomAttribute:otpAttribute];
  
  XCTAssertFalse(entry.hasTimeOTP);
  XCTAssertFalse(entry.hasHmacOTP);
}

/*
- (void)testTimeOTPEntry {
  KPKEntry *entry = [[KPKEntry alloc] init];
  NSData *keyData = [@"12345678901234567890" dataUsingEncoding:NSUTF8StringEncoding];
  NSString *issuer = @"KeePassKitTest:me@test.com";
  NSInteger period = 30;
  NSInteger digits = 6;
  KPKOTPHashAlgorithm algorithm = KPKOTPHashAlgorithmSha1;
  
  NSURL *otpURL = [NSURL URLWithTimeOTPKey:keyData algorithm:algorithm issuer:issuer period:period digits:digits];
  XCTAssertNotNil(otpURL);
    
  
  KPKAttribute *otpAttribute = [[KPKAttribute alloc] initWithKey:kKPKAttributeKeyOTPOAuthURL value:otpURL.absoluteString];
  [entry addCustomAttribute:otpAttribute];
  
  // since the entry uses the current time to generate the TOPT code we need ot construct the code with the same time
  KPKTimeOTPGenerator *generator = [[KPKTimeOTPGenerator alloc] init];
  generator.key = keyData;
  generator.numberOfDigits = digits;
  generator.timeSlice = period;
  
  XCTAssertFalse(entry.hasHmacOTP);
  XCTAssertTrue(entry.hasTimeOTP);
  
  generator.time = NSDate.date.timeIntervalSince1970;
  XCTAssertEqualObjects(entry.timeOTP, generator.string);
}
*/

@end
