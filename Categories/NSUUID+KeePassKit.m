//
//  NSUUID+KeePassKit.m
//  KeePassKit
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

#import "NSUUID+KeePassKit.h"
#import "NSMutableData+Base64.h"

static NSUUID *aesUUID = nil;

@implementation NSUUID (KeePassKit)

+ (NSUUID *)nullUUID {
  return [[NSUUID alloc] initWithUUIDString:@"00000000-0000-0000-0000-000000000000"];
}

+ (NSUUID *)AESUUID {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    aesUUID = [[NSUUID alloc] initWithUUIDString:@"31C1F2E6-BF71-4350-BE58-05216AFC5AFF"];
  });
  return aesUUID;
}

+ (NSUUID *)uuidWithEncodedString:(NSString *)string {
  return [[NSUUID alloc] initWithEncodedUUIDString:string];
}

- (id)initWithEncodedUUIDString:(NSString *)string {
  NSMutableData *data = [[string dataUsingEncoding:NSUTF8StringEncoding] mutableCopy];
  [data decodeBase64];
  self = [self initWithData:data];
  return self;
}

- (id)initWithData:(NSData *)data {
  uuid_t uuidBuffer;
  [data getBytes:&uuidBuffer length:sizeof(uuid_t)];
  self = [self initWithUUIDBytes:uuidBuffer];
  return self;
}

- (NSString *)encodedString {
  NSData *data = [NSMutableData mutableDataWithBase64EncodedData:[self uuidData]];
  return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (NSData *)uuidData {
  uuid_t bytes;
  [self getUUIDBytes:bytes];
  return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

@end
