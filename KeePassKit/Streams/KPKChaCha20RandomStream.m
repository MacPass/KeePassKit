//
//  KPKChaCha20RandomStream.m
//  KeePassKit
//
//  Created by Michael Starke on 28/10/2016.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKChaCha20RandomStream.h"
#import "NSData+KPKRandom.h"
#import "KPKCipher.h"
#import "KPKChaCha20Cipher.h"

#import "NSData+CommonCrypto.h"

@interface KPKChaCha20RandomStream () {
  KPKChaCha20Cipher *_cipher;
}
@end
@implementation KPKChaCha20RandomStream

- (instancetype)init {
  return [self initWithKeyData:[NSData kpk_dataWithRandomBytes:64]];
}

- (instancetype)initWithKeyData:(NSData*)key {
  self = [super init];
  if(self) {
    NSData *hash = key.SHA512Hash;
    _cipher = [[KPKChaCha20Cipher alloc] initWithKey:[hash subdataWithRange:NSMakeRange(0, 32)] initializationVector:[hash subdataWithRange:NSMakeRange(32, 12)]];
  }
  return self;
}

- (uint8_t)getByte {
  uint8_t byte[1] = { 0 };
  uint8_t outByte[1] = { 0 };
  NSData *data = [_cipher encryptData:[NSData dataWithBytesNoCopy:byte length:1 freeWhenDone:NO] error:nil];
  [data getBytes:outByte length:1];
  return outByte[0];
}

@end
