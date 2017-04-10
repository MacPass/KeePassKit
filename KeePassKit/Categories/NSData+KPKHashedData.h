//
//  NSData+HashedData.h
//  KeePassKit
//
//  Created by Michael Starke on 21.07.13.
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

#import "KPKPlatformIncludes.h"

/**
 Extension to handle blocked hashed data.
 the hashed data has the following structure

 Sha256:
 
 struct HashBlock {
  uint32_t blockIndex;
  uint8_t dataHash[32];
  uint32_t dataLenght;
  void *data;
 };
 
 The stream is terminated with this block;
 struct TerminationBlock {
  uint32_t blockIndex = blockCount;
  uint8_t dataHash[32] = {0};
  uint32_t dataLenght = 0;
 };
 
 HMACSha256:
 
 struct HashBlock {
  uint8_t dataHash[32];
  uint32_t blockSize (in bytes, minimum 0, maximum 231-1, 0 indicates the last block, little-endian encoding).
  uint32_t cipherText[blockSize];
 }
*/
@interface NSData (KPKHashedData)

/* block sizes are defaulted per stream */
@property (nonatomic, readonly) NSData *kpk_hashedSha256Data;
@property (nonatomic, readonly) NSData *kpk_unhashedSha256Data;

- (NSData *)kpk_hashedHmacSha256DataWithKey:(NSData *)key error:(NSError *__autoreleasing *)error;
- (NSData *)kpk_unhashedHmacSha256DataWithKey:(NSData *)key error:(NSError *__autoreleasing *)error;

@end
