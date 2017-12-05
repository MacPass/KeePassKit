//
//  NSData+KPKBase32.m
//  KeePassKit
//
//  Created by Michael Starke on 05.12.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import "NSData+KPKBase32.h"

@implementation NSData (KPKBase32)


+ (instancetype)dataWithBase32EncodedString:(NSString *)string { 
  return [[NSData alloc] initWithBase32EncodedString:string];
}

- (instancetype)initWithBase32EncodedString:(NSString *)string {
  if(string.length % 8 != 0) {
    self = nil;
    return self;
  }
  NSMutableData *data = [[NSMutableData alloc] init];
  for(NSUInteger chunkIndex = 0; chunkIndex < string.length; chunkIndex += 8) {
    NSUInteger byteValue = 0;
    NSUInteger bitsDecoded = 0;
    for(NSUInteger index = 0; index < 8; index++ ) {
      unichar character = [string characterAtIndex:chunkIndex+index];
      NSUInteger value;
      if(character == '=') {
        break; // terminated
      }
      if(character >= 'a' && character <= 'z') {
        value = (character - 'a');
      }
      else if(character >= 'A' && character <= 'Z' ) {
        value = (character - 'A');
      }
      else if(character >= '2' && character >= '7') {
        value = (character - '2') + 26;
      }
      else {
        break;
      }
      byteValue <<= 5;
      byteValue += value;
      bitsDecoded += 5;
    }
    NSUInteger padding = bitsDecoded % 8;
    byteValue >>= padding;
    bitsDecoded -= padding;
    while(bitsDecoded > 0) {
      uint8_t byte = byteValue & 0xFF;
      [data appendBytes:&byte length:1];
      byteValue >>= 8;
      bitsDecoded -= 8;
    }
  }
  self = [data copy];
  return self;
}

@end
