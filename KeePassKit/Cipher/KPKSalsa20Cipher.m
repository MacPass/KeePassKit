//
//  KPKSalsa20Cipher.m
//  KeePassKit
//
//  Created by Michael Starke on 04/11/2016.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKSalsa20Cipher.h"
#import "KPKCipher_Private.h"

@implementation KPKSalsa20Cipher

/*
+ (void)load {
  [KPKCipher _registerCipher:self];
}
*/

+ (NSUUID *)uuid {
  static uuid_t const uuid_bytes = {
    0x71, 0x6E, 0x1C, 0x8A, 0xEE, 0x17, 0x4B, 0xDC,
    0x93, 0xAE, 0xA9, 0x77, 0xB8, 0x82, 0x83, 0x3A
  };
  static NSUUID *salsa20 = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    salsa20 = [[NSUUID alloc] initWithUUIDBytes:uuid_bytes];
  });
  return salsa20;
}

- (NSString *)name {
  return @"Salsa20";
}

- (NSData *)encryptData:(NSData *)data error:(NSError *__autoreleasing  _Nullable *)error {
  return nil;
}

- (NSData *)decryptData:(NSData *)data error:(NSError *__autoreleasing  _Nullable *)error {
  return nil;
}

@end
