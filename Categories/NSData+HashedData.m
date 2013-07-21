//
//  NSData+HashedData.m
//  MacPass
//
//  Created by Michael Starke on 21.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import "NSData+HashedData.h"
#import <CommonCrypto/CommonDigest.h>


@implementation NSData (HashedData)

- (NSData *)unhashedData {
  NSUInteger blockIndex = 0;
  NSUInteger location = 0;
  uint32_t indexBuffer = 0;
  uint32_t bufferLength;
  uint8_t hash[32];

  NSMutableData *unhashed = [[NSMutableData alloc] initWithCapacity:[self length]];
  
  while(true) {

    if([self length] < location + 4) {
      /* There needs to be at lease one block index */
      return nil;
    }
    /* Read the block index */
    [self getBytes:&indexBuffer range:NSMakeRange(location, 4)];
    location += 4;
    
    if(indexBuffer != blockIndex) {
      /* Block index is invalid */
      return nil;
    }
    blockIndex++;
    
    if([self length] < location + 32) {
      /* At least one has has to be there */
      return nil;
    }
    [self getBytes:hash range:NSMakeRange(location, 32)];
    location += 32;
    
    if([self length] < location + 4) {
      /* we need to be able to read the lenght of the data */
      return nil;
    }
    [self getBytes:&bufferLength range:NSMakeRange(location, 4)];
    location += 4;

    if (bufferLength == 0) {
      for (int i = 0; i < 32; ++i) {
        if (hash[i] != 0) {
          return nil;
        }
      }
      return unhashed;
    }
    if([self length] < location + bufferLength) {
      return nil;
    }
    uint8_t *rawData = malloc(sizeof(uint8_t)*bufferLength);
    [self getBytes:rawData range:NSMakeRange(location, bufferLength)];
    location +=bufferLength;
    
    uint8_t verifyHash[32];
    CC_SHA256(rawData, bufferLength, verifyHash);
    if(!memcmp(verifyHash, hash, 32)) {
      [unhashed appendBytes:rawData length:bufferLength];
    }
    free(rawData);
    if(location == [self length]) {
      return  unhashed;
    }
  }
}

- (NSData *)hashedData {
  return nil;
}

@end
