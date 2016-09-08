//
//  KPKAESKeyDerication.m
//  KeePassKit
//
//  Created by Michael Starke on 05/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKAESKeyDerivation.h"
#import "KPKKeyDerivation_Private.h"
#import "NSData+CommonCrypto.h"

#import "NSNumber+TypedNumber.h"

#import <CommonCrypto/CommonCrypto.h>

static uint32_t const kKPKAESKeyFileLength = 32;

NSString *const kKPKAESSeedKey = @"S"; // NSData
NSString *const kKPKAESRoundsKey = @"R"; // KPKNumber

@implementation KPKAESKeyDerivation

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

- (NSData *)deriveData:(NSData *)data options:(NSDictionary *)options {
  
  NSNumber *rounds = options[kKPKAESRoundsKey];
  if(!rounds) {
    return nil;
  }

  if(rounds.type != kKPKNumberTypeUInt64 ) {
    return nil;
  }

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
  
  /* Transform the key */
  uint8_t masterKey[kKPKAESKeyFileLength];
  CCCryptorRef cryptorRef;
  CCCryptorCreate(kCCEncrypt, kCCAlgorithmAES128, kCCOptionECBMode, data.bytes, kCCKeySizeAES256, nil, &cryptorRef);
  
  size_t tmp;
  for(unsigned long long i = 0; i < rounds.unsignedLongLongValue; i++) {
    CCCryptorUpdate(cryptorRef, masterKey, kKPKAESKeyFileLength, masterKey, kKPKAESKeyFileLength, &tmp);
  }
  
  CCCryptorRelease(cryptorRef);
  uint8_t transformedKey[kKPKAESKeyFileLength];
  CC_SHA256(masterKey, kKPKAESKeyFileLength, transformedKey);
  
  /* Hash the master seed with the transformed key into the final key */
  uint8_t finalKey[kKPKAESKeyFileLength];
  CC_SHA256_CTX ctx;
  CC_SHA256_Init(&ctx);
  CC_SHA256_Update(&ctx, seed.bytes, (CC_LONG)seed.length);
  CC_SHA256_Update(&ctx, transformedKey,  kKPKAESKeyFileLength);
  CC_SHA256_Final(finalKey, &ctx);

  return [NSData dataWithBytes:finalKey length:kKPKAESKeyFileLength];
}

@end
