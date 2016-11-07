//
//  KPKKdbTreeUnarchiver.m
//  KeePassKit
//
//  Created by Michael Starke on 25/10/2016.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKKdbUnarchiver.h"
#import "KPKUnarchiver_Private.h"

#import "KPKErrors.h"
#import "KPKFormat.h"
#import "KPKKdbFormat.h"
#import "KPKKdbTreeReader.h"

#import "KPKTree.h"
#import "KPKMetaData.h"
#import "KPKCompositeKey.h"

#import "KPKAESCipher.h"
#import "KPKTwofishCipher.h"
#import "KPKAESKeyDerivation.h"

#import "KPKNumber.h"

#import "NSData+KPKKeyComputation.h"

@interface KPKKdbUnarchiver () {
  KPKLegacyHeader _header;
}
@property (readonly) NSUInteger headerLength;
@property (copy, nonatomic, readonly) NSData *masterSeed;
@property (copy, nonatomic, readonly) NSData *encryptionIV;
@property (readonly) uint32_t numberOfEntries;
@property (readonly) uint32_t numberOfGroups;

@end

@implementation KPKKdbUnarchiver

- (instancetype)_initWithData:(NSData *)data version:(NSUInteger)version key:(KPKCompositeKey *)key error:(NSError *__autoreleasing *)error {
  self = [super _initWithData:data version:version key:key error:error];
  if(self) {
    // Read in the header
    if(data.length < sizeof(KPKLegacyHeader)) {
      KPKCreateError(error, KPKErrorKdbHeaderTruncated);
      self = nil;
      return self;
    }
    [data getBytes:&_header range:NSMakeRange(0, sizeof(KPKLegacyHeader))];
    /*
     Signature Check was done by KPKFormat to determine the correct Cryptor
     */
    
    _header.version = CFSwapInt32LittleToHost(_header.version);
    if ((_header.version & kKPKKdbFileVersionMask) != (kKPKKdbFileVersion & kKPKKdbFileVersionMask)) {
      KPKCreateError(error, KPKErrorUnsupportedDatabaseVersion);
    }
    
    // Check the encryption algorithm
    _header.flags = CFSwapInt32LittleToHost(_header.flags);
    if(_header.flags & KPKLegacyEncryptionAES) {
      self.cipherUUID = [KPKAESCipher uuid];
    }
    if(_header.flags & KPKLegacyEncryptionTwoFish) {
      self.cipherUUID = [KPKTwofishCipher uuid];
    }
    
    if(!self.cipherUUID) {
      KPKCreateError(error, KPKErrorUnsupportedCipher);
      self = nil;
      return self;
    }
    
    _header.groups = CFSwapInt32LittleToHost(_header.groups);
    _header.entries = CFSwapInt32LittleToHost(_header.entries);
    
    _header.keyEncRounds = CFSwapInt32LittleToHost(_header.keyEncRounds);
    self.mutableKeyDerivationParameters = [[KPKAESKeyDerivation defaultParameters] mutableCopy];
    self.mutableKeyDerivationParameters[KPKAESRoundsOption] = [[KPKNumber alloc] initWithUnsignedInteger64:_header.keyEncRounds];
    self.mutableKeyDerivationParameters[KPKAESSeedOption] = [[NSData alloc] initWithBytes:_header.transformationSeed length:sizeof(_header.transformationSeed)];
  }
  return self;
}
- (KPKTree *)tree:(NSError * _Nullable __autoreleasing *)error {
  /* todo encrypt */
  KPKKeyDerivation *keyDerivation = [[KPKKeyDerivation alloc] initWithParameters:self.mutableKeyDerivationParameters];
  if(!keyDerivation) {
    KPKCreateError(error, KPKErrorUnsupportedKeyDerivation);
    return nil;
  }
  
  KPKCipher *cipher = [[KPKCipher alloc] initWithUUID:self.cipherUUID];
  NSData *keyData = [self.key computeKeyDataForFormat:KPKDatabaseFormatKdb
                                           masterseed:self.masterSeed
                                               cipher:cipher
                                        keyDerivation:keyDerivation
                                              hmacKey:nil
                                                error:error];
  if(!keyData) {
    return nil;
  }
  
  NSData *contentData = [self.data subdataWithRange:NSMakeRange(self.headerLength, self.data.length - self.headerLength)];
  NSData *decryptedData = [cipher decryptData:contentData withKey:keyData initializationVector:self.encryptionIV error:error];
  if(!decryptedData) {
    return nil;
  }
  
  KPKKdbTreeReader *treeReader = [[KPKKdbTreeReader alloc] initWithData:decryptedData numberOfEntries:self.numberOfEntries numberOfGroups:self.numberOfGroups];
  KPKTree *tree = [treeReader tree:error];
  tree.metaData.keyDerivationParameters = [self.mutableKeyDerivationParameters copy];
  return tree;
}

- (NSData *)masterSeed {
  return [NSData dataWithBytes:_header.masterSeed length:sizeof(_header.masterSeed)];
}

- (NSData *)encryptionIV {
  return [NSData dataWithBytes:_header.encryptionIV length:sizeof(_header.encryptionIV)];
}

- (uint32_t)numberOfGroups {
  return _header.groups;
}

- (uint32_t)numberOfEntries {
  return _header.entries;
}

- (NSUInteger)headerLength {
  return sizeof(_header);
}

@end
