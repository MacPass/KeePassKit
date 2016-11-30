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
#import "KPKUTIs.h"
#import "NSString+KPKHexdata.h"


@implementation NSUUID (KeePassKit)

+ (NSUUID *)nullUUID {
  return [[NSUUID alloc] initWithUUIDString:@"00000000-0000-0000-0000-000000000000"];
}

+ (NSUUID *)uuidWithEncodedString:(NSString *)string {
  return [[NSUUID alloc] initWithEncodedUUIDString:string];
}

- (instancetype)initWithEncodedUUIDString:(NSString *)string {
  NSData *data = [[NSData alloc] initWithBase64EncodedString:string options:NSDataBase64DecodingIgnoreUnknownCharacters];
  self = [self initWithData:data];
  return self;
}

- (instancetype)initWithData:(NSData *)data {
  uuid_t uuidBuffer;
  [data getBytes:&uuidBuffer length:sizeof(uuid_t)];
  self = [self initWithUUIDBytes:uuidBuffer];
  return self;
}

- (instancetype)initWithUndelemittedUUIDString:(NSString *)string {
  if(!string.kpk_isValidHexString) {
    return nil; // invalid characters
  }
  if(string.length != 32) {
    return nil; // invalid lenght
  }
  @autoreleasepool {
    NSString *fixedFormat = [NSString stringWithFormat:@"%@-%@-%@-%@-%@",
                             [string substringWithRange:NSMakeRange(0, 8)],
                             [string substringWithRange:NSMakeRange(8, 4)],
                             [string substringWithRange:NSMakeRange(12, 4)],
                             [string substringWithRange:NSMakeRange(16, 4)],
                             [string substringWithRange:NSMakeRange(20, 12)]
                             ];
    self = [self initWithUUIDString:fixedFormat];
  }
  return self;
}

- (NSString *)encodedString {
  return [self.uuidData base64EncodedStringWithOptions:0];
}

- (NSData *)uuidData {
  uuid_t bytes;
  [self getUUIDBytes:bytes];
  return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

@end

@implementation NSUUID (Pasteboarding)


#pragma mark -
#pragma mark NSPasteboardReading

+ (NSArray *)readableTypesForPasteboard:(NSPasteboard *)pasteboard {
  return @[ KPKUUIDUTI ];
}

+ (NSPasteboardReadingOptions)readingOptionsForType:(NSString *)type pasteboard:(NSPasteboard *)pasteboard {
  NSAssert([type isEqualToString:KPKUUIDUTI], @"Only MPUUID type is supported");
  return NSPasteboardReadingAsKeyedArchive;
}
#pragma mark -
#pragma mark NSPasteboardWriting

- (id)pasteboardPropertyListForType:(NSString *)type {
  NSAssert([type isEqualToString:KPKUUIDUTI], @"Only MPUUID type is supported");
  return [NSKeyedArchiver archivedDataWithRootObject:self];
}

- (NSArray *)writableTypesForPasteboard:(NSPasteboard *)pasteboard {
  return @[ KPKUUIDUTI ];
}

@end
