//
//  KPKTestTwofish.m
//  KeePassKit
//
//  Created by Michael Starke on 04/11/2016.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "twofish.h"

@interface KPKTestTwofish : XCTestCase

@end

@implementation KPKTestTwofish

- (void)testExample {
  Twofish_context context;
  uint8_t key[32] = { 0 };
  key[0] = 0x11;
  key[31] = 0xFF;
  
  uint8_t iv[16] = { 0 };
  iv[0] = 0xFF;
  iv[15] = 0xAA;
  
  Twofish_setup(&context, key, iv, Twofish_options_default);
  
  uint8_t data1[17] = { 0 };
  data1[7] = 0x11;
  
  uint64_t output_length = Twofish_get_output_length(&context, sizeof(data1));
  uint8_t output[output_length];
  Twofish_encrypt(&context, data1, sizeof(data1), output, output_length);

  Twofish_setup(&context, key, iv, Twofish_options_default);
  uint8_t decryptedOutput[output_length];
  uint64_t decrypted_length = output_length;
  Twofish_decrypt(&context, output, sizeof(output), decryptedOutput, &decrypted_length);
  
  NSData *decryptedData = [NSData dataWithBytes:decryptedOutput length:decrypted_length];

  XCTAssertEqual(0, memcmp(decryptedData.bytes, data1, sizeof(data1)));
}


@end
