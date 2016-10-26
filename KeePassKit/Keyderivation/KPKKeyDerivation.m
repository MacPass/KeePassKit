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

NSString *const KPKKeyDerivationOptionUUID = @"$UUID";

@implementation KPKKeyDerivation

static NSMutableDictionary *_keyDerivations;

+ (NSDictionary *)defaultOptions {
  return @{ KPKKeyDerivationOptionUUID: [self.class uuid].uuidData };
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

+ (KPKKeyDerivation *)keyDerivationWithOptions:(NSDictionary *)options {
  return [[KPKKeyDerivation alloc] initWithOptions:options];
}

+ (void)parametersForDelay:(NSUInteger)seconds completionHandler:(void (^)(NSDictionary * _Nonnull))completionHandler {
  NSAssert(NO, @"%@ should not be called on abstract class!", NSStringFromSelector(_cmd));
}

+ (NSData * _Nullable)deriveData:(NSData *)data wihtOptions:(NSDictionary *)options {
  KPKKeyDerivation *derivation = [[KPKKeyDerivation alloc] initWithOptions:options];
  return [derivation deriveData:data];
}

- (KPKKeyDerivation *)initWithOptions:(NSDictionary *)options {
  NSData *uuidData = options[KPKKeyDerivationOptionUUID];
  if(!uuidData || ![uuidData isKindOfClass:[NSData class]]) {
    self = nil;
    return self;
  }
  NSUUID *uuid = [[NSUUID alloc] initWithData:uuidData];
  Class keyDerivationClass = _keyDerivations[uuid];
  self = [(KPKKeyDerivation *)[keyDerivationClass alloc] _initWithOptions:options];
  return self;
}

- (KPKKeyDerivation *)_initWithOptions:(NSDictionary *)options {
  self = [self _init];
  if(self) {
    self.mutableOptions  = [options mutableCopy];
  }
  return self;
}

- (KPKKeyDerivation *)_init {
  self = [super init];
  if(self) {
    _mutableOptions = [[NSMutableDictionary alloc] init];
  }
  return self;
}

- (instancetype)init {
  self = [self initWithOptions:[self.class defaultOptions]];
  return self;
}

- (NSData *)deriveData:(NSData *)data {
  NSAssert(NO, @"%@ should not be called on abstract class!", NSStringFromSelector(_cmd));
  return nil;
}

- (NSUUID *)uuid {
  return [self.class uuid];
}

- (void)randomize {
  NSAssert(NO, @"%@ should not be called on abstract class!", NSStringFromSelector(_cmd));
}

- (NSDictionary *)options {
  return [self.mutableOptions copy];
}

@end
