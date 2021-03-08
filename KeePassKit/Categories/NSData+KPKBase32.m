//
//  NSData+KPKBase32.m
//  KeePassKit
//
//  Created by Michael Starke on 05.12.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import "NSData+KPKBase32.h"

typedef NS_ENUM(NSUInteger, KPKBase32AlphabetType) {
  KPKBase32Alphabet,
  KPKBase32HexAlphabet
};

NSArray<NSString *> *alphabetForType(KPKBase32AlphabetType type) {
  switch (type) {
    case KPKBase32Alphabet:
      return @[
        @"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H",
        @"I", @"J", @"K", @"L", @"M", @"N", @"O", @"P",
        @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"X",
        @"Y", @"Z", @"2", @"3", @"4", @"5", @"6", @"7"
      ];
    case KPKBase32HexAlphabet:
      return @[
        @"0", @"1", @"2", @"3", @"4", @"5", @"6", @"7",
        @"8", @"9", @"A", @"B", @"C", @"D", @"E", @"F",
        @"G", @"H", @"I", @"J", @"K", @"L", @"M", @"N",
        @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"V"
      ];
    default:
      return @[];
  }
}

NSUInteger valueForCharacterInAlphabet(unichar character, KPKBase32AlphabetType type, BOOL *ok) {
  if(ok != NULL) {
    *ok = YES;
  }
  switch(type) {
    case KPKBase32Alphabet:
      if(character >= 'a' && character <= 'z') {
        return (character - 'a');
      }
      else if(character >= 'A' && character <= 'Z' ) {
        return (character - 'A');
      }
      else if(character >= '2' && character <= '7') {
        return (character - '2') + 26;
      }
      if(ok != NULL) {
        *ok = NO;
      }
      return 0;
    case KPKBase32HexAlphabet:
      if(character >= '0' && character <= '9') {
        return (character - '0');
      }
      else if(character >= 'a' && character <= 'v' ) {
        return (character - 'a') + 10;
      }
      else if(character >= 'A' && character <= 'V') {
        return (character - 'A') + 10;
      }
      return 0;
    default:
      if(ok != NULL) {
        *ok = NO;
      }
      return 0;
  }
}

@implementation NSData (KPKBase32)

+ (instancetype)dataWithBase32EncodedString:(NSString *)string { 
  return [[NSData alloc] initWithBase32EncodedString:string];
}

+ (instancetype)dataWithBase32HexEncodedString:(NSString *)string {
  return [[NSData alloc] initWithBase32HexEncodedString:string];
}

- (instancetype)initWithBase32EncodedString:(NSString *)string {
  return [self _initWithBase32EncodedString:string alphabetType:KPKBase32Alphabet];
}

- (instancetype)initWithBase32HexEncodedString:(NSString *)string {
  return [self _initWithBase32EncodedString:string alphabetType:KPKBase32HexAlphabet];
}

- (instancetype)_initWithBase32EncodedString:(NSString *)string alphabetType:(KPKBase32AlphabetType)type {
  /* return null data */
  if(string.length == 0) {
    self = NSData.data;
    return self;
  }
  static NSDictionary *paddingDict;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    paddingDict = @{ @(0) : @"",
                     @(2) : @"======",
                     @(4) : @"====",
                     @(5) : @"===",
                     @(7) : @"=" };
  });
  
  NSString *missingPadding = paddingDict[@(string.length % 8)];
  if(!missingPadding) {
    /* FIXME: Raise Excpetion since this is no valid Base32 code at all */
    self = NSData.data;
    return self;
  }
  /* add missing padding */
  string = [string stringByAppendingString:missingPadding];
  
  NSMutableData *data = [[NSMutableData alloc] init];
  for(NSUInteger chunkIndex = 0; chunkIndex < string.length; chunkIndex += 8) {
    NSUInteger byteValue = 0;
    NSUInteger bitsDecoded = 0;
    for(NSUInteger index = 0; index < 8; index++ ) {
      unichar character = [string characterAtIndex:chunkIndex+index];
      if(character == '=') {
        break; // terminated
      }
      BOOL valueOK;
      NSUInteger value = valueForCharacterInAlphabet(character, type, &valueOK);
      if(!valueOK) {
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

- (NSString *)base32EncodedStringWithOptions:(KPKBase32EncodingOptions)options {
  KPKBase32AlphabetType type = (options & KPKBase32EncodingOptionHexadecimalAlphabet) ? KPKBase32HexAlphabet : KPKBase32Alphabet;
  // TODO fix possible endianess bugs on big endian machines!
  NSMutableString *encodedString = [[NSMutableString alloc] init];
  
  NSArray *alphabet = alphabetForType(type);
  NSAssert(alphabet.count == 32, @"Internal inconsitency. Base32 alphabet is mallformed!");
  
  NSUInteger bytesToEncode = self.length;
  NSUInteger byteGroupIndex = 0;
  
  while(bytesToEncode >= 5) {
    uint8_t byteGroup[5] = { 0 };
    
    [self getBytes:byteGroup range:NSMakeRange(byteGroupIndex, 5 * sizeof(uint8_t))];
    
    uint8_t characterValues[8] = { 0 };
    characterValues[0] = (byteGroup[0] >> 3);
    characterValues[1] = (0b00000111 & byteGroup[0]) << 2 | byteGroup[1] >> 6;
    characterValues[2] = (0b00111110 & byteGroup[1]) >> 1;
    characterValues[3] = (0b00000001 & byteGroup[1]) << 4 | byteGroup[2] >> 4;
    characterValues[4] = (0b00001111 & byteGroup[2]) << 1 | byteGroup[3] >> 7;
    characterValues[5] = (0b01111100 & byteGroup[3]) >> 2;
    characterValues[6] = (0b00000011 & byteGroup[3]) << 3 | byteGroup[4] >> 5;
    characterValues[7] = (0b00011111 & byteGroup[4]);
    
    bytesToEncode -= 5;
    byteGroupIndex += 5;
    
    for(NSUInteger index = 0; index < 8; index++) {
      [encodedString appendString:alphabet[characterValues[index]]];
    }
  }
  if(bytesToEncode > 0) {
    uint8_t bytes[5] = { 0 };
    [self getBytes:bytes range:NSMakeRange(byteGroupIndex, bytesToEncode * sizeof(uint8_t))];
    uint8_t characterValues[7] = { 0 };
    static uint8_t paddingCount[] = { 0, 6, 4, 3, 1 };
    uint8_t bitCount[] = { 0, 2, 4, 5, 7 };
    switch(bytesToEncode) {
      case 4:
        // 32 bit
        characterValues[6] = (0b00000011 & bytes[3]) << 3 | bytes[4] >> 5;
        characterValues[5] = (0b01111100 & bytes[3]) >> 2;
      case 3:
        // 24 bit
        characterValues[4] = (0b00001111 & bytes[2]) << 1 | bytes[3] >> 7;
      case 2:
        // 16 bit
        characterValues[3] = (0b00000001 & bytes[1]) << 4 | bytes[2] >> 4;
        characterValues[2] = (0b00111110 & bytes[1]) >> 1;
      case 1:
        // 8 bit
        characterValues[1] = (0b00000111 & bytes[0]) << 2 | bytes[1] >> 6;
        characterValues[0] = (bytes[0] >> 3);
      default:
        break;
    }
    for(NSUInteger index = 0; index < bitCount[bytesToEncode]; index++) {
      [encodedString appendString:alphabet[characterValues[index]]];
    }
    if(!(options & KPKBase32EncodingOptionNoPadding)) {
      uint8_t pad = paddingCount[bytesToEncode];
      while(pad--) {
        [encodedString appendString:@"="];
      }
    }
  }
  return [encodedString copy];;
}

@end
