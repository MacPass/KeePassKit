//
//  KPKAESCipher.m
//  KeePassKit
//
//  Created by Michael Starke on 02/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKAESCipher.h"
#import "KPKCipher_Private.h"
#import "KPKErrors.h"
#import "KPKCompositeKey.h"

#import "NSData+CommonCrypto.h"

#import <CommonCrypto/CommonCrypto.h>

@implementation KPKAESCipher

+ (void)load {
  [KPKCipher _registerCipher:self];
}

+ (NSUUID *)uuid {
  static const uuid_t bytes = {
    0x31, 0xC1, 0xF2, 0xE6, 0xBF, 0x71, 0x43, 0x50,
    0xBE, 0x58, 0x05, 0x21, 0x6A, 0xFC, 0x5A, 0xFF
  };
  static NSUUID *aesUUID = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    aesUUID = [[NSUUID alloc] initWithUUIDBytes:bytes];
  });
  return aesUUID;
}

- (NSString *)name {
  return @"AES Rijndale";
}

- (NSData *)decryptData:(NSData *)data withKey:(NSData *)key initializationVector:(NSData *)iv error:(NSError *__autoreleasing  _Nullable *)error {
  CCCryptorStatus cryptoError = kCCSuccess;
  NSData *decryptedData = [data decryptedDataUsingAlgorithm:kCCAlgorithmAES128
                                                        key:key
                                       initializationVector:iv
                                                    options:kCCOptionPKCS7Padding
                                                      error:&cryptoError];
  if(cryptoError != kCCSuccess) {
    KPKCreateError(error, KPKErrorAESDecryptionFailed);
    return nil;
  }
  return decryptedData;
}

- (NSData *)encryptData:(NSData *)data withKey:(NSData *)key initializationVector:(NSData *)iv error:(NSError *__autoreleasing  _Nullable *)error {
  CCCryptorStatus cryptoError = kCCSuccess;
  NSData *encryptedData = [data dataEncryptedUsingAlgorithm:kCCAlgorithmAES128
                                                        key:key
                                       initializationVector:iv
                                                    options:kCCOptionPKCS7Padding
                                                      error:&cryptoError];
  if(cryptoError != kCCSuccess) {
    KPKCreateError(error, KPKErrorAESDecryptionFailed);
    return nil;
  }
  return encryptedData;
}


@end
