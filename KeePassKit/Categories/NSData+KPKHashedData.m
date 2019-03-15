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

#import "NSData+KPKHashedData.h"

#import "KPKDataStreamReader.h"
#import "KPKDataStreamWriter.h"
#import "KPKErrors.h"

#import "NSData+CommonCrypto.h"
#import "NSData+KPKKeyComputation.h"

#import <CommonCrypto/CommonHMAC.h>
#import <CommonCrypto/CommonDigest.h>

#define KPKValidateLength(length, location, offset) if(length < location + offset ) { return nil; }

@implementation NSData (KPKHashedData)

- (NSData *)kpk_unhashedHmacSha256DataWithKey:(NSData *)key error:(NSError *__autoreleasing *)error {
  
  KPKDataStreamReader *reader = [[KPKDataStreamReader alloc] initWithData:self];
  NSMutableData *unhashedData = [[NSMutableData alloc] initWithCapacity:self.length];
  
  uint64_t blockIndex = 0;
  uint8_t expectedHmac[32];
  uint8_t computedHmac[32];
  uint32_t blockLength;
  
  while(reader.hasBytesAvailable) {
    if(reader.readableBytes < 32) {
      KPKCreateError(error, KPKErrorKdbxCorruptedEncryptionStream);
      return nil;
    }
    /* hmac */
    [reader readBytes:expectedHmac length:32];
    /* size */
    if(reader.readableBytes < 4) {
      KPKCreateError(error, KPKErrorKdbxCorruptedEncryptionStream);
      return nil;
    }
    blockLength = CFSwapInt32LittleToHost(reader.read4Bytes);
    if(reader.readableBytes < blockLength) {
      KPKCreateError(error, KPKErrorKdbxCorruptedEncryptionStream);
      return nil;
    }
    
    NSData *hmacKey = [key kpk_hmacKeyForIndex:blockIndex];
    NSData *content = [reader readDataWithLength:blockLength];
    
    CCHmacContext context;
    uint64_t LEblockIndex = CFSwapInt64HostToLittle(blockIndex);
    uint64_t LEblockLength = CFSwapInt32HostToLittle(blockLength);
    CCHmacInit(&context, kCCHmacAlgSHA256, hmacKey.bytes, (CC_LONG)hmacKey.length);
    CCHmacUpdate(&context, &LEblockIndex, 8);
    CCHmacUpdate(&context, &LEblockLength, 4);
    if(content.length > 0) {
      CCHmacUpdate(&context, content.bytes, (CC_LONG)content.length);
    }
    CCHmacFinal(&context, computedHmac);
    if(memcmp(expectedHmac, computedHmac, 32)) {
      KPKCreateError(error, KPKErrorKdbxCorruptedEncryptionStream);
      return nil;
    }
    if(blockLength == 0) {
      return [unhashedData copy]; // return the final data
    }
    [unhashedData appendData:content];
    blockIndex++;
  }
  return nil;
}

- (NSData *)kpk_unhashedSha256Data {
  NSUInteger blockIndex = 0;
  NSUInteger location = 0;
  uint32_t indexBuffer = 0;
  uint32_t bufferLength;
  uint8_t hash[32];
  
  NSMutableData *unhashed = [[NSMutableData alloc] initWithCapacity:self.length];
  NSMutableData *rawData;
  
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
    if(!rawData) {
      rawData = [[NSMutableData alloc] initWithLength:bufferLength];
    }
    rawData.length = bufferLength;
    [self getBytes:rawData.mutableBytes range:NSMakeRange(location, bufferLength)];
    location +=bufferLength;
    
    uint8_t verifyHash[32];
    CC_SHA256(rawData.bytes, bufferLength, verifyHash);
    if(!memcmp(verifyHash, hash, 32)) {
      [unhashed appendBytes:rawData.bytes length:bufferLength];
    }
    if(location == self.length) {
      return unhashed;
    }
  }
}

- (NSData *)kpk_hashedHmacSha256DataWithKey:(NSData *)key error:(NSError *__autoreleasing *)error {
  uint32_t blockSize = 1024*1024;
  uint32_t blockCount = ceil((CGFloat)self.length / (CGFloat)blockSize);
  
  NSMutableData *outputData = [[NSMutableData alloc] initWithCapacity:(self.length + (blockSize + 4) * blockCount)];
  
  KPKDataStreamWriter *writer = [[KPKDataStreamWriter alloc] initWithData:outputData];
  
  uint8_t hmac[32];
  NSUInteger offset = 0;
  for(uint64_t blockIndex = 0; blockIndex <= blockCount; blockIndex++) {
    NSData *hmacKey = [key kpk_hmacKeyForIndex:blockIndex];
    uint32_t blockLength = (uint32_t)MIN(blockSize, self.length - offset);
    
    CCHmacContext context;
    uint64_t LEblockIndex = CFSwapInt64HostToLittle(blockIndex);
    uint64_t LEblockLength = CFSwapInt32HostToLittle(blockLength);
    CCHmacInit(&context, kCCHmacAlgSHA256, hmacKey.bytes, (CC_LONG)hmacKey.length);
    CCHmacUpdate(&context, &LEblockIndex, 8);
    CCHmacUpdate(&context, &LEblockLength, 4);
    if(blockLength > 0) {
      CCHmacUpdate(&context, (self.bytes+offset), (CC_LONG)blockLength);
    }
    CCHmacFinal(&context, hmac);
    
    [writer writeBytes:hmac length:32];
    [writer write4Bytes:blockLength];
    if(blockLength > 0) {
      [writer writeBytes:(self.bytes + offset) length:blockLength];
    }
    offset += blockLength;
  }
  return [outputData copy];
}

- (NSData *)kpk_hashedSha256Data {
  NSUInteger blockSize = 1024*1024;
  uint32_t blockCount = ceil((CGFloat)self.length / (CGFloat)blockSize);
  uint32_t location = 0;
  NSMutableData *outputData = [[NSMutableData alloc] initWithCapacity:blockCount * (blockSize + 33)];
  NSMutableData *sliceData = [[NSMutableData alloc] initWithLength:blockSize];
  uint32_t blockIndex = 0;
  uint32_t blockLength = 0;
  uint8_t hash[32];
  for(; blockIndex < blockCount; blockIndex++) {
    blockLength = MAX(0,MIN((uint32_t)self.length - location, (uint32_t)blockSize));
    sliceData.length = blockLength;
    [self getBytes:sliceData.mutableBytes range:NSMakeRange(location, blockLength)];
    [outputData appendBytes:&blockIndex length:4];
    CC_SHA256(sliceData.bytes, blockLength, hash);
    [outputData appendBytes:hash length:32];
    [outputData appendBytes:&blockLength length:4];
    [outputData appendBytes:sliceData.bytes length:blockLength];
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

@end
