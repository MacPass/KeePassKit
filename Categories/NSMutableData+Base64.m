//
//  NSMutableData+Base64.m
//  MacPass
//
//  Created by Michael Starke on 25.06.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//
//  Based on the answer
//  http://stackoverflow.com/questions/11386876/how-to-encode-and-decode-files-as-base64-in-cocoa-objective-c
//  by user http://stackoverflow.com/users/200321/denis2342
//

#import "NSMutableData+Base64.h"
#include <Security/Security.h>

static NSData *base64helper(NSData *input, SecTransformRef transform)
{
  NSData *output = nil;
  
  if (!transform)
    return nil;
  
  if (SecTransformSetAttribute(transform, kSecTransformInputAttributeName, (__bridge CFTypeRef)(input), NULL))
    output = (NSData *)CFBridgingRelease(SecTransformExecute(transform, NULL));
  
  CFRelease(transform);
  
  return output;
}

@implementation NSMutableData (Base64)


+ (NSMutableData *)mutableDataWithBase64EncodedData:(NSData *)inputData {
  SecTransformRef transform = SecEncodeTransformCreate(kSecBase64Encoding, NULL);

  return [[NSMutableData alloc] initWithData:base64helper(inputData, transform)];
}

+ (NSMutableData *)mutableDataWithBase64DecodedData:(NSData *)inputData {
  SecTransformRef transform = SecDecodeTransformCreate(kSecBase64Encoding, NULL);
  return [[NSMutableData  alloc] initWithData:base64helper(inputData, transform)];
}

- (void)encodeBase64 {
  SecTransformRef transform = SecEncodeTransformCreate(kSecBase64Encoding, NULL);
  [self setData:base64helper(self, transform)];
}

- (void)decodeBase64 {
  SecTransformRef transform = SecDecodeTransformCreate(kSecBase64Encoding, NULL);
  [self setData:base64helper(self, transform)];
}

+ (NSData *)dataFromBase64EncodedString:(NSString *)string encoding:(NSStringEncoding)encoding {
  NSMutableData *mutableData = [[string dataUsingEncoding:encoding] mutableCopy];
  [mutableData decodeBase64];
  return mutableData;
}



@end
