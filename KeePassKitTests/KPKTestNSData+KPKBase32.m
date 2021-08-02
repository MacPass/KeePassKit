//
//  KPKTestNSData+KPKBase32.m
//  KeePassKitTests macOS
//
//  Created by Michael Starke on 01.11.19.
//  Copyright © 2019 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KeePassKit.h"
#import "KeePassKit_Private.h"

@interface KPKTestNSData_KPKBase32 : XCTestCase

@end

@implementation KPKTestNSData_KPKBase32


- (void)testBase32EncodingDecoding {
  for(NSUInteger dataLenght = 1; dataLenght < 128; dataLenght++) {
    NSData *data = [NSData kpk_dataWithRandomBytes:dataLenght];
    NSString *base32 = [data base32EncodedStringWithOptions:0];
    NSData *decodedData = [[NSData alloc] initWithBase32EncodedString:base32];
    XCTAssertEqualObjects(data, decodedData);
  }
}

- (void)testBase32HexEncodingDecoding {
  for(NSUInteger dataLenght = 1; dataLenght < 128; dataLenght++) {
    NSData *data = [NSData kpk_dataWithRandomBytes:dataLenght];
    NSString *base32Hex = [data base32EncodedStringWithOptions:KPKBase32EncodingOptionHexadecimalAlphabet];
    NSData *decodedData = [[NSData alloc] initWithBase32HexEncodedString:base32Hex];
    XCTAssertEqualObjects(data, decodedData);
  }
}


- (void)testBase32Decoding {  
  NSDictionary <NSString*, NSString *> *values = @{
    @""       : @"",
    @"f"      : @"MY======",
    @"fo"     : @"MZXQ====",
    @"foo"    : @"MZXW6===",
    @"foob"   : @"MZXW6YQ=",
    @"fooba"  : @"MZXW6YTB",
    @"foobar" : @"MZXW6YTBOI======"
  };
  
  for(NSString *key in values) {
    NSData *expected = [key dataUsingEncoding:NSUTF8StringEncoding];
    NSData *actual = [NSData dataWithBase32EncodedString:values[key]];
    XCTAssertEqualObjects(expected, actual);
  }
}

- (void)testBase32HexDecoding {
  NSDictionary <NSString*, NSString *> *values = @{
    @"" : @"",
    @"f" : @"CO======",
    @"fo" : @"CPNG====",
    @"foo" : @"CPNMU===",
    @"foob" : @"CPNMUOG=",
    @"fooba" : @"CPNMUOJ1",
    @"foobar" : @"CPNMUOJ1E8======"
  };
  
  for(NSString *key in values) {
    NSData *expected = [key dataUsingEncoding:NSUTF8StringEncoding];
    NSData *actual = [NSData dataWithBase32HexEncodedString:values[key]];
    XCTAssertEqualObjects(expected, actual);
  }
}

- (void)testBase32Encoding {
  NSDictionary <NSString*, NSString *> *values = @{
    @""                 : @"",
    @"MY======"         : @"f",
    @"MZXQ===="         : @"fo",
    @"MZXW6==="         : @"foo",
    @"MZXW6YQ="         : @"foob",
    @"MZXW6YTB"         : @"fooba",
    @"MZXW6YTBOI======" : @"foobar"
  };
  
  for(NSString *key in values) {
    NSString *expected = key;
    NSString *actual = [[values[key] dataUsingEncoding:NSUTF8StringEncoding] base32EncodedStringWithOptions:0];
    XCTAssertEqualObjects(expected, actual);
  }
}

- (void)testBase32EncodingWithoutPadding {
  NSDictionary <NSString*, NSString *> *values = @{
    @""           : @"",
    @"MY"         : @"f",
    @"MZXQ"       : @"fo",
    @"MZXW6"      : @"foo",
    @"MZXW6YQ"    : @"foob",
    @"MZXW6YTB"   : @"fooba",
    @"MZXW6YTBOI" : @"foobar"
  };
  
  for(NSString *key in values) {
    NSString *expected = key;
    NSString *actual = [[values[key] dataUsingEncoding:NSUTF8StringEncoding] base32EncodedStringWithOptions:KPKBase32EncodingOptionNoPadding];
    XCTAssertEqualObjects(expected, actual);
  }
}


- (void)testBase32HexEncoding {
  NSDictionary <NSString*, NSString *> *values = @{
    @""                 : @"",
    @"CO======"         : @"f",
    @"CPNG===="         : @"fo",
    @"CPNMU==="         : @"foo",
    @"CPNMUOG="         : @"foob",
    @"CPNMUOJ1"         : @"fooba",
    @"CPNMUOJ1E8======" : @"foobar"
  };
  
  for(NSString *key in values) {
    NSString *expected = key;
    NSString *actual = [[values[key] dataUsingEncoding:NSUTF8StringEncoding] base32EncodedStringWithOptions:KPKBase32EncodingOptionHexadecimalAlphabet];
    XCTAssertEqualObjects(expected, actual);
  }
}

@end
