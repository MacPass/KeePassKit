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
#import "NSData+Random.h"

#import <CommonCrypto/CommonCrypto.h>

@implementation KPKAESKeyDerivation

+ (NSDictionary *)defaultParameters {
  return @{
           KPKAESRoundsOption: [[KPKNumber alloc] initWithUnsignedInteger64:50000],
           KPKAESSeedOption: [NSData dataWithRandomBytes:32]
           };
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
  NSNumber *secondsNumber = options[KPKKeyDerivationBenchmarkSecondsOptions];
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
      completionHandler(@{ KPKAESRoundsOption: @(completedRounds) });
    });
  });
}

- (instancetype)init {
  /* initialize a default parameterized key derivation */
  self = [self _initWithOptions:@{}];
  return self;
}

- (KPKKeyDerivation *)_initWithOptions:(NSDictionary *)options {
  self = [super _init];
  if(self) {
    self.options = [options copy];
    NSDictionary *defaults = [self.class defaultParameters];
    _seed = [options[KPKAESSeedOption] copy];
    _rounds = [options[KPKAESRoundsOption] copy];
    if( ! self.seed ) {
      _seed = [defaults[KPKAESSeedOption] copy];
    }
    if( ! self.rounds ) {
      _rounds = [defaults[KPKAESRoundsOption] copy];
    }
  }
  return self;
}

- (NSData *)deriveData:(NSData *)data options:(NSDictionary *)options {
  KPKNumber *roundsObj = options[KPKAESRoundsOption];
  if(roundsObj && roundsObj.type != KPKNumberTypeUnsignedInteger64 ) {
    _rounds = [roundsObj copy];
  }
  else {
    return nil;
  }
  
  NSData *seed = options[KPKAESSeedOption];
  if(seed && [seed isKindOfClass:[NSData class]]) {
    _seed = [seed copy];
  }
  
  if(self.seed.length != 32 ) {
    NSLog(@"Key derivations seed is not 32 bytes. Hashing seed!");
    _seed = [seed.SHA256Hash copy];
  }
  
  if(data.length != 32) {
    NSLog(@"Data to derive is not 32 bytes long. Hashing data!");
    data = data.SHA256Hash;
  }
  
  CCCryptorRef cryptorRef;
  CCCryptorStatus status = CCCryptorCreate(kCCEncrypt, kCCAlgorithmAES, kCCOptionECBMode, self.seed.bytes, kCCKeySizeAES256, NULL, &cryptorRef);
  if(kCCSuccess != status) {
    CCCryptorRelease(cryptorRef);
    return nil;
  }
  uint8_t derivedData[32];
  [data getBytes:derivedData length:32];
  size_t tmp;
  uint64_t rounds = self.rounds.unsignedInteger64Value;
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
