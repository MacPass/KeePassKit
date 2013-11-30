//
//  NSMutableData+Base64.m
//  MacPass
//
//  Created by Michael Starke on 25.06.13.
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
//  Based on the answer
//  http://stackoverflow.com/questions/11386876/how-to-encode-and-decode-files-as-base64-in-cocoa-objective-c
//  by user http://stackoverflow.com/users/200321/denis2342
//

#import "NSMutableData+Base64.h"
#include <Security/Security.h>

typedef NS_ENUM(NSUInteger, KPKTransformMethod) {
  KPKEncode,
  KPKDecode
};

static NSData *base64helper(NSData *input, KPKTransformMethod method)
{
  NSData *output = nil;
  SecTransformRef transformRef;
  switch (method) {
    case KPKEncode:
      transformRef = SecEncodeTransformCreate(kSecBase64Encoding, NULL);
      break;
    case KPKDecode:
      transformRef = SecDecodeTransformCreate(kSecBase64Encoding, NULL);
      break;
      
    default:
      return nil;
  }
  if (SecTransformSetAttribute(transformRef, kSecTransformInputAttributeName, (__bridge CFTypeRef)(input), NULL))
    output = (NSData *)CFBridgingRelease(SecTransformExecute(transformRef, NULL));
  
  CFRelease(transformRef);
  
  return output;
}

@implementation NSMutableData (Base64)


+ (NSMutableData *)mutableDataWithBase64EncodedData:(NSData *)inputData {
  return [[NSMutableData alloc] initWithData:base64helper(inputData, KPKEncode)];
}

+ (NSMutableData *)mutableDataWithBase64DecodedData:(NSData *)inputData {
  return [[NSMutableData  alloc] initWithData:base64helper(inputData, KPKDecode)];
}

- (void)encodeBase64 {
  [self setData:base64helper(self, KPKEncode)];
}

- (void)decodeBase64 {
  [self setData:base64helper(self, KPKDecode)];
}

+ (NSData *)dataFromBase64EncodedString:(NSString *)string encoding:(NSStringEncoding)encoding {
  NSMutableData *mutableData = [[string dataUsingEncoding:encoding] mutableCopy];
  [mutableData decodeBase64];
  return mutableData;
}



@end
