//
//  KPKAnon2KeyDerivation.m
//  KeePassKit
//
//  Created by Michael Starke on 13/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKArgon2KeyDerivation.h"
#import "KPKKeyDerivation_Private.h"

#import "KPKNumber.h"

#import "NSData+KPKRandom.h"
#import "NSDictionary+KPKVariant.h"

#import "argon2.h"

NSString *const KPKArgon2SaltParameter             = @"S";
NSString *const KPKArgon2ParallelismParameter      = @"P";
NSString *const KPKArgon2MemoryParameter           = @"M";
NSString *const KPKArgon2IterationsParameter       = @"I";
NSString *const KPKArgon2VersionParameter          = @"V";
NSString *const KPKArgon2SecretKeyParameter        = @"K";
NSString *const KPKArgon2AssociativeDataParameter  = @"A";

const uint32_t KPKArgon2MinSaltLength = 8;
const uint32_t KPKArgon2MaxSaltLength = INT32_MAX;
const uint64_t KPKArgon2MinIterations = 1;
const uint64_t KPKArgon2MaxIterations = UINT32_MAX;

const uint64_t KPKArgon2MinMemory = 1024 * 8;
const uint64_t KPKArgon2MaxMemory = INT32_MAX;

const uint32_t KPKArgon2MinParallelism = 1;
const uint32_t KPKArgon2MaxParallelism = (1 << 24) - 1;

const uint64_t KPKArgon2DefaultIterations = 2;
const uint64_t KPKArgon2DefaultMemory = 1024 * 1024; // 1 MB
const uint32_t KPKArgon2DefaultParallelism = 2;

#define KPK_ARGON2_CHECK_INVERVALL(min,max,value) ( (value >= min) && (value <= max) )

@implementation KPKArgon2KeyDerivation

+ (void)load {
  [KPKKeyDerivation _registerKeyDerivation:self];
}

+ (NSDictionary *)defaultParameters {
  NSMutableDictionary *parameters = [[super defaultParameters] mutableCopy];
  [parameters setUnsignedInteger32:ARGON2_VERSION_13 forKey:KPKArgon2VersionParameter];
  [parameters setUnsignedInteger64:KPKArgon2DefaultIterations forKey:KPKArgon2IterationsParameter];
  [parameters setUnsignedInteger64:KPKArgon2DefaultMemory forKey:KPKArgon2MemoryParameter];
  [parameters setUnsignedInteger32:KPKArgon2DefaultParallelism forKey:KPKArgon2ParallelismParameter];
  return [parameters copy];
}

+ (NSUUID *)uuid {
  static const uuid_t bytes = {
    0xEF, 0x63, 0x6D, 0xDF, 0x8C, 0x29, 0x44, 0x4B,
    0x91, 0xF7, 0xA9, 0xA4, 0x03, 0xE3, 0x0A, 0x0C
  };
  static NSUUID *argon2UUID = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    argon2UUID = [[NSUUID alloc] initWithUUIDBytes:bytes];
  });
  return argon2UUID;
}

- (NSString *)name {
  return @"Argon2";
}

- (uint64_t)iterations {
  return [self.mutableParameters unsignedInteger64ForKey:KPKArgon2IterationsParameter];
}

- (void)setIterations:(uint64_t)iterations {
  [self.mutableParameters setUnsignedInteger64:iterations forKey:KPKArgon2IterationsParameter];
}

- (uint32_t)threads {
  return [self.mutableParameters unsignedInteger32ForKey:KPKArgon2ParallelismParameter];
}

- (void)setThreads:(uint32_t)threads {
  [self.mutableParameters setUnsignedInteger32:threads forKey:KPKArgon2ParallelismParameter];
}

- (uint64_t)memory {
  return [self.mutableParameters unsignedInteger64ForKey:KPKArgon2MemoryParameter];
}

- (void)setMemory:(uint64_t)memory {
  [self.mutableParameters setUnsignedInteger64:memory forKey:KPKArgon2MemoryParameter];
}

- (uint64_t)minimumMemory {
  return KPKArgon2MaxMemory;
}

- (uint64_t)maximumMemory {
  return KPKArgon2MaxMemory;
}

- (void)randomize {
  [self.mutableParameters setData:[NSData kpk_dataWithRandomBytes:32] forKey:KPKArgon2SaltParameter];
}

- (BOOL)adjustParameters:(NSMutableDictionary *)parameters {
  BOOL changed = NO;
  KPKNumber *p = parameters[KPKArgon2ParallelismParameter];
  if(p) {
    uint32_t clamped = MIN(MAX(KPKArgon2MinParallelism, p.unsignedInteger32Value), KPKArgon2MaxParallelism);
    if(clamped != p.unsignedInteger32Value) {
      changed = YES;
      [parameters setUnsignedInteger32:clamped forKey:KPKArgon2ParallelismParameter];
    }
  }

  KPKNumber *i = parameters[KPKArgon2IterationsParameter];
  if(i) {
    uint64_t clamped = MIN(MAX(KPKArgon2MinIterations, p.unsignedInteger64Value), KPKArgon2MaxIterations);
    if(clamped != i.unsignedInteger64Value) {
      changed = YES;
      [parameters setUnsignedInteger64:clamped forKey:KPKArgon2IterationsParameter];
    }
  }

  KPKNumber *m = parameters[KPKArgon2MemoryParameter];
  if(i) {
    uint64_t clamped = MIN(MAX(KPKArgon2MinMemory, m.unsignedInteger64Value), KPKArgon2MaxMemory);
    if(clamped != m.unsignedInteger64Value) {
      changed = YES;
      [parameters setUnsignedInteger64:clamped forKey:KPKArgon2MemoryParameter];
    }
  }
  return changed;
}

- (NSData *)deriveData:(NSData *)data {
  NSAssert(self.mutableParameters[KPKArgon2IterationsParameter], @"Iterations option is missing!");
  NSAssert(self.mutableParameters[KPKArgon2SaltParameter], @"Salt option is missing!");
  NSAssert(self.mutableParameters[KPKArgon2MemoryParameter], @"Memory option is missing!");
  NSAssert(self.mutableParameters[KPKArgon2ParallelismParameter], @"Parallelism option is missing!");
  NSAssert(self.mutableParameters[KPKArgon2VersionParameter], @"Version option is missing!");
  
  uint32_t version = [self.mutableParameters unsignedInteger32ForKey:KPKArgon2VersionParameter];
  if(!KPK_ARGON2_CHECK_INVERVALL(ARGON2_VERSION_10, ARGON2_VERSION_13, version)) {
    return nil;
  }
  
  NSData *saltData = [self.mutableParameters dataForKey:KPKArgon2SaltParameter];
  if(!KPK_ARGON2_CHECK_INVERVALL(KPKArgon2MinSaltLength, KPKArgon2MaxSaltLength, saltData.length)) {
    return nil;
  }
  uint32_t parallelism = self.threads;
  if(!KPK_ARGON2_CHECK_INVERVALL(KPKArgon2MinParallelism, KPKArgon2MaxParallelism, parallelism)) {
    return nil;
  }
  
  uint64_t memory = self.memory;
  if(!KPK_ARGON2_CHECK_INVERVALL(KPKArgon2MinMemory, KPKArgon2MaxMemory, memory)) {
    return nil;
  }
  uint64_t iterations = self.iterations;
  if(!KPK_ARGON2_CHECK_INVERVALL(KPKArgon2MinIterations, KPKArgon2MaxIterations, iterations)) {
    return nil;
  }
  
  NSData *associativeData = [self.mutableParameters dataForKey:KPKArgon2AssociativeDataParameter];
  NSData *secretData = [self.mutableParameters dataForKey:KPKArgon2SecretKeyParameter];

  uint8_t hash[32];
  argon2_context context = {
    hash,  /* output array, at least HASHLEN in size */
    sizeof(hash), /* digest length */
    (uint8_t *)data.bytes, /* password array */
    (uint32_t)data.length, /* password length */
    (uint8_t *)saltData.bytes, /* salt array */
    (uint32_t)saltData.length, /* salt length */
    NULL, 0, /* optional secret data */
    NULL, 0, /* optional associated data */
    (uint32_t)iterations,
    (uint32_t)(memory/1024),
    parallelism,
    parallelism,
    version, /* algorithm version */
    NULL, NULL, /* custom memory allocation / deallocation functions */
    ARGON2_DEFAULT_FLAGS /* by default the password is zeroed on exit */
  };
  
  /* Optionals */
  if(associativeData) {
    context.ad = (uint8_t *)associativeData.bytes;
    context.adlen = (uint32_t)associativeData.length;
  }
  if(secretData) {
    context.secret = (uint8_t *)secretData.bytes;
    context.secretlen = (uint32_t)secretData.length;
  }
  
  int returnCode = argon2d_ctx(&context);
  if(ARGON2_OK != returnCode) {
    NSLog(@"%s", argon2_error_message(returnCode));
    return nil;
  }
  return [NSData dataWithBytes:hash length:sizeof(hash)];
}

@end
