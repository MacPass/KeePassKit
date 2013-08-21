//
//  KPKLegacyHeaderWriter.m
//  MacPass
//
//  Created by Michael Starke on 08.08.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import "KPKLegacyHeaderWriter.h"
#import "KPKLegacyHeaderUtility.h"
#import "KPKLegacyFormat.h"
#import "KPKTree.h"
#import "KPKMetaData.h"

#import "NSData+Random.h"

@interface KPKLegacyHeaderWriter () {
  KPKLegacyHeader _header;
}
@property (weak) KPKTree *tree;
@end

@implementation KPKLegacyHeaderWriter

- (id)initWithTree:(KPKTree *)tree {
  self = [super init];
  if(self) {
    _tree = tree;
    _masterSeed = [NSData dataWithRandomBytes:16];
    _encryptionIv = [NSData dataWithRandomBytes:16];
    _transformSeed = [NSData dataWithRandomBytes:32];
    _groupCount = -1;
    _entryCount = -1;
  }
  return self;
}

- (uint32_t)transformationRounds {
  return _header.keyEncRounds;
}

- (void)writeHeaderData:(NSMutableData *)data {
  NSAssert(_groupCount != -1, @"Group count needs to be initalized");
  NSAssert(_entryCount != -1, @"Entry count needs to be initalized");
  _header.signature1 = CFSwapInt32HostToLittle(KPK_LEGACY_SIGNATURE_1);
  _header.signature2 = CFSwapInt32HostToLittle(KPK_LEGACY_SIGNATURE_2);
  _header.flags = CFSwapInt32HostToLittle( KPKLegacyEncryptionSHA2 | KPKLegacyEncryptionRijndael );
  _header.version = CFSwapInt32HostToLittle(KPK_LEGACY_FILE_VERSION);
  
  /* Master seed and encryption iv */
  [_masterSeed getBytes:_header.masterSeed length:sizeof(_header.masterSeed)];
  [_encryptionIv getBytes:_header.encryptionIv length:sizeof(_header.encryptionIv)];
  
  /* Number of groups */
  _header.groups = CFSwapInt32HostToLittle((uint32_t)_groupCount);
  
  /* Number of entries */
  _header.entries = CFSwapInt32HostToLittle((uint32_t)_entryCount);
  
  /* Skip the content hash for now, it will get filled in after the content is written */
  
  /* Master seed #2 */
  [_transformSeed getBytes:_header.masterSeed2 length:sizeof(_header.masterSeed2)];
  
  /*
   Number of key encryption rounds
   Since we use 64 bits in the new format
   we have to clamp to the maxium possible
   size in 32 bit legacy format
   */
  uint32_t rounds = (uint32_t)MIN(_tree.metaData.rounds, UINT32_MAX);
  _header.keyEncRounds = CFSwapInt32HostToLittle(rounds);
  
  // Write out the header
  [data appendBytes:&_header length:sizeof(_header)];
}

- (void)setContentHash:(NSData *)hash {
  if([hash length] == 32) {
    [hash getBytes:&_header.contentsHash length:32];
  }
}

- (void)setGroupCount:(NSUInteger)count {
  NSAssert(count <= UINT32_MAX, @"Count greater than UINT32_MAX");
  _entryCount = count;
}

- (void)setEntryCount:(NSUInteger)count {
  NSAssert(count <= UINT32_MAX, @"Count greater than UINT32_MAX");
  _groupCount = count;
}

- (NSData *)headerHash {
  return [KPKLegacyHeaderUtility hashForHeader:&_header];
}

@end
