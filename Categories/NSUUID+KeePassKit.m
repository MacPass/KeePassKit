//
//  NSUUID+KeePassKit.m
//  KeePassKit
//
//  Created by Michael Starke on 25.06.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import "NSUUID+KeePassKit.h"
#import "NSMutableData+Base64.h"

static NSUUID *aesUUID = nil;

@implementation NSUUID (KeePassKit)

+ (NSUUID *)nullUUID {
  return [[NSUUID alloc] initWithUUIDString:@"00000000000000000000000000000000"];
}

+ (NSUUID *)AESUUID {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    aesUUID = [[NSUUID alloc] initWithUUIDString:@"31C1F2E6BF714350BE5805216AFC5AFF"];
  });
  return aesUUID;
}

+ (NSUUID *)uuidWithEncodedString:(NSString *)string {
  return [[NSUUID alloc] initWithEncodedUUIDString:string];
}

- (id)initWithEncodedUUIDString:(NSString *)string {
  NSData *stringData = [string dataUsingEncoding:NSUTF8StringEncoding];
  NSData *decodedData = [NSMutableData mutableDataWithBase64DecodedData:stringData];
  NSString *uuidString = [[NSString alloc] initWithData:decodedData encoding:NSUTF8StringEncoding];
  self = [self initWithUUIDString:uuidString];
  return self;
}

- (NSString *)encodedString {
  NSData *data = [NSMutableData mutableDataWithBase64EncodedData:[self getUUIDData]];
  return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (NSData *)getUUIDData {
  uint8_t *bytes = NULL;
  [self getUUIDBytes:bytes];
  
  return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

@end
