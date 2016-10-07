//
//  KPKRC4Cipher.m
//  KeePassKit
//
//  Created by Michael Starke on 23/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKRC4Cipher.h"
#import "KPKCipher_Private.h"
#import "KPKErrors.h"

#import "NSData+CommonCrypto.h"

#import <CommonCrypto/CommonCrypto.h>

@implementation KPKRC4Cipher

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

- (NSData *)decryptData:(NSData *)data withKey:(NSData *)key initializationVector:(NSData *)iv error:(NSError *__autoreleasing  _Nullable *)error {
  CCCryptorStatus cryptoError = kCCSuccess;
  NSData *decryptedData = [data decryptedDataUsingAlgorithm:kCCAlgorithmRC4
                                                        key:key
                                       initializationVector:iv
                                                    options:kCCOptionPKCS7Padding
                                                      error:&cryptoError];
  if(cryptoError != kCCSuccess) {
    KPKCreateError(error, KPKErrorDecryptionFailed, @"ERROR_DECRYPTION_FAILED", "");
    return nil;
  }
  return decryptedData;
}

@end
