//
//  NSString+Hexdata.m
//  MacPass
//
//  Created by Michael Starke on 14.07.13.
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
//  Based on http://stackoverflow.com/questions/2501033/nsstring-hex-to-bytes
//  by http://stackoverflow.com/users/136819/zyphrax
//
#import "NSString+KPKHexdata.h"

@implementation NSString (KPKHexdata)

NSCharacterSet *KPKHexCharacterSet(void) {
  static dispatch_once_t onceToken;
  static NSCharacterSet *set;
  dispatch_once(&onceToken, ^{
     set = [NSCharacterSet characterSetWithCharactersInString:@"0123456789AaBbCcDdEeFf"].invertedSet;
  });
  return set;
}

+ (NSString *)kpk_hexstringFromData:(NSData *)data {
  NSMutableString *hexString = [[NSMutableString alloc] initWithCapacity:data.length * 2];
  uint8_t byte;
  for(NSInteger byteIndex = 0; byteIndex < data.length; byteIndex++) {
    [data getBytes:&byte range:NSMakeRange(byteIndex, 1)];
    [hexString appendFormat:@"%02x", byte];
  }
  return hexString;
}

- (NSData *)kpk_dataFromHexString {
  if(!self.kpk_isValidHexString) {
    return nil;
  }
  NSString *string = [self copy];
  if([string hasPrefix:@"0x"]) {
    string = [self substringFromIndex:2];
  }
  if(string.length % 2 == 1) {
    string = [NSString stringWithFormat:@"0%@", string];
  }
  if(!string.kpk_isValidHexString) {
    return nil;
  }
  const char *chars = string.UTF8String;
  NSUInteger index = 0;
  NSUInteger length = string.length;
  
  /* FIXME: use fixed buffer no mutable data since we know length */
  
  NSMutableData *data = [NSMutableData dataWithCapacity:length / 2];
  char byteChars[3] = {'\0','\0','\0'};
  NSUInteger wholeByte;
  
  while (index < length) {
    byteChars[0] = chars[index++];
    byteChars[1] = chars[index++];
    
    wholeByte = strtoul(byteChars, NULL, 16);
    [data appendBytes:&wholeByte length:1];
  }
  
  return [data copy];
}

- (BOOL)kpk_isValidHexString {
  NSRange range = [self rangeOfCharacterFromSet:KPKHexCharacterSet()];
  return (NSNotFound == range.location) && (0 == range.length);
}

@end
