//
//  KPKChipher.m
//  KeePassKit
//
//  Created by Michael Starke on 02/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKCipher.h"
#import "KPKCipher_Private.h"

#import "KPKAESCipher.h"
#import "KPKChaCha20Cipher.h"

#import "NSUUID+KPKAdditions.h"

@implementation KPKCipher

static NSMutableDictionary<NSUUID *, Class> *_ciphers;

+ (NSUUID *)uuid {
  return [NSUUID kpk_nullUUID];
}

+ (KPKCipher *)cipherWithUUID:(NSUUID *)uuid {
  return [[KPKCipher alloc] initWithUUID:uuid];
}

+ (void)_registerCipher:(Class)cipherClass {
  NSAssert([cipherClass isSubclassOfClass:KPKCipher.class], @"Wrong class %@ supplied to register.", NSStringFromClass(cipherClass) );
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _ciphers = [[NSMutableDictionary alloc] init];
  });
  NSUUID *uuid = [cipherClass uuid];
  if(!uuid) {
    NSAssert(uuid, @"Ciphers must provide a non-nil uuid");
    return;
  }
  if(!_ciphers[uuid]) {
    _ciphers[uuid] = cipherClass;
  }
}

+ (NSArray<KPKCipher *> *)availableCiphers {
  NSMutableArray *array = [[NSMutableArray alloc] init];
  for(NSUUID *uuid in _ciphers) {
    [array addObject:[[_ciphers[uuid] alloc] init]];
  }
  return [array copy];
}

- (KPKCipher *)initWithUUID:(NSUUID *)uuid {
  self = nil;
  Class cipherClass = _ciphers[uuid];
  self = [((KPKCipher *)[cipherClass alloc]) init];
  return self;
}

- (KPKCipher *)initWithKey:(NSData *)key initializationVector:(NSData *)iv {
  if(self.class == KPKCipher.class) {
    NSAssert(NO, @"%@ should not be called on abstract class!", NSStringFromSelector(_cmd));
    return nil;
  }
  self = [super init];
  if(self) {
    _key = [key copy];
    _initializationVector = [iv copy];
  }
  return self;
}

- (NSString *)name {
  NSAssert(NO, @"%@ should not be called on abstract class!", NSStringFromSelector(_cmd));
  return @"ABSTRACT_CIPHER";
}

- (NSUUID *)uuid {
  return [self.class uuid];
}

- (NSUInteger)IVLength {
  return 16;
}

- (NSUInteger)keyLength {
  return 32;
}

- (NSData *)decryptData:(NSData *)data withKey:(NSData *)key initializationVector:(NSData *)iv error:(NSError *__autoreleasing  _Nullable *)error {
  NSAssert(NO, @"%@ should not be called on abstract class!", NSStringFromSelector(_cmd));
  return nil;
}

- (NSData *)encryptData:(NSData *)data withKey:(NSData *)key initializationVector:(NSData *)iv error:(NSError *__autoreleasing  _Nullable *)error {
  NSAssert(NO, @"%@ should not be called on abstract class!", NSStringFromSelector(_cmd));
  return nil;
}

- (NSData * _Nullable)decryptData:(NSData *)data error:(NSError * _Nullable __autoreleasing *)error {
  NSAssert(NO, @"%@ should not be called on abstract class!", NSStringFromSelector(_cmd));
  return nil;
}

- (NSData * _Nullable)encryptData:(NSData *)data error:(NSError * _Nullable __autoreleasing *)error {
  NSAssert(NO, @"%@ should not be called on abstract class!", NSStringFromSelector(_cmd));
  return nil;
}


@end
