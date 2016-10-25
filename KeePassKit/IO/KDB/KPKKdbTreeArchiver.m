//
//  KPKKdbWriter.m
//  KeePassKit
//
//  Created by Michael Starke on 25/10/2016.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKKdbTreeArchiver.h"
#import "KPKTreeArchiver_Private.h"

#import "KPKLegacyTreeWriter.h"
#import "KPKLegacyFormat.h"
#import "KPKKeyDerivation.h"
#import "KPKAESKeyDerivation.h"
#import "KPKCipher.h"
#import "KPKAESCipher.h"
#import "KPKLegacyHeaderUtility.h"

#import "KPKTree.h"
#import "KPKMetaData.h"
#import "KPKCompositeKey.h"

#import "KPKErrors.h"

#import "NSData+Random.h"
#import "NSData+CommonCrypto.h"

#import <CommonCrypto/CommonCrypto.h>
#import <CommonCrypto/CommonCryptoError.h>

@interface KPKKdbTreeArchiver () {
  KPKLegacyHeader _header;
}
@end

@implementation KPKKdbTreeArchiver

- (NSData *)archiveTree:(NSError *__autoreleasing *)error {
  _header.signature1 = CFSwapInt32HostToLittle(kKPKKdbSignature1);
  _header.signature2 = CFSwapInt32HostToLittle(kKPKKdbSignature2);
  /*
   we do not load unsupported KDB files, so we can safely assume only AES encryption is used
   hence we do not adhere to the setting of tree.metaData.cipherUUID
   */
  _header.flags = CFSwapInt32HostToLittle( KPKLegacyEncryptionSHA2 | KPKLegacyEncryptionAES );
  _header.version = CFSwapInt32HostToLittle(kKPKKdbFileVersion);
  
  /* randomize Master seed and encryption iv */
  [[NSData dataWithRandomBytes:sizeof(_header.masterSeed)] getBytes:_header.masterSeed length:sizeof(_header.masterSeed)];
  [[NSData dataWithRandomBytes:sizeof(_header.encryptionIv)] getBytes:_header.encryptionIv length:sizeof(_header.encryptionIv)];
  
  /* initalize the tree writer to get the count of meta entries */
  KPKLegacyTreeWriter *treeWriter = [[KPKLegacyTreeWriter alloc] initWithTree:self.tree];
  
  _header.groups = (uint32_t)self.tree.allGroups.count;
  _header.entries = (uint32_t)(self.tree.allEntries.count + treeWriter.metaEntryCount);
  _header.version = kKPKKdbFileVersion;
  
  /* we only support AES cipher for the KDB  */
  KPKAESKeyDerivation *keyDerivation = (KPKAESKeyDerivation *)[[KPKKeyDerivation alloc] initWithUUID:self.tree.metaData.keyDerivationUUID options:self.tree.metaData.keyDerivationOptions];
  if(!keyDerivation || [keyDerivation.uuid isEqual:[KPKAESKeyDerivation uuid]]) {
    keyDerivation = [[KPKAESKeyDerivation alloc] init];
  }
  /* randomize key derivation */
  [keyDerivation randomize];
  
  NSData *seed = keyDerivation.options[KPKAESSeedOption];
  NSAssert(seed, @"AESKeyDerivation is missing a seed option!");
  [seed getBytes:_header.transformationSeed length:seed.length];
  
  uint32_t clampedRounds = (uint32_t)MIN(keyDerivation.rounds, UINT32_MAX);
  _header.keyEncRounds = CFSwapInt32HostToLittle(clampedRounds);
  
  NSData *headerHash = [KPKLegacyHeaderUtility hashForHeader:&_header];
  NSData *treeData = [treeWriter treeDataWithHeaderHash:headerHash];
  
  /* Save the content hash in the header */
  [treeData.SHA256Hash getBytes:_header.contentsHash length:sizeof(_header.contentsHash)];
  
  /* Create the key to encrypt the data stream from the password */
  NSData *keyData = [self.key transformForFormat:KPKDatabaseFormatKdb seed:self.masterSeed keyDerivation:keyDerivation error:error];
  
  CCCryptorStatus cryptoError = kCCSuccess;
  KPKCipher *cipher = [[KPKAESCipher alloc] init];
  NSData *encryptedTreeData = [cipher encryptData:treeData withKey:keyData initializationVector:self.encryptionIV error:error];
  
  if(cryptoError != kCCSuccess) {
    KPKCreateError(error, KPKErrorAESEncryptionFailed);
    return nil;
  }
  
  /* header */
  NSMutableData *data = [[NSMutableData alloc] initWithBytes:&_header length:sizeof(_header)];
  /* content */
  [data appendData:encryptedTreeData];
  return data;
}

- (NSData *)masterSeed {
  return [[NSData alloc] initWithBytes:_header.masterSeed length:sizeof(_header.masterSeed)];
}

- (NSData *)encryptionIV {
  return [[NSData alloc] initWithBytes:_header.encryptionIv length:sizeof(_header.encryptionIv)];
}


@end
