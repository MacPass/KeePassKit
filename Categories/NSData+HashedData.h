//
//  NSData+HashedData.h
//  MacPass
//
//  Created by Michael Starke on 21.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
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
- (NSData *)unhashedData;
/**
 *	Hashes the given data using SHA256 hashing and the proviede block size.
 *	@param	blockSize	Size to use for hashing blocks
 *	@return	data wrapped converted to a hased data stream
 */
- (NSData *)hashedDataWithBlockSize:(NSUInteger)blockSize;

@end
