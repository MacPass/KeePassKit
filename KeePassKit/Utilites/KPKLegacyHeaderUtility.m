//
//  KPKLegacyHeaderUtility.m
//  KeePassKit
//
//  Created by Michael Starke on 18.08.13.
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
#import "KPKLegacyHeaderUtility.h"
#import <CommonCrypto/CommonDigest.h>

@implementation KPKLegacyHeaderUtility

+ (NSData *)hashForHeader:(KPKLegacyHeader *)header {
  if(sizeof(*header) != sizeof(KPKLegacyHeader)) {
    return nil; // Data size missmatch;
  }
  uint8_t *buffer = (uint8_t *)header;
  size_t endCount = sizeof((*header).transformationSeed) + sizeof((*header).keyEncRounds);
  size_t startCount = sizeof(KPKLegacyHeader) - sizeof((*header).contentsHash) - endCount;
  uint8_t hash[32];
  
  CC_SHA256_CTX ctx;
  CC_SHA256_Init(&ctx);
  CC_SHA256_Update(&ctx, buffer, (CC_LONG)startCount);
  CC_SHA256_Update(&ctx, buffer + (sizeof(KPKLegacyHeader) - endCount), (CC_LONG)endCount);
  CC_SHA256_Final(hash, &ctx);
  
  return [[NSData alloc] initWithBytes:hash length:sizeof(hash)];
}

@end
