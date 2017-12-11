//
//  KPKOTP.m
//  KeePassKit
//
//  Created by Michael Starke on 09.12.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import "KPKOTP.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation KPKOTP

+ (NSData *)HMACOTPWithKey:(NSData *)key counter:(uint64_t)counter error:(NSError *__autoreleasing *)error {
  // ensure we use big endian
  uint64_t beCounter = CFSwapInt64HostToBig(counter);
  uint8_t mac[CC_SHA1_DIGEST_LENGTH];
  CCHmac(kCCHmacAlgMD5, key.bytes, key.length, &beCounter, sizeof(uint64_t), mac);
  /*
   DT(String) // String = String[0]...String[19]
   Let OffsetBits be the low-order 4 bits of String[19]
   Offset = StToNum(OffsetBits) // 0 <= OffSet <= 15
   Let P = String[OffSet]...String[OffSet+3]
   Return the Last 31 bits of P
  */
  return [NSData dataWithBytes:mac length:CC_SHA1_DIGEST_LENGTH];
  
}
+ (NSData *)TOTPWithKey:(NSData *)key time:(NSTimeInterval)time slice:(NSUInteger)slice base:(NSUInteger)base error:(NSError *__autoreleasing *)error {
  uint64_t counter = floor((time - base) / slice);
  return [self HMACOTPWithKey:key counter:counter error:error];
}

@end
