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

#import <CommonCrypto/CommonCrypto.h>

NSString *const kKPKAESSeedKey = @"S"; // NSData
NSString *const kKPKAESRoundsKey = @"R"; // KPKNumber

@implementation KPKAESKeyDerivation

+ (NSDictionary *)defaultParameters {
  return @{ kKPKAESRoundsKey: [[KPKNumber alloc] initWithUnsignedInteger64:50000]  };
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

+ (void)benchmarkWithOptions:(NSDictionary *)options completionHandler:(void(^)(NSDictionary *results))completionHandler {
  NSNumber *secondsNumber = options[kKPKKeyDerivationBenchmarkSeconds];
  if(!secondsNumber) {
    return;
  }
  NSUInteger seconds = secondsNumber.unsignedIntegerValue;
  // Transform the key
  dispatch_queue_t normalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  dispatch_async(normalQueue, ^{
    /* dispatch the benchmark to the background */
    size_t seed = 0xAF09F49F;
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
      completionHandler(@{ kKPKAESRoundsKey: @(completedRounds) });
    });
  });
}

+ (NSData *)deriveData:(NSData *)data options:(NSDictionary *)options {
  
  KPKNumber *roundsObj = options[kKPKAESRoundsKey];
  if(!roundsObj) {
    return nil;
  }

  if(roundsObj.type != KPKNumberTypeUnsignedInteger64 ) {
    return nil;
  }
  uint64_t rounds = roundsObj.unsignedInteger64Value;
  
  NSData *seed = options[kKPKAESSeedKey];
  if(!seed) {
    return nil;
  }

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
