//
//  KPKKeyDerivation.m
//  KeePassKit
//
//  Created by Michael Starke on 05/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKKeyDerivation.h"
#import "KPKKeyDerivation_Private.h"
#import "NSUUID+KPKAdditions.h"

NSString *const KPKKeyDerivationOptionUUID = @"$UUID";

@implementation KPKKeyDerivation

static NSMutableDictionary *_keyDerivations;

+ (NSDictionary *)defaultParameters {
  return @{ KPKKeyDerivationOptionUUID: [self.class uuid].kpk_uuidData };
}

+ (NSUUID *)uuid {
  return [NSUUID kpk_nullUUID];
}

+ (void)_registerKeyDerivation:(Class)derivationClass {
  if(![derivationClass isSubclassOfClass:KPKKeyDerivation.class]) {
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
  NSMutableArray *keyDerivations = [[NSMutableArray alloc] init];
  for(NSUUID *uuid in _keyDerivations) {
    [keyDerivations addObject:[[_keyDerivations[uuid] alloc] init]];
  }
  return [NSArray arrayWithArray:keyDerivations];
}

+ (KPKKeyDerivation *)keyDerivationWithParameters:(NSDictionary *)parameters {
  return [[KPKKeyDerivation alloc] initWithParameters:parameters];
}

+ (void)parametersForDelay:(NSUInteger)seconds completionHandler:(void (^)(NSDictionary * _Nonnull))completionHandler {
  NSAssert(NO, @"%@ should not be called on abstract class!", NSStringFromSelector(_cmd));
}

+ (NSData * _Nullable)deriveData:(NSData *)data withParameters:(NSDictionary *)parameters {
  KPKKeyDerivation *derivation = [[KPKKeyDerivation alloc] initWithParameters:parameters];
  return [derivation deriveData:data];
}

- (KPKKeyDerivation *)initWithParameters:(NSDictionary *)parameters {
  NSData *uuidData = parameters[KPKKeyDerivationOptionUUID];
  if(!uuidData || ![uuidData isKindOfClass:NSData.class]) {
    self = nil;
    return self;
  }
  NSUUID *uuid = [[NSUUID alloc] initWithData:uuidData];
  Class keyDerivationClass = _keyDerivations[uuid];
  self = [(KPKKeyDerivation *)[keyDerivationClass alloc] _initWithParameters:parameters];
  return self;
}

- (KPKKeyDerivation *)_initWithParameters:(NSDictionary *)parameters{
  self = [self _init];
  if(self) {
    self.mutableParameters  = [parameters mutableCopy];
  }
  return self;
}

- (KPKKeyDerivation *)_init {
  self = [super init];
  if(self) {
    _mutableParameters = [[NSMutableDictionary alloc] init];
  }
  return self;
}

- (instancetype)init {
  self = [self initWithParameters:[self.class defaultParameters]];
  return self;
}

- (NSData *)deriveData:(NSData *)data {
  NSAssert(NO, @"%@ should not be called on abstract class!", NSStringFromSelector(_cmd));
  return nil;
}

- (NSUUID *)uuid {
  return [self.class uuid];
}

- (BOOL)adjustParameters:(NSMutableDictionary *)parameters {
  NSAssert(NO, @"%@ should not be called on abstract class!", NSStringFromSelector(_cmd));
  return NO;
}

- (void)randomize {
  NSAssert(NO, @"%@ should not be called on abstract class!", NSStringFromSelector(_cmd));
}

- (NSString *)name {
  NSAssert(NO, @"%@ should not be called on abstract class!", NSStringFromSelector(_cmd));
  return @"UNDEFINED";
}

- (NSDictionary *)parameters {
  return [self.mutableParameters copy];
}

@end
