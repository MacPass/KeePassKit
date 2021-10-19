//
//  KPKTestNSURL+KPKAddtions.m
//  KeePassKitTests macOS
//
//  Created by Michael Starke on 07.12.20.
//  Copyright © 2020 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSURL+KPKAdditions.h"
#import "NSData+KPKRandom.h"
#import "NSData+KPKBase32.h"

@interface KPKTestNSURL_KPKAddtions : XCTestCase

@end

@implementation KPKTestNSURL_KPKAddtions

- (void)testTimeOTPInit {
  NSData *keyData = [@"0123456789" dataUsingEncoding:NSUTF8StringEncoding];
  KPKOTPHashAlgorithm hashAlgorithm = KPKOTPHashAlgorithmSha1;
  NSInteger period = 0;
  NSInteger digits = 6;
  NSString *issuer = @"Title:me@domain.com";
  
  NSURL *totpURL = [NSURL URLWithTimeOTPKey:keyData algorithm:hashAlgorithm issuer:issuer period:period digits:digits];
  XCTAssertNotNil(totpURL);
  XCTAssertEqualObjects(totpURL.issuer, issuer);
  XCTAssertEqualObjects(totpURL.key, keyData);
  XCTAssertEqual(totpURL.period, period);
  XCTAssertEqual(totpURL.digits, digits);
}

- (void)testSteamOTPInit {
  NSData *keyData = [@"0123456789" dataUsingEncoding:NSUTF8StringEncoding];
  NSString *issuer = @"Title:me@domain.com";
  
  NSURL *steamOTPURL = [NSURL URLWIthSteamOTPKey:keyData issuer:issuer];
  XCTAssertNotNil(steamOTPURL);
  XCTAssertEqualObjects(steamOTPURL.issuer, issuer);
  XCTAssertEqualObjects(steamOTPURL.key, keyData);
  XCTAssertEqualObjects(steamOTPURL.encoder, @"steam");
  XCTAssertEqual(steamOTPURL.period, 30);
  XCTAssertEqual(steamOTPURL.digits, 5);
  
}

- (void)testInvalidScheme {
    NSData *keyData = [NSData kpk_dataWithRandomBytes:10];
    NSUInteger period = 30;
    NSUInteger digits = 8;
    NSString *urlString = [NSString stringWithFormat:@"nototpauth://totp/title:user@domain.com?secret=%@&issuer=titleuserdomaincom&period=%ld&algorithm=sha256&digits=%ld", [keyData base32EncodedStringWithOptions:KPKBase32EncodingOptionNoPadding], period, digits];
    NSURL *timeURL = [NSURL URLWithString:urlString];
    XCTAssertNotNil(timeURL);
    XCTAssertFalse(timeURL.isTimeOTPURL);
    XCTAssertFalse(timeURL.isHmacOTPURL);
}
- (void)testInvalidURL {
  NSString *urlString = @"ThisIsNotAnURL";
  NSURL *url = [NSURL URLWithString:urlString];
}

- (void)testTimeOTPURLProperties {
  NSData *keyData = [NSData kpk_dataWithRandomBytes:10];
  NSUInteger period = 30;
  NSUInteger digits = 8;
  KPKOTPHashAlgorithm algoritm = KPKOTPHashAlgorithmSha256;
  NSString *urlString = [NSString stringWithFormat:@"otpauth://totp/title:user@domain.com?secret=%@&issuer=titleuserdomaincom&period=%ld&algorithm=sha256&digits=%ld", [keyData base32EncodedStringWithOptions:KPKBase32EncodingOptionNoPadding], period, digits];
  NSURL *timeURL = [NSURL URLWithString:urlString];
  XCTAssertNotNil(timeURL);
  XCTAssertTrue(timeURL.isTimeOTPURL);
  XCTAssertFalse(timeURL.isHmacOTPURL);
  XCTAssertEqual(timeURL.digits, digits);
  XCTAssertEqual(timeURL.hashAlgorithm, algoritm);
  XCTAssertEqual(timeURL.period, period);
  XCTAssertEqualObjects(timeURL.key, keyData);
}

- (void)testTimeOTPURLWithPaddingProperties {
  NSData *keyData = [NSData kpk_dataWithRandomBytes:11];
  NSUInteger period = 30;
  NSUInteger digits = 8;
  KPKOTPHashAlgorithm algoritm = KPKOTPHashAlgorithmSha256;
  
  NSString *secretString = [[keyData base32EncodedStringWithOptions:0] stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet];
  
  NSString *urlString = [NSString stringWithFormat:@"otpauth://totp/title:user@domain.com?secret=%@&issuer=titleuserdomaincom&period=%ld&algorithm=sha256&digits=%ld", secretString, period, digits];
  NSURL *timeURL = [NSURL URLWithString:urlString];
  XCTAssertNotNil(timeURL);
  XCTAssertTrue(timeURL.isTimeOTPURL);
  XCTAssertFalse(timeURL.isHmacOTPURL);
  XCTAssertEqual(timeURL.digits, digits);
  XCTAssertEqual(timeURL.hashAlgorithm, algoritm);
  XCTAssertEqual(timeURL.period, period);
  XCTAssertEqualObjects(timeURL.key, keyData);
}

- (void)testHmacOTPURLProperties {
  NSData *keyData = [NSData kpk_dataWithRandomBytes:10];
  NSUInteger counter = 999;
  NSUInteger digits = 8;
  KPKOTPHashAlgorithm algoritm = KPKOTPHashAlgorithmSha1;
  NSString *urlString = [NSString stringWithFormat:@"otpauth://hotp/title:user@domain.com?secret=%@&issuer=titleuserdomaincom&counter=%ld&algorithm=sha1&digits=%ld", [keyData base32EncodedStringWithOptions:KPKBase32EncodingOptionNoPadding], counter, digits];
  NSURL *timeURL = [NSURL URLWithString:urlString];
  XCTAssertNotNil(timeURL);
  XCTAssertFalse(timeURL.isTimeOTPURL);
  XCTAssertTrue(timeURL.isHmacOTPURL);
  XCTAssertEqual(timeURL.digits, digits);
  XCTAssertEqual(timeURL.hashAlgorithm, algoritm);
  XCTAssertEqual(timeURL.counter, counter);
  XCTAssertEqualObjects(timeURL.key, keyData);
}



@end
