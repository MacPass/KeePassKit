//
//  KPKPassword.m
//  KeePassKit
//
//  Created by Michael Starke on 12.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//


#import "KPKCompositeKey.h"
#import "KPKFormat.h"
#import "KPKNumber.h"
#import "KPKData.h"

#import "KPKKeyDerivation.h"
#import "KPKAESKeyDerivation.h"
#import "KPKCipher.h"

#import "KPKKey.h"
#import "KPKPasswordKey.h"
#import "KPKFileKey.h"

#import "KPKErrors.h"

#import "NSData+KPKKeyfile.h"
#import "NSData+KPKKeyComputation.h"
#import "NSData+CommonCrypto.h"

#import <CommonCrypto/CommonCrypto.h>

@interface KPKCompositeKey ()

@property (strong) NSMutableArray *keys;

@end

@implementation KPKCompositeKey

+ (BOOL)supportsSecureCoding {
  return YES;
}

- (instancetype)init {
  self = [super init];
  if(self) {
    _keys = [[NSMutableArray alloc] init];
  }
  return self;
}

- (instancetype)initWithKeys:(NSArray<KPKKey *> *)keys {
  self = [self init];
  if(self) {
    for(KPKKey *key in keys) {
      BOOL added = [self addKey:key];
      if(!added) {
        NSLog(@"Did not add key %@", key);
      }
    }
  }
  return self;
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder {
  [coder encodeObject:self.keys forKey:NSStringFromSelector(@selector(keys))];
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder {
  NSMutableArray *keys = [coder decodeObjectOfClasses:[NSSet setWithArray:@[NSMutableArray.class, KPKKey.class]] forKey:NSStringFromSelector(@selector(keys))];
  self = [self initWithKeys:keys];
  return self;
}

- (BOOL)isEqual:(id)object {
  if(self == object) {
    return YES;
  }
  if([object isKindOfClass:self.class]) {
    return [self isEqualToKey:object];
  }
  return NO;
}

- (BOOL)isEqualToKey:(KPKCompositeKey *)key {
  if(self == key) {
    return YES;
  }
  NSAssert([key isKindOfClass:KPKCompositeKey.class], @"Unsupported class for key");
  if(self.keys.count != key.keys.count) {
    return NO;
  }
  /* Keys matches if single keys are the same and the key order is the same */
  for(NSUInteger index = 0; index < self.keys.count; index++) {
    KPKKey *myKey = self.keys[index];
    KPKKey *otherKey = key.keys[index];
    
    NSData *myKdbData = [myKey dataForFormat:KPKDatabaseFormatKdb];
    NSData *otherKdbData = [otherKey dataForFormat:KPKDatabaseFormatKdb];
    if(![myKdbData isEqualToData:otherKdbData]) {
      return NO;
    }
    NSData *myKdbxData = [myKey dataForFormat:KPKDatabaseFormatKdbx];
    NSData *otherKdbxData = [otherKey dataForFormat:KPKDatabaseFormatKdbx];
    if(![myKdbxData isEqualToData:otherKdbxData]) {
      return NO;
    }
  }
  return YES;
}

#pragma mark Properties
- (BOOL)hasKeys {
  return self.keys.count > 0;
}

- (BOOL)hasKeyOfClass:(Class)keyClass {
  return (nil != [self _keyOfClass:keyClass]);
}

- (BOOL)addKey:(KPKKey *)key {
  NSAssert([key.class supportsSecureCoding], @"Keys need to be securely codable!");
  if(nil == key) {
    return NO;
  }
  if([self.keys containsObject:key]) {
    return NO;
  }
  
  [self.keys addObject:key];
  return YES;
}

- (void)_clearKeys {
  [self.keys removeAllObjects];
}

- (NSData *)computeKeyDataForFormat:(KPKDatabaseFormat)format masterseed:(NSData *)seed cipher:(KPKCipher *)cipher keyDerivation:(KPKKeyDerivation *)keyDerivation hmacKey:(NSData **)hmacKey error:(NSError *__autoreleasing *)error {
  NSAssert(seed.length == 32 || seed.length == 16, @"Unexpected seed length");
  /* KDBX uses 32 byte seeds, KDB only 16 */
  if(format != KPKDatabaseFormatKdbx && format != KPKDatabaseFormatKdb) {
    KPKCreateError(error, KPKErrorUnknownFileFormat);
    return nil;
  }
  NSData *keyData = [self _createKeyDataForFormat:format];
  NSData *derivedData = [keyDerivation deriveData:keyData];
  if(!derivedData) {
    KPKCreateError(error, KPKErrorKeyDerivationFailed);
    return nil;
  }
  NSAssert(derivedData.length == 32, @"Invalid key size after key derivation!");
  NSMutableData *workingData = [seed mutableCopy];
  [workingData appendData:derivedData];
  
  /* add 1 byte for Hmac */
  uint8_t oneByte = 0x01;
  [workingData appendBytes:&oneByte length:1];
  if(hmacKey) {
    uint8_t hmacBuffer[64];
    /* full 65 bytes for Hmac */
    CC_SHA512(workingData.bytes, (CC_LONG)workingData.length, hmacBuffer);
    *hmacKey = [NSData dataWithBytes:hmacBuffer length:64];
  }
  /* do not use last 1-byte for key computation */
  return [workingData kpk_resizeKeyDataRange:NSMakeRange(0, workingData.length - 1) toLength:cipher.keyLength];
}

- (NSData *)_createKeyDataForFormat:(KPKDatabaseFormat)format {
  if(format == KPKDatabaseFormatUnknown) {
    return nil; // unkown format, nothing to do
  }
  
  if(self.keys.count == 0) {
    return nil; // no keys, nothing to do
  }
  /* KDB uses the password or file hash directly without re-hashing */
  if(format == KPKDatabaseFormatKdb) {
    KPKKey *passwordKey = [self _keyOfClass:KPKPasswordKey.class];
    KPKKey *fileKey = [self _keyOfClass:KPKFileKey.class];
    
    if(passwordKey && !fileKey) {
      return [passwordKey dataForFormat:KPKDatabaseFormatKdb];
    }
    else if(!passwordKey && fileKey) {
      return [fileKey dataForFormat:KPKDatabaseFormatKdb];
    }
  }
  /* KDBX re-hashes the single keys again, even if only one key is present */
  CC_SHA256_CTX ctx;
  CC_SHA256_Init(&ctx);
  
  for(KPKKey *key in self.keys) {
    NSData *keyData = [key dataForFormat:KPKDatabaseFormatKdbx];
    if(keyData.length == 0) {
      continue;
    }
    NSAssert(keyData.length == kKPKKeyFileLength, @"Unexpected key size");
    CC_SHA256_Update(&ctx, keyData.bytes, (CC_LONG)keyData.length);
  }
  // Finish the hash into the master key
  uint8_t masterKey[ kKPKKeyFileLength];
  CC_SHA256_Final(masterKey, &ctx);
  return [NSData dataWithBytes:masterKey length:kKPKKeyFileLength];
}

- (KPKKey *)_keyOfClass:(Class)keyClass {
  for(KPKKey *key in self.keys) {
    if([key isKindOfClass:keyClass]) {
      return key;
    }
  }
  return nil;
}

@end
