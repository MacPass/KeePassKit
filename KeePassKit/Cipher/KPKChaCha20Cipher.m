//
//  KPKChaChaCipher.m
//  KeePassKit
//
//  Created by Michael Starke on 02/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKChaCha20Cipher.h"
#import "KPKCipher_Private.h"
#import "chacha20_simple.h"

@implementation KPKChaCha20Cipher

+ (void)load {
  [KPKCipher _registerCipher:self];
}

+ (NSUUID *)uuid {
  static uuid_t const uuid_bytes = {
    0xD6, 0x03, 0x8A, 0x2B, 0x8B, 0x6F, 0x4C, 0xB5,
    0xA5, 0x24, 0x33, 0x9A, 0x31, 0xDB, 0xB5, 0x9A
  };
  static NSUUID *chacha20UUID = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    chacha20UUID = [[NSUUID alloc] initWithUUIDBytes:uuid_bytes];
  });
  return chacha20UUID;
}

@end
