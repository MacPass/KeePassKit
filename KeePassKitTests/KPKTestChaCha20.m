//
//  KPKTestChaCha20.m
//  KeePassKit
//
//  Created by Michael Starke on 27/10/2016.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KeePassKit.h"

#import "KPKChaCha20Cipher.h"
#import "KPKChaCha20RandomStream.h"

#import "NSData+CommonCrypto.h"

@interface KPKTestChaCha20 : XCTestCase

@end

@implementation KPKTestChaCha20

- (void)testChaCha20Cipher {
  
  uint8_t nullBytes[64] = { 0 };
  uint8_t keyBytes[32] = {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31};
  NSData *key = [NSData dataWithBytesNoCopy:keyBytes length:32 freeWhenDone:NO];
  
  NSMutableData *iv = [[NSMutableData alloc] initWithLength:12];
  ((uint8_t*)iv.mutableBytes)[3] = 0x09;
  ((uint8_t*)iv.mutableBytes)[7] = 0x4A;
  
  uint8_t expectedBytes1[64] = {
				0x10, 0xF1, 0xE7, 0xE4, 0xD1, 0x3B, 0x59, 0x15,
				0x50, 0x0F, 0xDD, 0x1F, 0xA3, 0x20, 0x71, 0xC4,
				0xC7, 0xD1, 0xF4, 0xC7, 0x33, 0xC0, 0x68, 0x03,
				0x04, 0x22, 0xAA, 0x9A, 0xC3, 0xD4, 0x6C, 0x4E,
				0xD2, 0x82, 0x64, 0x46, 0x07, 0x9F, 0xAA, 0x09,
				0x14, 0xC2, 0xD7, 0x05, 0xD9, 0x8B, 0x02, 0xA2,
				0xB5, 0x12, 0x9C, 0xD1, 0xDE, 0x16, 0x4E, 0xB9,
				0xCB, 0xD0, 0x83, 0xE8, 0xA2, 0x50, 0x3C, 0x4E
  };
  
  KPKChaCha20Cipher *cipher = [[KPKChaCha20Cipher alloc] initWithKey:key initializationVector:iv];
  
  NSData *messageData = [[NSMutableData alloc] initWithLength:64];
  NSData *exptectedData = [NSData dataWithBytesNoCopy:expectedBytes1 length:sizeof(expectedBytes1) freeWhenDone:NO];
  
  /* strip the first 64 bytes out */
  NSError *error;
  NSData *nullData = [NSData dataWithBytesNoCopy:nullBytes length:64 freeWhenDone:NO];
  NSData *firstBlock = [cipher encryptData:nullData error:&error];
  XCTAssertNil(error);
  XCTAssertNotNil(firstBlock);
  
  NSData *actualData = [cipher encryptData:messageData error:&error];
  XCTAssertEqualObjects(actualData, exptectedData, @"ChaCha20 encryption yields the same result");
  
  ((uint8_t*)iv.mutableBytes)[3] = 0;
  cipher = [[KPKChaCha20Cipher alloc] initWithKey:key initializationVector:iv];
  
  messageData = [@"Ladies and Gentlemen of the class of '99: If I could offer you only one tip for the future, sunscreen would be it." dataUsingEncoding:NSUTF8StringEncoding];
  
  uint8_t expectedBytes2[] = {
				0x6E, 0x2E, 0x35, 0x9A, 0x25, 0x68, 0xF9, 0x80,
				0x41, 0xBA, 0x07, 0x28, 0xDD, 0x0D, 0x69, 0x81,
				0xE9, 0x7E, 0x7A, 0xEC, 0x1D, 0x43, 0x60, 0xC2,
				0x0A, 0x27, 0xAF, 0xCC, 0xFD, 0x9F, 0xAE, 0x0B,
				0xF9, 0x1B, 0x65, 0xC5, 0x52, 0x47, 0x33, 0xAB,
				0x8F, 0x59, 0x3D, 0xAB, 0xCD, 0x62, 0xB3, 0x57,
				0x16, 0x39, 0xD6, 0x24, 0xE6, 0x51, 0x52, 0xAB,
				0x8F, 0x53, 0x0C, 0x35, 0x9F, 0x08, 0x61, 0xD8,
				0x07, 0xCA, 0x0D, 0xBF, 0x50, 0x0D, 0x6A, 0x61,
				0x56, 0xA3, 0x8E, 0x08, 0x8A, 0x22, 0xB6, 0x5E,
				0x52, 0xBC, 0x51, 0x4D, 0x16, 0xCC, 0xF8, 0x06,
				0x81, 0x8C, 0xE9, 0x1A, 0xB7, 0x79, 0x37, 0x36,
				0x5A, 0xF9, 0x0B, 0xBF, 0x74, 0xA3, 0x5B, 0xE6,
				0xB4, 0x0B, 0x8E, 0xED, 0xF2, 0x78, 0x5E, 0x42,
				0x87, 0x4D
  };
  
  exptectedData = [NSData dataWithBytesNoCopy:expectedBytes2 length:sizeof(expectedBytes2) freeWhenDone:NO];
  firstBlock = [cipher encryptData:nullData error:&error];
  actualData = [cipher encryptData:messageData error:&error];
  XCTAssertNil(error); // no error
  XCTAssertEqualObjects(actualData, exptectedData, @"ChaCha20 encryption yields the same result");
}

- (void)testChaCha20RandomStream {
  uint8_t nullBytes[64] = { 0 };

  NSData *keyData = [NSData dataWithBytesNoCopy:nullBytes length:64 freeWhenDone:NO].SHA512Hash;
  NSData *key = [keyData subdataWithRange:NSMakeRange(0, 32)];
  NSData *iv = [keyData subdataWithRange:NSMakeRange(32, 12)];
  
  KPKChaCha20Cipher *cipher = [[KPKChaCha20Cipher alloc] initWithKey:key initializationVector:iv];
  KPKChaCha20RandomStream *stream = [[KPKChaCha20RandomStream alloc] initWithKeyData:[NSData dataWithBytesNoCopy:nullBytes length:64 freeWhenDone:NO]];
  
  NSData *messageData = [[NSMutableData alloc] initWithLength:(1024*1024)];
  NSError *error;
  NSData *encryptedData = [cipher encryptData:messageData error:&error];
  for(NSUInteger index = 0; index < encryptedData.length; index++) {
    uint8_t streamByte = stream.getByte;
    uint8_t encryptedByte = ((uint8_t *)encryptedData.bytes)[index];
    XCTAssertEqual(streamByte, encryptedByte);
  }
}

@end
