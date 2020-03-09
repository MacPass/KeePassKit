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
      else if(character >= '2' && character <= '7') {
        value = (character - '2') + 26;
      }
      else {
        break;
      }
      byteValue <<= 5 ;
      byteValue += value;
      bitsDecoded += 5;
    }
    NSUInteger padding = bitsDecoded % 8;
    byteValue >>= padding;
    bitsDecoded -= padding;
    NSMutableData *chunkData = [[NSMutableData alloc] init];
    while(bitsDecoded > 0) {
      uint8_t byte = byteValue & 0xFF;
      // prepend the data to the current working byte!
      [chunkData replaceBytesInRange:NSMakeRange(0, 0) withBytes:&byte length:1];
      byteValue >>= 8;
      bitsDecoded -= 8;
    }
    // apend bytes to final result
    [data appendData:chunkData];
  }
  self = [data copy];
  return self;
}

- (NSString *)base32EncodedString {
  // TODO fix possible endianess bugs on big endian machines!
  NSMutableString *encodedString = [[NSMutableString alloc] init];
  NSArray *alphabet = @[
    @"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H",
    @"I", @"J", @"K", @"L", @"M", @"N", @"O", @"P",
    @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"X",
    @"Y", @"Z", @"2", @"3", @"4", @"5", @"6", @"7"
  ];
  
  
  NSUInteger bytesToEncode = self.length;
  
  NSUInteger byteGroupIndex = 0;
  while(bytesToEncode >= 5) {
    uint8_t byteGroup[5] = { 0, 0, 0, 0, 0 };

    uint8_t encodedValues[8] = { 0, 0, 0, 0, 0, 0, 0, 0 };
    
    [self getBytes:byteGroup range:NSMakeRange(byteGroupIndex, sizeof(uint8_t))];
    [self getBytes:(byteGroup + 1)  range:NSMakeRange(byteGroupIndex + 1, sizeof(uint8_t))];
    [self getBytes:(byteGroup + 2) range:NSMakeRange(byteGroupIndex  + 2, sizeof(uint8_t))];
    [self getBytes:(byteGroup + 3) range:NSMakeRange(byteGroupIndex + 3, sizeof(uint8_t))];
    [self getBytes:(byteGroup + 4) range:NSMakeRange(byteGroupIndex + 4, sizeof(uint8_t))];
    
        
    encodedValues[0] = (byteGroup[0] >> 3);
    encodedValues[1] = (0b00000111 & byteGroup[0]) << 2;
    encodedValues[1] |= byteGroup[1] >> 6;
    encodedValues[2] = (0b00111110 & byteGroup[1]) >> 1;
    encodedValues[3] = (0b00000001 & byteGroup[1]) << 4;
    encodedValues[3] |= byteGroup[2] >> 4;
    encodedValues[4] = (0b00001111 & byteGroup[2]) << 1;
    encodedValues[4] |= byteGroup[3] >> 7;
    encodedValues[5] = (0b01111100 & byteGroup[3]) >> 2;
    encodedValues[6] = (0b00000011 & byteGroup[3]) << 3 ;
    encodedValues[6] |= byteGroup[4] >> 5;
    encodedValues[7] = (0b00011111 & byteGroup[4]);
     
    bytesToEncode -= 5;
    byteGroupIndex += 5;
    
    for(NSUInteger index = 0; index < 8; index++) {
      [encodedString appendString:alphabet[encodedValues[index]]];
    }
  }
  switch(bytesToEncode) {
    case 1:
      break;
    case 2:
      break;
    case 3:
      break;
    case 4:
      break;
    default:
      break;
  }
  // encode last block!

  
  return [encodedString copy];;
}

@end
