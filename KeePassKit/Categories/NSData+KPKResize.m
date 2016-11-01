//
//  NSData+KPKResize.m
//  KeePassKit
//
//  Created by Michael Starke on 01/11/2016.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "NSData+KPKResize.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation NSData (KPKResize)

- (NSData *)deriveKeyWithLength:(NSUInteger)length {
  return [self deriveKeyWithLength:length fromRange:NSMakeRange(0, self.length)];
}

- (NSData *)deriveKeyWithLength:(NSUInteger)length fromRange:(NSRange)range {
  
  NSAssert((range.location + range.length) <= self.length, @"");
  
  if(length == 0) {
    return [NSData data]; // empty data!
  }
  const uint8_t *byteOffset = (self.bytes + range.location);
  if(length <= 32) {
    uint8_t sha256Hash[32];
    CC_SHA256(byteOffset, (CC_LONG)range.length, sha256Hash);
    return [NSData dataWithBytes:sha256Hash length:32];
  }
  uint8_t sha512Hash[64];
  CC_SHA512(byteOffset, (CC_LONG)range.length, sha512Hash);
  
  if(length <= 64 ) {
    return [NSData dataWithBytes:sha512Hash length:length];
  }
  
  uint8_t output[length];
  NSUInteger position = 0;
  uint64_t count = 0;
  while(position < length) {
    uint8_t hmac[32];
    CCHmac(kCCHmacAlgSHA256, &count, sizeof(uint64_t), sha512Hash, 64, hmac);
    NSUInteger copyLength = MIN(length - position, 32);
    memcpy(output+position, hmac, copyLength);
    position += copyLength;
    count++;
  }
  
  return [NSData dataWithBytes:output length:length];
}
@end
