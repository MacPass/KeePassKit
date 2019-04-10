//
//  KPKOTP.m
//  KeePassKit
//
//  Created by Michael Starke on 09.12.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import "KPKOTPGenerator.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation NSData (KPKIntegerConversion)

- (NSUInteger)unsignedInteger {
  /*
   HMAC data is interpreted as big endian
   */
  NSUInteger number = 0;
  [self getBytes:&number length:MIN(self.length, sizeof(NSUInteger))];
  
  /*
   convert big endian to host
   if conversion took place, we need to shift by the size
   */
#if __LP64__ || NS_BUILD_32_LIKE_64
  NSUInteger beNumber = (NSUInteger)CFSwapInt64BigToHost(number);
#else
  NSUInteger beNumber = (NSUInteger)CFSwapInt32BigToHost(number);
#endif

  if(beNumber != number) {
    beNumber >>= (8 * (sizeof(NSUInteger) - self.length));
  }
  return beNumber;
}

- (NSUInteger)unsignedIntegerFromIndex:(NSInteger)index {
  NSAssert(index < self.length, @"Index out of bounds!");
  return [self unsignedIntegerFromRange:NSMakeRange(index, MIN(index + sizeof(NSUInteger), self.length - index))];
}

- (NSUInteger)unsignedIntegerFromRange:(NSRange)range {
  NSAssert(range.location + range.length < self.length, @"Range out of bounds");
  NSUInteger number = 0;
  /* FIXME shift to LSB */
  [self getBytes:&number range:range];
  return number;
}

@end

@implementation KPKOTPGenerator

+ (NSData *)HMACOTPWithKey:(NSData *)key counter:(uint64_t)counter {
  // ensure we use big endian
  uint64_t beCounter = CFSwapInt64HostToBig(counter);
  uint8_t mac[CC_SHA1_DIGEST_LENGTH];
  CCHmac(kCCHmacAlgSHA1, key.bytes, key.length, &beCounter, sizeof(uint64_t), mac);
  
  /* offset is lowest 4 bit on last byte */
  uint8_t offset = (mac[CC_SHA1_DIGEST_LENGTH - 1] & 0xf);
  
  uint8_t otp[4];
  otp[0] = mac[offset] & 0x7f;
  otp[1] = mac[offset + 1];
  otp[2] = mac[offset + 2];
  otp[3] = mac[offset + 3];

  return [NSData dataWithBytes:&otp length:sizeof(uint32_t)];
  
}
+ (NSData *)TOTPWithKey:(NSData *)key time:(NSTimeInterval)time slice:(NSUInteger)slice base:(NSUInteger)base {
  uint64_t counter = floor((time - base) / slice);
  return [self HMACOTPWithKey:key counter:counter];
}

@end
