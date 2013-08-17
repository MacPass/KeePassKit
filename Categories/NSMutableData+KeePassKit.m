//
//  NSMutableData+KeePassKit.m
//  MacPass
//
//  Created by Michael Starke on 17.08.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import "NSMutableData+KeePassKit.h"

@implementation NSMutableData (KeePassKit)

- (void)xorWithKey:(NSData *)key {
  if([key length] < [self length]) {
    NSAssert(NO, @"Key has to be at least as long as data");
  }
  uint8_t *dataPointer = [self mutableBytes];
  const uint8_t *keyPointer = [key bytes];
  for(NSUInteger byteIndex = 0; byteIndex < [self length]; byteIndex++) {
    dataPointer[byteIndex] = dataPointer[byteIndex] ^ keyPointer[byteIndex];
  }
}

@end
