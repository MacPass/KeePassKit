//
//  NSMutableData+KeePassKit.m
//  KeePassKit
//
//  Created by Michael Starke on 17.08.13.
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

#import "NSData+KPKXor.h"

@implementation NSData (KPKXor)

static const NSUInteger kKPKStrideSize = 256;

- (NSData *)kpk_dataXoredWithKey:(NSData *)key {
  if(key.length < self.length) {
    NSAssert(NO, @"Key has to be at least as long as data");
    return nil;
  }
  if(self.length == 0) {
    return nil;
  }
  
  NSMutableData *buffer = [self mutableCopy];
  const uint8_t *keyPointer = key.bytes;
  uint8_t *dataPointer = buffer.mutableBytes;
  // TODO: check if this can benefit from dispatch_apply
  NSUInteger count = self.length / kKPKStrideSize;
  dispatch_apply(count, DISPATCH_APPLY_AUTO, ^(size_t stride) {
    for(NSUInteger byteIndex = 0; byteIndex < kKPKStrideSize; byteIndex++) {
      NSUInteger actualIndex = stride * kKPKStrideSize + byteIndex;
      dataPointer[actualIndex] ^= keyPointer[actualIndex];
    }
  });
  /* update last unaligend chunk */
  for(NSUInteger byteIndex = count * kKPKStrideSize; byteIndex < self.length; byteIndex++) {
    dataPointer[byteIndex] ^= keyPointer[byteIndex];
  }
  return [buffer copy];
}

@end
