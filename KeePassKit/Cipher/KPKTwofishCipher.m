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


/*
+ (void)load {
  [KPKCipher _registerCipher:self];
}
*/

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

- (NSUInteger)IVLength {
  return 16;
}

- (NSUInteger)keyLength {
  return 32;
}

- (NSData *)encryptData:(NSData *)data error:(NSError *__autoreleasing  _Nullable *)error {
  if(![self _setupContext:error]) {
    return nil;
  };
  
  NSMutableData *outputData = [[NSMutableData alloc] initWithCapacity:data.length];
  NSUInteger blockSize = 16;
  NSUInteger blockCount = ceil((CGFloat)data.length / (CGFloat)blockSize) + 1;
  NSUInteger blockIndex = 0;
  while(blockIndex < blockCount) {
    uint8_t inputBlock[16];
    uint8_t copyLength = MIN(data.length - blockIndex * blockSize, blockSize);
    [data getBytes:inputBlock range:NSMakeRange(blockIndex * blockCount, copyLength)];
    uint8_t paddingCount = (16-copyLength);
    for(int index=0; index < paddingCount; index++) {
      inputBlock[15-index] = paddingCount;
    }
    uint8_t outputBlock[16];
    Twofish_encrypt_block(&_context.key, inputBlock, outputBlock);
    
    [outputData appendBytes:outputBlock length:16];
  }
  return nil;
}

- (NSData *)decryptData:(NSData *)data error:(NSError *__autoreleasing  _Nullable *)error {
 if(![self _setupContext:error]) {
    return nil;
  }
  NSMutableData *outputData = [[NSMutableData alloc] initWithCapacity:data.length];
  NSAssert(data.length % 16 == 0, @"Unsupported input data size. No padding applied?");
  KPKDataStreamReader *reader = [[KPKDataStreamReader alloc] initWithData:data];
  while(reader.hasBytesAvailable) {
    uint8_t inputBlock[16];
    [data getBytes:inputBlock range:NSMakeRange(reader.offset, 16)];
    uint8_t outputBlock[16];
    Twofish_decrypt_block(&_context.key, inputBlock, outputBlock);
    /* todo update iv */
    [outputData appendBytes:outputBlock length:16];
  }
  
  return nil;
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
