//
//  KPKKDBFileHeader.m
//  KeePassKit
//
//  Created by Michael Starke on 14/10/2016.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKKdbFileHeader.h"
#import "KPKFileHeader_Private.h"

#import "KPKTree.h"
#import "KPKMetaData.h"
#import "KPKNumber.h"

#import "KPKErrors.h"
#import "KPKLegacyHeaderUtility.h"
#import "KPKLegacyFormat.h"

#import "KPKKeyDerivation.h"
#import "KPKAESKeyDerivation.h"

#import "NSData+Random.h"

@interface KPKKdbFileHeader () {
  KPKLegacyHeader _header;
  BOOL _headerDataValid;
}
@end

@implementation KPKKdbFileHeader

- (instancetype)_initWithTree:(KPKTree *)tree fileInfo:(KPKFileInfo)fileInfo {
  self = [super _initWithTree:tree fileInfo:fileInfo];
  if(self) {
    _headerDataValid = NO;
    _header.signature1 = CFSwapInt32HostToLittle(kKPKKdbSignature1);
    _header.signature2 = CFSwapInt32HostToLittle(kKPKKdbSignature2);
    /* kdx is stored with AES encryption and SHA hash */
    _header.flags = CFSwapInt32HostToLittle( KPKLegacyEncryptionSHA2 | KPKLegacyEncryptionAES );
    _header.version = CFSwapInt32HostToLittle(kKPKKdbFileVersion);
    
    /* Master seed and encryption iv */
    
    [[NSData dataWithRandomBytes:16] getBytes:_header.masterSeed length:sizeof(_header.masterSeed)];
    [[NSData dataWithRandomBytes:16] getBytes:_header.encryptionIv length:sizeof(_header.encryptionIv)];
    
    /* Number of groups */
    _header.groups = CFSwapInt32HostToLittle((uint32_t)self.tree.allGroups.count);
    /* Number of entries */
    _header.entries = -1;//CFSwapInt32HostToLittle((uint32_t)_entryCount);
    
    /* Master seed #2 */
    [[NSData dataWithRandomBytes:32] getBytes:_header.masterSeed2 length:sizeof(_header.masterSeed2)];
    
    /*
     Number of key encryption rounds
     Since we use 64 bits in the new format
     we have to clamp to the maxium possible
     size in 32 bit legacy format
     */
    
    /* we only support aes cipher for the legacy writer */
    KPKAESKeyDerivation *keyDerivation = (KPKAESKeyDerivation *)[[KPKKeyDerivation alloc] initWithUUID:self.tree.metaData.keyDerivationUUID options:self.tree.metaData.keyDerivationOptions];
    if(!keyDerivation || [keyDerivation.uuid isEqual:[KPKAESKeyDerivation uuid]]) {
      keyDerivation = [[KPKAESKeyDerivation alloc] init];
    }
    uint32_t clampedRounds = (uint32_t)MIN(keyDerivation.rounds, UINT32_MAX);
    _header.keyEncRounds = CFSwapInt32HostToLittle(clampedRounds);
  }
  return self;
}

- (instancetype)_initWithData:(NSData *)data error:(NSError *__autoreleasing *)error {
  self = [super _initWithData:data error:error];
  if(self) {
    _headerDataValid = NO;
    // Read in the header
    if(data.length < sizeof(KPKLegacyHeader)) {
      KPKCreateError(error, KPKErrorHeaderCorrupted, @"ERROR_HEADER_CORRUPTED", "");
      self = nil;
      return self;
    }
    [data getBytes:&_header range:NSMakeRange(0, sizeof(KPKLegacyHeader))];
    /*
     Signature Check was done by KPKFormat to determine the correct Cryptor
     */
    
    _header.version = CFSwapInt32LittleToHost(_header.version);
    if ((_header.version & kKPKKdbFileVersionMask) != (kKPKKdbFileVersion & kKPKKdbFileVersionMask)) {
      KPKCreateError(error, KPKErrorUnsupportedDatabaseVersion, @"ERROR_UNSUPPORTED_DATABASER_VERSION", "");
    }
    
    // Check the encryption algorithm
    _header.flags = CFSwapInt32LittleToHost(_header.flags);
    if (!(_header.flags & KPKLegacyEncryptionAES)) {
      KPKCreateError(error, KPKErrorUnsupportedCipher, @"ERROR_UNSUPPORTED_CIPHER", "");
      self = nil;
      return self;
      //@throw [NSException exceptionWithName:@"IOException" reason:@"Unsupported algorithm" userInfo:nil];
    }
    
    _header.groups = CFSwapInt32LittleToHost(_header.groups);
    _header.entries = CFSwapInt32LittleToHost(_header.entries);
    KPKNumber *rounds = [KPKNumber numberWithInteger64:CFSwapInt32LittleToHost(_header.keyEncRounds)];
    
    self.keyDerivationUUID = [KPKAESKeyDerivation uuid];
    self.keyDerivationOptions = @{ KPKAESSeedOption: [[NSData alloc] initWithBytes:_header.masterSeed2 length:sizeof(_header.masterSeed2)],
                                   KPKAESRoundsOption : rounds
                                   };
  }
  _headerDataValid = YES;
  return self;
}

- (NSUInteger)numberOfEntries {
  NSAssert(_headerDataValid, @"Header has no valid data!");
  return _header.entries;
}

- (NSUInteger)numberOfGroups {
  NSAssert(_headerDataValid, @"Header has no valid data!");
  return _header.groups;
}

- (NSData *)masterSeed {
  NSAssert(_headerDataValid, @"Header has no valid data!");
  return [[NSData alloc] initWithBytes:_header.masterSeed length:sizeof(_header.masterSeed)];
}

- (NSData *)encryptionIV {
  NSAssert(_headerDataValid, @"Header has no valid data!");
  return [[NSData alloc] initWithBytes:_header.encryptionIv length:sizeof(_header.encryptionIv)];
}

- (NSData *)headerHash {
  NSAssert(_headerDataValid, @"Header has no valid data!");
  if(!_headerDataValid) {
    return nil;
  }
  return [KPKLegacyHeaderUtility hashForHeader:&_header];;
}

- (NSData *)headerData {
  NSAssert(_headerDataValid, @"Header has no valid data!");
  if(!_headerDataValid) {
    return nil;
  }
  return [NSData dataWithBytes:&_header length:sizeof(_header)];
}

@end
