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
#import "NSData+Keyfile.h"

#import <CommonCrypto/CommonCrypto.h>

#define KPK_KEYLENGTH 32

@interface KPKCompositeKey ()
@property (nonatomic, assign) BOOL hasKeyFile;
@property (nonatomic, assign) BOOL hasPassword;
@property (nonatomic, copy) NSData *rawData;

@end

@implementation KPKCompositeKey

+ (void)benchmarkTransformationRounds:(NSUInteger)seconds completionHandler:(void(^)(NSUInteger rounds))completionHandler {
  // Transform the key
  dispatch_queue_t normalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  dispatch_async(normalQueue, ^{
    /* dispatch the benchmark to the background */
    size_t seed = 0xAF09F49F;
    CCCryptorRef cryptorRef;
    CCCryptorCreate(kCCEncrypt, kCCAlgorithmAES128, kCCOptionECBMode, &seed, sizeof(seed), nil, &cryptorRef);
    size_t tmp;
    size_t key = 0x8934BBCD;
    NSUInteger completedRounds = 0;
    NSDate *date = [[NSDate alloc] init];
    /* run transformations until our set time is over */
    while(-[date timeIntervalSinceNow] < seconds) {
      completedRounds++;
      CCCryptorUpdate(cryptorRef, &key, sizeof(size_t), &key, sizeof(size_t), &tmp);
    }
    CCCryptorRelease(cryptorRef);
    dispatch_async(dispatch_get_main_queue(), ^{
      /* call the block on the main thread to return the results */
      completionHandler(completedRounds);
    });
  });
}

- (id)initWithPassword:(NSString *)password key:(NSURL *)url {
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

- (void)setPassword:(NSString *)password andKeyfile:(NSURL *)keyURL {
  self.hasPassword = (password.length > 0);
  self.hasKeyFile = (keyURL != nil);

  if(!password && !keyURL) {
    return;
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
    NSData *keyFileData = [NSData dataWithContentsOfKeyFile:keyURL error:&error];
    if(!keyURL) {
      return; // We are unable to use the keyfile
    }
    // Add the keyfile hash to the master hash
    CC_SHA256_Update(&ctx, keyFileData.bytes, (CC_LONG)keyFileData.length);
  }
  
  // Finish the hash into the master key
  uint8_t masterKey[KPK_KEYLENGTH];
  CC_SHA256_Final(masterKey, &ctx);
  
  /* Store the hashed data */
  self.rawData = [NSData dataWithBytes:masterKey length:KPK_KEYLENGTH];
}

- (NSData *)transformUsingMasterSeed:(NSData *)masterSeed transformSeed:(NSData *)transformSeed rounds:(NSUInteger)rounds {
  // Generate the master key from the credentials
  uint8_t masterKey[KPK_KEYLENGTH];
  [self.rawData getBytes:masterKey length:KPK_KEYLENGTH];

  /* Transform the key */
  CCCryptorRef cryptorRef;
  CCCryptorCreate(kCCEncrypt, kCCAlgorithmAES128, kCCOptionECBMode, transformSeed.bytes, kCCKeySizeAES256, nil, &cryptorRef);
  
  size_t tmp;
  for(int i = 0; i < rounds; i++) {
    CCCryptorUpdate(cryptorRef, masterKey, KPK_KEYLENGTH, masterKey, KPK_KEYLENGTH, &tmp);
  }
  
  CCCryptorRelease(cryptorRef);
  uint8_t transformedKey[KPK_KEYLENGTH];
  CC_SHA256(masterKey, KPK_KEYLENGTH, transformedKey);
  
  /* Hash the master seed with the transformed key into the final key */
  uint8_t finalKey[KPK_KEYLENGTH];
  CC_SHA256_CTX ctx;
  CC_SHA256_Init(&ctx);
  CC_SHA256_Update(&ctx, masterSeed.bytes, (CC_LONG)masterSeed.length);
  CC_SHA256_Update(&ctx, transformedKey, KPK_KEYLENGTH);
  CC_SHA256_Final(finalKey, &ctx);
  
  return [NSData dataWithBytes:finalKey length:KPK_KEYLENGTH];
}

@end
