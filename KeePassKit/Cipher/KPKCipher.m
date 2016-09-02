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
#import "KPKChaChaCipher.h"

#import "NSUUID+KeePassKit.h"

@implementation KPKCipher

static NSMutableDictionary<NSUUID *, Class> *_ciphers;

+ (NSUUID *) uuid {
  return [NSUUID nullUUID];
}

+ (KPKCipher *)chipherForUUID:(NSUUID *)uuid {
  Class chipherClass = _ciphers[uuid];
  return [[chipherClass alloc] init];
}

+ (KPKCipher *)aesCipher {
  return [[KPKAESCipher alloc] init];
}

+ (KPKCipher *)chaChaCipher {
  return [[KPKChaChaCipher alloc] init];
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

- (NSUUID *)uuid {
  return [[self class] uuid];
}

- (NSData *)decryptDataWithHeaderReader:(id<KPKHeaderReading>)headerReader withKey:(NSData *)key error:(NSError * _Nullable __autoreleasing *)error {
  NSAssert(NO, @"%@ should not be called on abstract class!", NSStringFromSelector(_cmd));
  return nil;
}

- (NSData *)encryptDataWithHeaderReader:(id<KPKHeaderReading>)headerReader withKey:(NSData *)key error:(NSError *__autoreleasing  _Nullable *)error {
  NSAssert(NO, @"%@ should not be called on abstract class!", NSStringFromSelector(_cmd));
  return nil;
}

@end
