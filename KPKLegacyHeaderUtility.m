//
//  KPKLegacyHeaderUtility.m
//  MacPass
//
//  Created by Michael Starke on 18.08.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import "KPKLegacyHeaderUtility.h"
#import <CommonCrypto/CommonDigest.h>

@implementation KPKLegacyHeaderUtility

+ (NSData *)hashForHeader:(KPKLegacyHeader *)header {
  if(sizeof(*header) != sizeof(KPKLegacyHeader)) {
    return nil; // Data size missmatch;
  }
  size_t endCount = sizeof((*header).masterSeed2) + sizeof((*header).keyEncRounds);
  size_t startCount = sizeof(KPKLegacyHeader) - sizeof((*header).contentsHash) - endCount;
  uint8_t hash[32];
  
  CC_SHA256_CTX ctx;
  CC_SHA256_Init(&ctx);
  CC_SHA256_Update(&ctx, header, (CC_LONG)startCount);
  CC_SHA256_Update(&ctx, header + (sizeof(KPKLegacyHeader) - endCount), (CC_LONG)endCount);
  CC_SHA256_Final(hash, &ctx);
  
  return [NSData dataWithBytes:hash length:sizeof(hash)];
}

@end
