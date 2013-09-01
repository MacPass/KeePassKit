//
//  NSString+Hexdata.m
//  MacPass
//
//  Created by Michael Starke on 14.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//
//  Based on http://stackoverflow.com/questions/2501033/nsstring-hex-to-bytes
//  by http://stackoverflow.com/users/136819/zyphrax
//
#import "NSString+Hexdata.h"

@implementation NSString (Hexdata)

+ (NSString *)hexstringFromData:(NSData *)data {
  NSMutableString *hexString = [[NSMutableString alloc] initWithCapacity:[data length] * 2];
  uint8_t byte;
  for(NSInteger byteIndex = 0; byteIndex < [data length]; byteIndex++) {
    [data getBytes:&byte range:NSMakeRange(byteIndex, 1)];
    [hexString appendFormat:@"%02x", byte];
  }
  return hexString;
}

- (NSData *)dataFromHexString {
  NSString *string = [self copy];
  if([string hasPrefix:@"0x"]) {
    string = [self substringFromIndex:2];
  }
  NSCharacterSet *hexCharactes = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789AaBbCcDdEeFf"] invertedSet];
  BOOL isValid = (NSNotFound == [string rangeOfCharacterFromSet:hexCharactes].location);
  if(!isValid) {
    return nil;
  }
  const char *chars = [string UTF8String];
  NSUInteger index = 0;
  NSUInteger length = [string length];
  
  NSMutableData *data = [NSMutableData dataWithCapacity:length / 2];
  char byteChars[3] = {'\0','\0','\0'};
  NSUInteger wholeByte;
  
  while (index < length) {
    byteChars[0] = chars[index++];
    byteChars[1] = chars[index++];
    
    wholeByte = strtoul(byteChars, NULL, 16);
    [data appendBytes:&wholeByte length:1];
  }
  
  return data;
}

@end
