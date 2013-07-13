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


#import "KPKPassword.h"
#import "NSData+Keyfile.h"

#import <CommonCrypto/CommonCrypto.h>

#define KPK_KEYLENGTH 32

@interface KPKPassword () {
  NSData *_compositeData;
}
@end

@implementation KPKPassword

- (id)initWithPassword:(NSString *)password key:(NSURL *)url {
  self = [super init];
  if(self) {
    _compositeData = [self _createCompositeDataWithPassword:password key:url];
  }
  return self;
}

- (NSData *)finalDataForVersion:(KPKDatabaseVersion)version
                     masterSeed:(NSData *)masterSeed
                  transformSeed:(NSData *)transformSeed
                         rounds:(NSUInteger)rounds {
  // Generate the master key from the credentials
  uint8_t masterKey[KPK_KEYLENGTH];
  [_compositeData getBytes:masterKey length:KPK_KEYLENGTH];
  
  // Transform the key
  CCCryptorRef cryptorRef;
  CCCryptorCreate(kCCEncrypt, kCCAlgorithmAES128, kCCOptionECBMode, transformSeed.bytes, kCCKeySizeAES256, nil, &cryptorRef);
  
  size_t tmp;
  for(int i = 0; i < rounds; i++) {
    CCCryptorUpdate(cryptorRef, masterKey, KPK_KEYLENGTH, masterKey, KPK_KEYLENGTH, &tmp);
  }
  
  CCCryptorRelease(cryptorRef);
  uint8_t transformedKey[KPK_KEYLENGTH];
  CC_SHA256(masterKey, KPK_KEYLENGTH, transformedKey);
  
  // Hash the master seed with the transformed key into the final key
  uint8_t finalKey[KPK_KEYLENGTH];
  CC_SHA256_CTX ctx;
  CC_SHA256_Init(&ctx);
  CC_SHA256_Update(&ctx, masterSeed.bytes, (CC_LONG)masterSeed.length);
  CC_SHA256_Update(&ctx, transformedKey, KPK_KEYLENGTH);
  CC_SHA256_Final(finalKey, &ctx);
  
  return [NSData dataWithBytes:finalKey length:KPK_KEYLENGTH];
}

- (NSData *)_createCompositeDataWithPassword:(NSString *)password key:(NSURL *)keyURL {
  uint8_t masterKey[KPK_KEYLENGTH];
  if(password && !keyURL) {
    // Hash the password into the master key
    // FIXME: PasswordEncoding!
    NSData *passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];
    CC_SHA256(passwordData.bytes, (CC_LONG)passwordData.length, masterKey);
  }
  else if(!password && keyURL) {
    // Get the bytes from the keyfile
    NSData *keyFileData;// = [self loadKeyFileV3:keyURL];
    if(!keyFileData) {
      return nil;
    }
    [keyFileData getBytes:masterKey length:32];
  }
  else {
    // Hash the password
    uint8_t passwordHash[32];
    NSData *passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];
    CC_SHA256(passwordData.bytes, (CC_LONG)passwordData.length, passwordHash);
    
    // Get the bytes from the keyfile
    NSData *keyFileData = [NSData dataWithWithContentsOfKeyFile:keyURL error:nil];
    //NSData *keyFileData =  [self _loadKeyFileV3:keyURL];
    if( keyFileData == nil) {
      return nil;
    }
    
    // Hash the password and keyfile into the master key
    CC_SHA256_CTX ctx;
    CC_SHA256_Init(&ctx);
    CC_SHA256_Update(&ctx, passwordHash, 32);
    CC_SHA256_Update(&ctx, keyFileData.bytes, 32);
    CC_SHA256_Final(masterKey, &ctx);
  }
  return [NSData dataWithBytes:masterKey length:KPK_KEYLENGTH];
}

@end
