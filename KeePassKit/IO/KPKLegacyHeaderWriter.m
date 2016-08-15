//
//  KPKLegacyHeaderWriter.m
//  KeePassKit
//
//  Created by Michael Starke on 08.08.13.
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

#import "KPKLegacyHeaderWriter.h"
#import "KPKLegacyHeaderUtility.h"
#import "KPKLegacyFormat.h"
#import "KPKFormat.h"
#import "KPKTree.h"
#import "KPKMetaData.h"

#import "NSData+Random.h"

@interface KPKLegacyHeaderWriter () {
  KPKLegacyHeader _header;
  BOOL _headerValid;
}
@property (nonatomic, assign, readonly) KPKLegacyHeader header;
@property (weak) KPKTree *tree;
@end

@implementation KPKLegacyHeaderWriter

@dynamic contentHash;

- (instancetype)initWithTree:(KPKTree *)tree {
  self = [super init];
  if(self) {
    _headerValid = NO;
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
  // Write out the header
  KPKLegacyHeader header = self.header;
  [data appendBytes:&header length:sizeof(header)];
}

- (NSData *)contentHash {
  return [NSData dataWithBytes:_header.contentsHash length:32];
}

- (void)setContentHash:(NSData *)hash {
  if(hash.length == 32) {
    [hash getBytes:&_header.contentsHash length:32];
  }
}

- (void)setGroupCount:(NSUInteger)count {
  NSAssert(count <= UINT32_MAX, @"Count greater than UINT32_MAX");
  _groupCount = count;
  _headerValid = NO;
}

- (void)setEntryCount:(NSUInteger)count {
  NSAssert(count <= UINT32_MAX, @"Count greater than UINT32_MAX");
  _entryCount = count;
  _headerValid = NO;
}

- (NSData *)headerHash {
  KPKLegacyHeader header = self.header;
  return [KPKLegacyHeaderUtility hashForHeader:&header];
}

- (KPKLegacyHeader)header {
  if(!_headerValid) {
    [self _updateHeader];
  }
  return _header;
}

- (void)_updateHeader {
  NSAssert(_groupCount != -1, @"Group count needs to be initalized");
  NSAssert(_entryCount != -1, @"Entry count needs to be initalized");
  _header.signature1 = CFSwapInt32HostToLittle(kKPKBinarySignature1);
  _header.signature2 = CFSwapInt32HostToLittle(kKPKBinarySignature2);
  _header.flags = CFSwapInt32HostToLittle( KPKLegacyEncryptionSHA2 | KPKLegacyEncryptionRijndael );
  _header.version = CFSwapInt32HostToLittle(kKPKBinaryFileVersion);
  
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
}

@end
