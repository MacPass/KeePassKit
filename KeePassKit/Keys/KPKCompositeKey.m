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

#import "KPKKeyDerivation.h"
#import "KPKAESKeyDerivation.h"
#import "KPKCipher.h"

#import "KPKErrors.h"

#import "NSData+Keyfile.h"
#import "NSData+KPKKeyComputation.h"
#import "NSData+CommonCrypto.h"

#import <CommonCrypto/CommonCrypto.h>

@interface KPKCompositeKey () {
  NSData *_kdbKeyData;
  NSData *_kdbxKeyData;
}

@property (nonatomic) BOOL hasKeyFile;
@property (nonatomic) BOOL hasPassword;

@end

@implementation KPKCompositeKey

- (instancetype)initWithPassword:(NSString *)password key:(NSURL *)url {
  self = [super init];
  if(self) {
    [self setPassword:password andKeyfile:url];
  }
  return self;
}

#pragma mark Properties
- (BOOL)hasPasswordOrKeyFile {
  return (self.hasPassword || self.hasKeyFile);
}

- (void)setPassword:(NSString *)password andKeyfile:(NSURL *)key {
  _hasPassword = (password.length > 0);
  _hasKeyFile = (key != nil);
  _kdbKeyData = [self _createKdbDataWithPassword:password keyFile:key];
  _kdbxKeyData = [self _createKdbxDataWithPassword:password keyFile:key];
}

- (BOOL)testPassword:(NSString *)password key:(NSURL *)key forVersion:(KPKDatabaseFormat)version {
  NSData *data;
  switch(version) {
    case KPKDatabaseFormatKdb:
      data = [self _createKdbDataWithPassword:password keyFile:key];
      break;
    case KPKDatabaseFormatKdbx:
      data = [self _createKdbxDataWithPassword:password keyFile:key];
      break;
    default:
      return NO;
  }
  if(data) {
    NSData *compare = (version == KPKDatabaseFormatKdb) ? _kdbKeyData : _kdbxKeyData;
    return [data isEqualToData:compare];
  }
  return NO;
}

- (NSData *)computeKeyDataForFormat:(KPKDatabaseFormat)format masterseed:(NSData *)seed cipher:(KPKCipher *)cipher keyDerivation:(KPKKeyDerivation *)keyDerivation hmacKey:(NSData *__autoreleasing *)hmacKey error:(NSError *__autoreleasing *)error {
  NSAssert(seed.length == 32 || seed.length == 16, @"Unexpected seed length");
  /* KDBX uses 32 byte seeds, KDB only 16 */
  if(format != KPKDatabaseFormatKdbx && format != KPKDatabaseFormatKdb) {
    KPKCreateError(error, KPKErrorUnknownFileFormat);
    return nil;
  }
  NSData *derivedData = (format == KPKDatabaseFormatKdb) ? [keyDerivation deriveData:_kdbKeyData] : [keyDerivation deriveData:_kdbxKeyData];
  if(!derivedData) {
    KPKCreateError(error, KPKErrorKeyDerivationFailed);
    return nil;
  }
  NSAssert(derivedData.length == 32, @"Invalid key size after key derivation!");
  NSMutableData *workingData = [seed mutableCopy];
  [workingData appendData:derivedData];
  
  /* add 1 null byte for Hmac */
  uint8_t nullByte = 0;
  [workingData appendBytes:&nullByte length:1];
  if(hmacKey) {
    uint8_t hmacBuffer[64];
    /* full 65 bytes for Hmac */
    CC_SHA512(workingData.bytes, (CC_LONG)workingData.length, hmacBuffer);
    *hmacKey = [NSData dataWithBytes:hmacBuffer length:64];
  }
  /* do not use last 0-byte for key computation */
  return [workingData resizeKeyDataRange:NSMakeRange(0, workingData.length - 1) toLength:cipher.keyLength];
}

- (NSData *)_createKdbDataWithPassword:(NSString *)password keyFile:(NSURL *)keyURL {
  if(!password && !keyURL) {
    return nil;
  }
  uint8_t masterKey[ kKPKKeyFileLength];
  if(password && !keyURL) {
    /* Hash the password into the master key FIXME: PasswordEncoding! */
    NSData *passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];
    CC_SHA256(passwordData.bytes, (CC_LONG)passwordData.length, masterKey);
  }
  else if(!password && keyURL) {
    /* Get the bytes from the keyfile */
    NSError *error = nil;
    NSData *keyFileData = [NSData dataWithContentsOfKeyFile:keyURL version:KPKDatabaseFormatKdb error:&error];
    if(!keyFileData) {
      NSLog(@"Error while trying to load keyfile:%@", error.localizedDescription);
      return nil;
    }
    [keyFileData getBytes:masterKey length:32];
  }
  else {
    /* Hash the password */
    uint8_t passwordHash[32];
    NSData *passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];
    CC_SHA256(passwordData.bytes, (CC_LONG)passwordData.length, passwordHash);
    
    /* Get the bytes from the keyfile */
    NSError *error = nil;
    NSData *keyFileData = [NSData dataWithContentsOfKeyFile:keyURL version:KPKDatabaseFormatKdb error:&error];
    if( keyFileData == nil) {
      return nil;
    }
    
    /* Hash the password and keyfile into the master key */
    CC_SHA256_CTX ctx;
    CC_SHA256_Init(&ctx);
    CC_SHA256_Update(&ctx, passwordHash, 32);
    CC_SHA256_Update(&ctx, keyFileData.bytes, 32);
    CC_SHA256_Final(masterKey, &ctx);
  }
  return [NSData dataWithBytes:masterKey length:kKPKKeyFileLength];
}

- (NSData *)_createKdbxDataWithPassword:(NSString *)password keyFile:(NSURL *)keyURL {
  if(!password && !keyURL) {
    return nil;
  }
  
  // Initialize the master hash
  CC_SHA256_CTX ctx;
  CC_SHA256_Init(&ctx);
  
  // Add the password to the master key if it was supplied
  if(password) {
    // Get the bytes from the password using the supplied encoding
    NSData *passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];
    
    // Hash the password
    uint8_t hash[32];
    CC_SHA256(passwordData.bytes, (CC_LONG)passwordData.length, hash);
    
    // Add the password hash to the master hash
    CC_SHA256_Update(&ctx, hash, 32);
  }
  
  // Add the keyfile to the master key if it was supplied
  if (keyURL) {
    // Get the bytes from the keyfile
    NSError *error = nil;
    NSData *keyFileData = [NSData dataWithContentsOfKeyFile:keyURL version:KPKDatabaseFormatKdbx error:&error];
    if(!keyURL) {
      return nil;
    }
    // Add the keyfile hash to the master hash
    CC_SHA256_Update(&ctx, keyFileData.bytes, (CC_LONG)keyFileData.length);
  }
  
  // Finish the hash into the master key
  uint8_t masterKey[kKPKKeyFileLength];
  CC_SHA256_Final(masterKey, &ctx);
  return [NSData dataWithBytes:masterKey length:kKPKKeyFileLength];
}

@end
