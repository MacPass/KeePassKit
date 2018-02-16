//
//  KPKTwofishCipher.m
//  KeePassKit
//
//  Created by Michael Starke on 04/11/2016.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKTwofishCipher.h"
#import "KPKCipher_Private.h"
#import "KPKDataStreamReader.h"

#import "twofish.h"

@interface KPKTwofishCipher () {
  Twofish_context _context;
}

@end
@implementation KPKTwofishCipher

+ (void)load {
  [KPKCipher _registerCipher:self];
}

+ (NSUUID *)uuid {
  static uuid_t const uuid_bytes = {
    0xAD, 0x68, 0xF2, 0x9F, 0x57, 0x6F, 0x4B, 0xB9,
    0xA3, 0x6A, 0xD4, 0x7A, 0xF9, 0x65, 0x34, 0x6C
  };
  static NSUUID *twofishUUID = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    twofishUUID = [[NSUUID alloc] initWithUUIDBytes:uuid_bytes];
  });
  return twofishUUID;
}

- (instancetype)init {
  self = [super init];
  
  static dispatch_once_t twofishInit;
  dispatch_once(&twofishInit, ^{
    Twofish_initialise();
  });
  return self;
}

- (NSString *)name {
  return @"Twofish";
}

- (NSUInteger)IVLength {
  return 16;
}

- (NSUInteger)keyLength {
  return 32;
}

- (NSData *)encryptData:(NSData *)data error:(NSError *__autoreleasing  _Nullable *)error {
  if(![self _setupContext:error]) {
    return nil;
  }
  uint64_t encrpyted_length = Twofish_get_output_length(&_context, data.length);
  uint8_t encrypted[data.length];
  
  Twofish_encrypt(&_context, (Twofish_Byte *)data.bytes, (Twofish_UInt64) data.length, encrypted, encrpyted_length);
  
  return [NSData dataWithBytes:encrypted length:(NSUInteger)encrpyted_length];
}

- (NSData *)decryptData:(NSData *)data error:(NSError *__autoreleasing  _Nullable *)error {
 if(![self _setupContext:error]) {
    return nil;
  }
  NSAssert(0 == (data.length % 16), @"Invalid data size");
  uint8_t decrypted[data.length];
  uint64_t decrpyted_length = data.length;
  Twofish_decrypt(&_context, (Twofish_Byte *)data.bytes, data.length, decrypted, &decrpyted_length);
  
  return [NSData dataWithBytes:decrypted length:(NSUInteger)decrpyted_length];
}

- (NSData *)encryptData:(NSData *)data withKey:(NSData *)key initializationVector:(NSData *)iv error:(NSError *__autoreleasing  _Nullable *)error {
  self.key = key;
  self.initializationVector = iv;
  return [self encryptData:data error:error];
}

- (NSData *)decryptData:(NSData *)data withKey:(NSData *)key initializationVector:(NSData *)iv error:(NSError *__autoreleasing  _Nullable *)error {
  self.key = key;
  self.initializationVector = iv;
  return [self decryptData:data error:error];
}

- (BOOL)_setupContext:(NSError **)error {
  NSAssert(self.initializationVector.length == self.IVLength, @"Twofish IV length must be 16 bytes!");
  NSAssert(self.key.length == self.keyLength, @"Twofish key lenght must be 32 bytes");
  if(self.key.length != 32) {
    KPKCreateError(error, KPKErrorDecryptionFailed);
    return NO;
  }
  if(self.initializationVector.length != 16) {
    KPKCreateError(error, KPKErrorDecryptionFailed);
    return NO;
  }
  Twofish_setup(&_context, (void *)self.key.bytes, (void *)self.initializationVector.bytes, Twofish_options_default);
  return YES;
}
@end
