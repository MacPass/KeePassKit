//
//  KPKAESKeyDerication.m
//  KeePassKit
//
//  Created by Michael Starke on 05/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKAESKeyDerivation.h"
#import "KPKKeyDerivation_Private.h"
#import "KPKNumber.h"

#import "NSData+CommonCrypto.h"
#import "NSData+KPKRandom.h"
#import "NSUUID+KPKAdditions.h"

#import "NSDictionary+KPKVariant.h"

#import <CommonCrypto/CommonCrypto.h>

NSString *const KPKAESSeedOption                = @"S"; // NSData
NSString *const KPKAESRoundsOption              = @"R"; // uint64_t wrapped in KPKNumber

@implementation KPKAESKeyDerivation

+ (NSDictionary *)defaultParameters {
  NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithDictionary:[super defaultParameters]];
  parameters[KPKAESRoundsOption] = [[KPKNumber alloc] initWithUnsignedInteger64:60000];
  return [parameters copy];
}

+ (NSUUID *)uuid {
  static const uuid_t bytes = {
    0xC9, 0xD9, 0xF3, 0x9A, 0x62, 0x8A, 0x44, 0x60,
    0xBF, 0x74, 0x0D, 0x08, 0xC1, 0x8A, 0x4F, 0xEA
  };
  static NSUUID *aesUUID = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    aesUUID = [[NSUUID alloc] initWithUUIDBytes:bytes];
  });
  return aesUUID;
}

+ (void)load {
  [KPKKeyDerivation _registerKeyDerivation:self];
}

- (void)parametersForDelay:(NSUInteger)seconds completionHandler:(void (^)(NSDictionary * _Nonnull options))completionHandler {
  // Transform the key
  dispatch_queue_t normalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  dispatch_async(normalQueue, ^{
    /* dispatch the benchmark to the background */
    static size_t seed = 0xAF09F49F;
    CCCryptorRef cryptorRef;
    CCCryptorCreate(kCCEncrypt, kCCAlgorithmAES128, kCCOptionECBMode, &seed, sizeof(seed), nil, &cryptorRef);
    size_t tmp;
    size_t key = 0x8934BBCD;
    NSUInteger completedRounds = 0;
    NSDate *date = [[NSDate alloc] init];
    /* run transformations until our set time is over */
    while(-date.timeIntervalSinceNow < seconds) {
      completedRounds++;
      CCCryptorUpdate(cryptorRef, &key, sizeof(size_t), &key, sizeof(size_t), &tmp);
    }
    CCCryptorRelease(cryptorRef);
    dispatch_async(dispatch_get_main_queue(), ^{
      /* call the block on the main thread to return the results */
      completionHandler(@{ KPKAESRoundsOption: [[KPKNumber alloc] initWithUnsignedInteger64:completedRounds] });
    });
  });
}

- (KPKKeyDerivation *)_initWithParameters:(NSDictionary *)parameters {
  NSAssert([parameters[KPKKeyDerivationOptionUUID] isEqualToData:self.uuid.kpk_uuidData], @"AES KeyDerivation UUID mismatch!");
  NSAssert(parameters[KPKAESRoundsOption], @"Rounds option is missing!");
  self = [super _initWithParameters:parameters];
  return self;
}

- (NSString *)name {
  return @"AES";
}

- (uint64_t)rounds {
  return [self.mutableParameters[KPKAESRoundsOption] unsignedInteger64Value];
}

- (void)setRounds:(uint64_t)rounds {
  [self.mutableParameters setUnsignedInteger64:rounds forKey:KPKAESRoundsOption];
}

- (void)randomize {
  [self.mutableParameters setData:[NSData kpk_dataWithRandomBytes:32] forKey:KPKAESSeedOption];
}

- (BOOL)adjustParameters:(NSMutableDictionary *)parameters {
  return NO;
}

- (NSData *)deriveData:(NSData *)data {
  NSAssert(self.mutableParameters[KPKAESSeedOption], @"AES Seed option is missing!");
  NSAssert(self.mutableParameters[KPKAESRoundsOption], @"AES Rounds option is missing!");
  NSData *seed = self.mutableParameters[KPKAESSeedOption];
  if(seed.length != 32 ) {
    NSLog(@"Key derivations seed is not 32 bytes. Hashing seed!");
    seed = seed.SHA256Hash;
  }
  
  if(data.length != 32) {
    NSLog(@"Data to derive is not 32 bytes long. Hashing data!");
    data = data.SHA256Hash;
  }
  
  CCCryptorRef cryptorRef;
  CCCryptorStatus status = CCCryptorCreate(kCCEncrypt, kCCAlgorithmAES, kCCOptionECBMode, seed.bytes, kCCKeySizeAES256, NULL, &cryptorRef);
  if(kCCSuccess != status) {
    CCCryptorRelease(cryptorRef);
    return nil;
  }
  uint8_t derivedData[32];
  [data getBytes:derivedData length:32];
  size_t tmp;
  uint64_t rounds = self.rounds;
  while(rounds--) {
    status = CCCryptorUpdate(cryptorRef, derivedData, 32, derivedData, 32, &tmp);
    if(kCCSuccess != status) {
      CCCryptorRelease(cryptorRef);
      return nil;
    }
  }
  status = CCCryptorFinal(cryptorRef,derivedData, 32, &tmp);
  if(kCCSuccess != status) {
    CCCryptorRelease(cryptorRef);
    return nil;
  }
  CCCryptorRelease(cryptorRef);
  
  /* Hash the result */
  uint8_t hash[CC_SHA256_DIGEST_LENGTH];
  CC_SHA256(derivedData, 32, hash);
  
  return [NSData dataWithBytes:hash length:CC_SHA256_DIGEST_LENGTH];
}

@end
