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

#import "KPKErrors.h"

#import "NSData+KPKKeyfile.h"
#import "NSData+KPKKeyComputation.h"
#import "NSData+CommonCrypto.h"

#import <CommonCrypto/CommonCrypto.h>

@interface KPKCompositeKey ()

@property (copy) KPKData *kdbKeyData;
@property (copy) KPKData *kdbxKeyData;

@property (nonatomic) BOOL hasKeyFile;
@property (nonatomic) BOOL hasPassword;

@end

@implementation KPKCompositeKey

- (instancetype)initWithPassword:(NSString *)password keyFileData:(NSData *)keyFileData {
  self = [super init];
  if(self) {
    [self setPassword:password andKeyFileData:keyFileData];
  }
  return self;
}

#pragma mark Properties
- (BOOL)hasPasswordOrKeyFile {
  return (self.hasPassword || self.hasKeyFile);
}

- (void)setPassword:(NSString *)password andKeyFileData:(NSData *)keyFileData {
  self.hasPassword = (password.length > 0);
  self.hasKeyFile = (keyFileData.length > 0);
  self.kdbKeyData = [[KPKData alloc] initWithProtectedData:[self _createKdbDataWithPassword:password keyFileData:keyFileData]];
  self.kdbxKeyData = [[KPKData alloc] initWithProtectedData:[self _createKdbxDataWithPassword:password keyFileData:keyFileData]];
}

- (BOOL)testPassword:(NSString *)password keyFileData:(NSData *)keyFileData forVersion:(KPKDatabaseFormat)version {
  NSData *data;
  switch(version) {
    case KPKDatabaseFormatKdb:
      data = [self _createKdbDataWithPassword:password keyFileData:keyFileData];
      break;
    case KPKDatabaseFormatKdbx:
      data = [self _createKdbxDataWithPassword:password keyFileData:keyFileData];
      break;
    default:
      return NO;
  }
  if(data) {
    KPKData *compare = (version == KPKDatabaseFormatKdb) ? self.kdbKeyData : self.kdbxKeyData;
    return [data isEqualToData:compare.data];
  }
  return NO;
}

- (NSData *)computeKeyDataForFormat:(KPKDatabaseFormat)format masterseed:(NSData *)seed cipher:(KPKCipher *)cipher keyDerivation:(KPKKeyDerivation *)keyDerivation hmacKey:(NSData **)hmacKey error:(NSError *__autoreleasing *)error {
  NSAssert(seed.length == 32 || seed.length == 16, @"Unexpected seed length");
  /* KDBX uses 32 byte seeds, KDB only 16 */
  if(format != KPKDatabaseFormatKdbx && format != KPKDatabaseFormatKdb) {
    KPKCreateError(error, KPKErrorUnknownFileFormat);
    return nil;
  }
  NSData *derivedData = (format == KPKDatabaseFormatKdb) ? [keyDerivation deriveData:self.kdbKeyData.data] : [keyDerivation deriveData:self.kdbxKeyData.data];
  if(!derivedData) {
    KPKCreateError(error, KPKErrorKeyDerivationFailed);
    return nil;
  }
  NSAssert(derivedData.length == 32, @"Invalid key size after key derivation!");
  NSMutableData *workingData = [seed mutableCopy];
  [workingData appendData:derivedData];
  
  /* add 1 null byte for Hmac */
  uint8_t oneByte = 0x01;
  [workingData appendBytes:&oneByte length:1];
  if(hmacKey) {
    uint8_t hmacBuffer[64];
    /* full 65 bytes for Hmac */
    CC_SHA512(workingData.bytes, (CC_LONG)workingData.length, hmacBuffer);
    *hmacKey = [NSData dataWithBytes:hmacBuffer length:64];
  }
  /* do not use last 0-byte for key computation */
  return [workingData kpk_resizeKeyDataRange:NSMakeRange(0, workingData.length - 1) toLength:cipher.keyLength];
}

- (NSData *)_createKdbDataWithPassword:(NSString *)password keyFileData:(NSData *)keyFileData {
  if(!password && !keyFileData) {
    return nil;
  }
  uint8_t masterKey[ kKPKKeyFileLength];
  if(password && !keyFileData) {
    /* Hash the password into the master key FIXME: PasswordEncoding! */
    NSData *passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];
    CC_SHA256(passwordData.bytes, (CC_LONG)passwordData.length, masterKey);
  }
  else if(!password && keyFileData) {
    /* Get the bytes from the keyfile */
    NSError *error = nil;
    NSData *keyData = [NSData kpk_keyDataForData:keyFileData version:KPKDatabaseFormatKdb error:&error];
    if(!keyData) {
      NSLog(@"Error while trying to load keyfile:%@", error.localizedDescription);
      return nil;
    }
    [keyData getBytes:masterKey length:32];
  }
  else {
    /* Hash the password */
    uint8_t passwordHash[32];
    NSData *passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];
    CC_SHA256(passwordData.bytes, (CC_LONG)passwordData.length, passwordHash);
    
    /* Get the bytes from the keyfile */
    NSError *error = nil;
    NSData *keyData = [NSData kpk_keyDataForData:keyFileData version:KPKDatabaseFormatKdb error:&error];
    if( keyData == nil) {
      return nil;
    }
    
    /* Hash the password and keyfile into the master key */
    CC_SHA256_CTX ctx;
    CC_SHA256_Init(&ctx);
    CC_SHA256_Update(&ctx, passwordHash, 32);
    CC_SHA256_Update(&ctx, keyData.bytes, 32);
    CC_SHA256_Final(masterKey, &ctx);
  }
  return [NSData dataWithBytes:masterKey length:kKPKKeyFileLength];
}

- (NSData *)_createKdbxDataWithPassword:(NSString *)password keyFileData:(NSData *)keyFileData {
  if(!password && !keyFileData) {
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
  if (keyFileData) {
    // Transform the keydata to the correct format
    NSError *error = nil;
    NSData *keyData = [NSData kpk_keyDataForData:keyFileData version:KPKDatabaseFormatKdbx error:&error];
    if(!keyData) {
      return nil;
    }
    // Add the keyfile hash to the master hash
    CC_SHA256_Update(&ctx, keyData.bytes, (CC_LONG)keyData.length);
  }
  
  // Finish the hash into the master key
  uint8_t masterKey[kKPKKeyFileLength];
  CC_SHA256_Final(masterKey, &ctx);
  return [NSData dataWithBytes:masterKey length:kKPKKeyFileLength];
}

@end
