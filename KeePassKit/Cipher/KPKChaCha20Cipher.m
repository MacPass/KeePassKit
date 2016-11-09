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

#import "KPKErrors.h"

@interface KPKChaCha20Cipher () {
  chacha20_ctx _context;
}

@end

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

- (KPKCipher *)initWithKey:(NSData *)key initializationVector:(NSData *)iv {
  self = [super initWithKey:key initializationVector:iv];
  if(self && ![self _setupContext:nil]) {
      self = nil;
  }
  return self;
}

- (NSString *)name {
  return @"ChaCha20";
}

- (NSUInteger)IVLength {
  return 12;
}

- (NSUInteger)keyLength {
  return 32;
}

- (NSData *)decryptData:(NSData *)data withKey:(NSData *)key initializationVector:(NSData *)iv error:(NSError *__autoreleasing  _Nullable *)error {
  return [self encryptData:data withKey:key initializationVector:iv error:error];
}

- (NSData *)encryptData:(NSData *)data withKey:(NSData *)key initializationVector:(NSData *)iv error:(NSError *__autoreleasing  _Nullable *)error {
  /* update our state */
  self.initializationVector = iv;
  self.key = key;
  [self _setupContext:error];
  return [self encryptData:data error:error];
}

- (NSData *)encryptData:(NSData *)data error:(NSError *__autoreleasing  _Nullable *)error {
  uint8_t buffer[data.length];
  chacha20_encrypt(&_context, data.bytes, buffer, data.length);
  return [[NSData alloc] initWithBytes:buffer length:data.length];
}

- (NSData *)decryptData:(NSData *)data error:(NSError *__autoreleasing  _Nullable *)error {
  return [self encryptData:data error:error];
}

- (BOOL)_setupContext:(NSError **)error {
  if(self.initializationVector.length != 12) {
    KPKCreateError(error, KPKErrorDecryptionFailed);
    return NO;
  }
  chacha20_setup(&_context, self.key.bytes, self.key.length, self.initializationVector.bytes, self.initializationVector.length);
  return YES;
}

@end
