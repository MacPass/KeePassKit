//
//  NSData+HashedData.m
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

#import "NSData+HashedData.h"

#import <CommonCrypto/CommonDigest.h>
#import "NSData+CommonCrypto.h"

#define KPKValidateLength(length, location, offset) if(length < location + offset ) { return nil; }

@implementation NSData (HashedData)

- (NSData *)unhashedHmacSha256Data {
  /*
   The HMAC is computed over i ‖ n ‖ C (where little-endian encoding is used for the 64-bit sequence number i and the 32-bit block size n; i is implicit and does not need to be stored).
   The key for the HMAC is different for each block; it is computed as Ki := SHA-512(i ‖ K), where K is a 512-bit key derived from the user's composite master key and the master seed stored in the KDBX header.
   */
  
  NSUInteger blockIndex;
  while(YES) {
    break;
  }
  
  
  
  NSAssert(NO, @"Not implemented!");
  return nil;
  
  /*
   private bool ReadSafeBlock()
   {
   if(m_bEos) return false; // End of stream reached already
   
   byte[] pbStoredHmac = MemUtil.Read(m_sBase, 32);
   if((pbStoredHmac == null) || (pbStoredHmac.Length != 32))
   throw new EndOfStreamException();
   
   // Block index is implicit: it's used in the HMAC computation,
   // but does not need to be stored
   // byte[] pbBlockIndex = MemUtil.Read(m_sBase, 8);
   // if((pbBlockIndex == null) || (pbBlockIndex.Length != 8))
   //	throw new EndOfStreamException();
   // ulong uBlockIndex = MemUtil.BytesToUInt64(pbBlockIndex);
   // if((uBlockIndex != m_uBlockIndex) && m_bVerify)
   //	throw new InvalidDataException();
   byte[] pbBlockIndex = MemUtil.UInt64ToBytes(m_uBlockIndex);
   
   byte[] pbBlockSize = MemUtil.Read(m_sBase, 4);
   if((pbBlockSize == null) || (pbBlockSize.Length != 4))
   throw new EndOfStreamException();
   int nBlockSize = MemUtil.BytesToInt32(pbBlockSize);
   if(nBlockSize < 0)
   throw new InvalidDataException(KLRes.FileCorrupted);
   
   m_iBufferPos = 0;
   
   m_pbBuffer = MemUtil.Read(m_sBase, nBlockSize);
   if((m_pbBuffer == null) || ((m_pbBuffer.Length != nBlockSize) && m_bVerify))
   throw new EndOfStreamException();
   
   if(m_bVerify)
   {
   byte[] pbCmpHmac;
   byte[] pbBlockKey = GetHmacKey64(m_pbKey, m_uBlockIndex);
   using(HMACSHA256 h = new HMACSHA256(pbBlockKey))
   {
   h.TransformBlock(pbBlockIndex, 0, pbBlockIndex.Length,
   pbBlockIndex, 0);
   h.TransformBlock(pbBlockSize, 0, pbBlockSize.Length,
   pbBlockSize, 0);
   
   if(m_pbBuffer.Length > 0)
   h.TransformBlock(m_pbBuffer, 0, m_pbBuffer.Length,
   m_pbBuffer, 0);
   
   h.TransformFinalBlock(MemUtil.EmptyByteArray, 0, 0);
   
   pbCmpHmac = h.Hash;
   }
   MemUtil.ZeroByteArray(pbBlockKey);
   
   if(!MemUtil.ArraysEqual(pbCmpHmac, pbStoredHmac))
   throw new InvalidDataException(KLRes.FileCorrupted);
   }
   
   ++m_uBlockIndex;
   
   if(nBlockSize == 0)
   {
   m_bEos = true;
   return false; // No further data available
   }
   return true;
   }
   
   */
}

- (NSData *)unhashedSha256Data {
  NSUInteger blockIndex = 0;
  NSUInteger location = 0;
  uint32_t indexBuffer = 0;
  uint32_t bufferLength;
  uint8_t hash[32];
  
  NSMutableData *unhashed = [[NSMutableData alloc] initWithCapacity:self.length];
  
  while(YES) {
    
    KPKValidateLength(self.length, location, 4)
    /* Read the block index */
    [self getBytes:&indexBuffer range:NSMakeRange(location, 4)];
    location += 4;
    
    if(indexBuffer != blockIndex) {
      /* Block index is invalid */
      return nil;
    }
    blockIndex++;
    
    KPKValidateLength(self.length, location, 32)
    [self getBytes:hash range:NSMakeRange(location, 32)];
    location += 32;
    
    KPKValidateLength(self.length, location, 4)
    [self getBytes:&bufferLength range:NSMakeRange(location, 4)];
    location += 4;
    
    if(bufferLength == 0) {
      for(int i = 0; i < 32; ++i) {
        if(hash[i] != 0) {
          return nil;
        }
      }
      return unhashed;
    }
    KPKValidateLength(self.length, location, bufferLength)
    uint8_t rawData[bufferLength];
    [self getBytes:rawData range:NSMakeRange(location, bufferLength)];
    location +=bufferLength;
    
    uint8_t verifyHash[32];
    CC_SHA256(rawData, bufferLength, verifyHash);
    if(!memcmp(verifyHash, hash, 32)) {
      [unhashed appendBytes:rawData length:bufferLength];
    }
    if(location == self.length) {
      return unhashed;
    }
  }
}

- (NSData *)hashedHmacSha256Data {
  NSUInteger blockSize = 1024*1024;
  uint32_t blockCount = ceil((CGFloat)self.length / (CGFloat)blockSize);
  
  
  
  /*
   byte[] pbBlockIndex = MemUtil.UInt64ToBytes(m_uBlockIndex);
   
			int cbBlockSize = m_iBufferPos;
			byte[] pbBlockSize = MemUtil.Int32ToBytes(cbBlockSize);
   
			byte[] pbBlockHmac;
			byte[] pbBlockKey = GetHmacKey64(m_pbKey, m_uBlockIndex);
			using(HMACSHA256 h = new HMACSHA256(pbBlockKey))
			{
   h.TransformBlock(pbBlockIndex, 0, pbBlockIndex.Length,
   pbBlockIndex, 0);
   h.TransformBlock(pbBlockSize, 0, pbBlockSize.Length,
   pbBlockSize, 0);
   
   if(cbBlockSize > 0)
   h.TransformBlock(m_pbBuffer, 0, cbBlockSize, m_pbBuffer, 0);
   
   h.TransformFinalBlock(MemUtil.EmptyByteArray, 0, 0);
   
   pbBlockHmac = h.Hash;
			}
			MemUtil.ZeroByteArray(pbBlockKey);
   
			MemUtil.Write(m_sBase, pbBlockHmac);
			// MemUtil.Write(m_sBase, pbBlockIndex); // Implicit
			MemUtil.Write(m_sBase, pbBlockSize);
			if(cbBlockSize > 0)
   m_sBase.Write(m_pbBuffer, 0, cbBlockSize);
   
			++m_uBlockIndex;
			m_iBufferPos = 0;
   }
   
   */
  
  NSAssert(NO, @"Not Implemented!");
  return nil;
}

- (NSData *)hashedSha256Data {
  NSUInteger blockSize = 1024*1024;
  uint32_t blockCount = ceil((CGFloat)self.length / (CGFloat)blockSize);
  uint32_t location = 0;
  NSMutableData *outputData = [[NSMutableData alloc] initWithCapacity:blockCount * (blockSize + 33)];
  uint32_t blockIndex = 0;
  uint32_t blockLength = 0;
  uint8_t hash[32];
  for(; blockIndex < blockCount; blockIndex++) {
    blockLength = MAX(0,MIN((uint32_t)self.length - location, (uint32_t)blockSize));
    uint8_t slice[blockLength];
    [self getBytes:slice range:NSMakeRange(location, blockLength)];
    [outputData appendBytes:&blockIndex length:4];
    CC_SHA256(slice, blockLength, hash);
    [outputData appendBytes:hash length:32];
    [outputData appendBytes:&blockLength length:4];
    [outputData appendBytes:slice length:blockLength];
    location += blockLength;
  }
  /* Write the terminating 0-hash */
  blockLength = 0;
  uint8_t nullHash[32] = {0};
  [outputData appendBytes:&blockIndex length:4];
  [outputData appendBytes:&nullHash length:32];
  [outputData appendBytes:&blockLength length:4];
  return outputData;
}

- (NSData *)_computeHmacKey:(NSData *)key index:(NSUInteger)index {
  NSAssert(key.length == 64, @"Unsupported key size!");
  if(key.length != 64) {
    return nil;
  }
  uint8_t hash[64];
  uint64_t index64 = CFSwapInt64HostToLittle(index);
  CC_SHA512_CTX context;
  CC_SHA512_Init(&context);
  CC_SHA512_Update(&context, key.bytes, (CC_LONG)key.length);
  CC_SHA512_Update(&context, &index64, 8);
  CC_SHA512_Final(hash, &context);
  
  return [NSData dataWithBytes:hash length:64];
}

@end
