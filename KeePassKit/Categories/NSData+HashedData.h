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

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, KPKHashingAlgorithm) {
  KPKSHA256,
  KPKMD5,
};
/**
 Extension to handle blocked hashed data.
 the hashed data has the following structure

 struct HashBlock {
  uint32_t blockIndex;
  uint8_t dataHash[32];
  uint32_t dataLenght;
  void *data;
 };
 
 The stream is terminated with the this block;
 struct TerminationBlock {
  uint32_t blockIndex = blockCount;
  uint8_t dataHash[32] = {0};
  uint32_t dataLenght = 0;
 };
*/
@interface NSData (HashedData)

/**
 @returns YES, if the hashed data's integritry was verified, NO if the hash is corrupted
 */
@property (nonatomic, readonly, copy) NSData *unhashedData;
/**
 *	Hashes the given data using SHA256 hashing and the proviede block size.
 *	@param	blockSize	Size to use for hashing blocks
 *	@return	data wrapped converted to a hased data stream
 */
- (NSData *)hashedDataWithBlockSize:(NSUInteger)blockSize;

@end
