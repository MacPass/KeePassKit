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

- (NSUInteger)integer {
  return 0;
}

- (NSUInteger)integerFromIndex:(NSInteger)index {
  return 0;
}

- (NSUInteger)integerFromRange:(NSRange)range {
  return 0;
}

@end

@implementation KPKOTPGenerator

+ (NSData *)HMACOTPWithKey:(NSData *)key counter:(uint64_t)counter {
  // ensure we use big endian
  uint64_t beCounter = CFSwapInt64HostToBig(counter);
  uint8_t mac[CC_SHA1_DIGEST_LENGTH];
  CCHmac(kCCHmacAlgSHA1, key.bytes, key.length, &beCounter, sizeof(uint64_t), mac);
  
  /* offset ist lowest 4 bit on last byte */
  uint8_t offset = (mac[19] & 0xf);
  
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
