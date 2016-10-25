//
//  KPKChipher.m
//  KeePassKit
//
//  Created by Michael Starke on 02/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKCipher.h"
#import "KPKCipher_Private.h"
#import "KPKHeaderReading.h"

#import "KPKAESCipher.h"
#import "KPKChaCha20Cipher.h"

#import "NSUUID+KeePassKit.h"

@implementation KPKCipher

static NSMutableDictionary<NSUUID *, Class> *_ciphers;

+ (NSUUID *) uuid {
  return [NSUUID nullUUID];
}

+ (KPKCipher *)cipherWithUUID:(NSUUID *)uuid {
  return [self cipherWithUUID:uuid options:@{}];
}

+ (KPKCipher *)cipherWithUUID:(NSUUID *)uuid options:(NSDictionary *)options {
  return [[self alloc] initWithUUID:uuid options:options];
}

+ (NSUInteger)IVLength {
  return 16;
}

+ (NSUInteger)keyLength {
  return 32;
}

+ (void)_registerCipher:(Class)cipherClass {
  NSAssert([cipherClass isSubclassOfClass:[KPKCipher class]], @"Wrong class %@ supplied to register.", NSStringFromClass(cipherClass) );
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

- (KPKCipher *)initWithUUID:(NSUUID *)uuid {
  return [self initWithUUID:uuid options:@{}];
}

- (KPKCipher *)initWithUUID:(NSUUID *)uuid options:(NSDictionary *)options {
  self = nil;
  Class cipherClass = _ciphers[uuid];
  self = [((KPKCipher *)[cipherClass alloc]) _initWithOptions:options];
  return self;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"
- (KPKCipher *)_initWithOptions:(NSDictionary *)options {
  NSAssert(NO, @"%@ should not be called on abstract class!", NSStringFromSelector(_cmd));
  return nil;
}
#pragma clang diagnostic pop

- (NSUUID *)uuid {
  return [self.class uuid];
}

- (NSUInteger)IVLength {
  return  [self.class IVLength];
}

- (NSUInteger)keyLength {
  return [self.class keyLength];
}

- (NSData *)decryptData:(NSData *)data withKey:(NSData *)key initializationVector:(NSData *)iv error:(NSError *__autoreleasing  _Nullable *)error {
  NSAssert(NO, @"%@ should not be called on abstract class!", NSStringFromSelector(_cmd));
  return nil;
}

- (NSData *)encryptData:(NSData *)data withKey:(NSData *)key initializationVector:(NSData *)iv error:(NSError *__autoreleasing  _Nullable *)error {
  NSAssert(NO, @"%@ should not be called on abstract class!", NSStringFromSelector(_cmd));
  return nil;
}

@end
