//
//  NSData+Keyfile.m
//  MacPass
//
//  Created by Michael Starke on 12.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import "NSData+Keyfile.h"
#import <CommonCrypto/CommonCrypto.h>


@implementation NSData (Keyfile)

+ (NSData *)dataWithWithContentsOfKeyFile:(NSURL *)url error:(NSError *__autoreleasing *)error {
  // Open the keyfile
  NSData *fileData = [NSData dataWithContentsOfURL:url
                                           options:(NSDataReadingUncached|NSDataReadingMappedIfSafe)
                                             error:error];
  if(error) {
    return nil;
  }
  
  if(!fileData) {
    return nil;
  }
  if([fileData length] == 32) {
    return fileData; // Loading of a 32 bit binary file succeded;
  }
  NSData *decordedData = nil;
  if ([fileData length] == 64) {
    error = nil;
    NSString *hexstring = [[NSString alloc] initWithData:fileData encoding:NSUTF8StringEncoding];
    if(!error && hexstring != nil) {
      decordedData = [self _keyDataWithHexString:hexstring];
    }
  }
  if(!decordedData) {
    // The hex encoded file failed to load, so try and hash the file
    decordedData = [self _keyDataFromHash:fileData];
  }
  return decordedData;
}

+ (NSData *)_keyDataWithHexString:(NSString *)hexString {
  uint8_t buffer[32];
  
  if(hexString == nil) {
    return nil;
  }
  if([hexString length] != 64) {
    return nil; // No valid lenght found
  }
  BOOL scanOk = YES;
  @autoreleasepool {
    for(NSUInteger iIndex = 0; iIndex < 32; iIndex++) {
      NSString *split = [hexString substringWithRange:NSMakeRange(iIndex * 2, 2)];
      NSScanner * scanner = [NSScanner scannerWithString:split];
      uint32_t integer = 0;
      if(![scanner scanHexInt:&integer]) {
        scanOk = NO;
        break;
      }
      buffer[iIndex] = (uint8_t)integer;
    }
  }
  if(!scanOk) {
    return nil; // Hex scanning failed
  }
  return [NSData dataWithBytes:buffer length:32];
}

+ (NSData *)_keyDataFromHash:(NSData *)fileData {
  uint8_t buffer[32];
  NSData *chunk;
  
  CC_SHA256_CTX ctx;
  CC_SHA256_Init(&ctx);
  @autoreleasepool {
    const NSUInteger chunkSize = 2048;
    for(NSUInteger iIndex = 0; iIndex < [fileData length]; iIndex += chunkSize) {
      NSUInteger maxChunkLenght = MIN(fileData.length - iIndex, chunkSize);
      chunk = [fileData subdataWithRange:NSMakeRange(iIndex, maxChunkLenght)];
      CC_SHA256_Update(&ctx, chunk.bytes, (CC_LONG)chunk.length);
    }
  }
  CC_SHA256_Final(buffer, &ctx);
  
  return [NSData dataWithBytes:buffer length:32];
}



@end
