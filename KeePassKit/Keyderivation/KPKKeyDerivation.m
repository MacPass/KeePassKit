//
//  KPKKeyDerivation.m
//  KeePassKit
//
//  Created by Michael Starke on 05/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKKeyDerivation.h"
#import "KPKKeyDerivation_Private.h"
#import "NSUUID+KeePassKit.h"

NSString *const KPKKeyDerivationBenchmarkSeconds = @"KPKKeyDerivationBenchmarkSeconds";

NSString *const KPKArgon2SaltOption             = @"S";
NSString *const KPKArgon2ParallelismOption      = @"P";
NSString *const KPKArgon2MemoryOption           = @"M";
NSString *const KPKArgon2IterationsOption       = @"I";
NSString *const KPKArgon2VersionOption          = @"V";
NSString *const KPKArgon2KeyOption              = @"K";
NSString *const KPKArgon2AssociativeDataOption  = @"A";

NSString *const KPKAESSeedOption                = @"S"; // NSData
NSString *const KPKAESRoundsOption              = @"R"; // uint64_t wrapped in KPKNumber

@implementation KPKKeyDerivation

static NSMutableDictionary *_keyDerivations;

+ (NSDictionary *)defaultOptions {
  return @{};
}

+ (NSUUID *)uuid {
  return [NSUUID nullUUID];
}

+ (void)_registerKeyDerivation:(Class)derivationClass {
  if(![derivationClass isSubclassOfClass:[KPKKeyDerivation class]]) {
    NSAssert(NO, @"%@ is no valid key derivation class", derivationClass);
    return;
  }
  if(!_keyDerivations) {
    _keyDerivations = [[NSMutableDictionary alloc] init];
  }
  NSUUID *uuid = [derivationClass uuid];
  if(!uuid) {
    NSAssert(uuid, @"%@ does not provide a valid uuid", derivationClass);
    return;
  }
  _keyDerivations[uuid] = derivationClass;
}

+ (NSArray<KPKKeyDerivation *> *)availableKeyDerivations {
  NSMutableArray *keyDerivations;
  for(NSUUID *uuid in _keyDerivations) {
    [keyDerivations addObject:[[_keyDerivations[uuid] alloc] init]];
  }
  return [NSArray arrayWithArray:keyDerivations];
}

+ (KPKKeyDerivation *)keyDerivationWithUUID:(NSUUID *)uuid {
  return [self keyDerivationWithUUID:uuid options:@{}];
}

+ (KPKKeyDerivation *)keyDerivationWithUUID:(NSUUID *)uuid options:(NSDictionary *)options {
  return [[self alloc] initWithUUID:uuid options:options];
}

+ (void)parametersForDelay:(NSUInteger)seconds completionHandler:(void (^)(NSDictionary * _Nonnull))completionHandler {
  NSAssert(NO, @"%@ should not be called on abstract class!", NSStringFromSelector(_cmd));
}

+ (NSData * _Nullable)deriveData:(NSData *)data withUUID:(NSUUID *)uuid options:(NSDictionary *)options {
  KPKKeyDerivation *derivation = [self keyDerivationWithUUID:uuid options:options];
  return [derivation deriveData:data];
}

- (KPKKeyDerivation *)initWithUUID:(NSUUID *)uuid {
  self = [self initWithUUID:uuid options:[self.class defaultOptions]];
  return self;
}

- (KPKKeyDerivation *)initWithUUID:(NSUUID *)uuid options:(NSDictionary *)options {
  self = nil;
  Class keyDerivationClass = _keyDerivations[uuid];
  self = [(KPKKeyDerivation *)[keyDerivationClass alloc] _initWithOptions:options];
  return self;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"
- (KPKKeyDerivation *)_initWithOptions:(NSDictionary *)options {
  NSAssert(NO, @"%@ should not be called on abstract class!", NSStringFromSelector(_cmd));
  return nil;
}

- (KPKKeyDerivation *)_init {
  self = [super init];
  return self;
}
#pragma clang diagnostic pop

- (instancetype)init {
  self = [self initWithUUID:self.uuid options:@{}];
  self = nil;
  NSAssert(NO, @"%@ should not be called on abstract class!", NSStringFromSelector(_cmd));
  return nil;
}

- (NSData *)deriveData:(NSData *)data {
  NSAssert(NO, @"%@ should not be called on abstract class!", NSStringFromSelector(_cmd));
  return nil;
}

- (NSUUID *)uuid {
  return [self.class uuid];
}

@end
