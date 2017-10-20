//
//  KPKDataStreamer.m
//  KeePassKit
//
//  Created by Michael Starke on 24.07.13.
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

#import "KPKDataStreamReader.h"

@interface KPKDataStreamReader ()

@property (nonatomic) NSUInteger offset;
@property (nonatomic, copy) NSData *data;

@end

@implementation KPKDataStreamReader

- (instancetype)initWithData:(NSData *)data {
  self = [super init];
  if(self) {
    _offset = 0;
    _data = [data copy];
  }
  return self;
}

- (NSData *)readDataWithLength:(NSUInteger)length {
  // FIXME: test for maxsize
  if(length == 0) {
    return nil;
  }
  length = MIN(self.data.length - self.offset, length);
  NSData *data = [self.data subdataWithRange:NSMakeRange(self.offset, length)];
  self.offset += length;
  return data;
}
- (NSString *)readStringFromNullTerminatedCStringWithLength:(NSUInteger)length encoding:(NSStringEncoding)encoding {
  char characters[length];
  [self _getBytes:characters length:length];
  return [NSString stringWithCString:characters encoding:encoding];
}

- (NSString *)readStringFromBytesWithLength:(NSUInteger)length encoding:(NSStringEncoding)encoding {
  return [[NSString alloc] initWithData:[self readDataWithLength:length] encoding:encoding];
}

- (void)readBytes:(void *)buffer length:(NSUInteger)length {
  [self _getBytes:buffer length:length];
}

- (uint8_t)readByte {
  uint8_t buffer = 0;
  if(self.readableBytes < sizeof(uint8_t)) {
    return buffer;
  }
  [self _getBytes:&buffer length:sizeof(uint8_t)];
  return buffer;
}

- (uint16_t)read2Bytes {
  uint16_t buffer = 0;
  if(self.readableBytes < sizeof(uint16_t)) {
    return buffer;
  }
  [self _getBytes:&buffer length:sizeof(uint16_t)];
  return buffer;
}

- (uint32_t)read4Bytes {
  uint32_t buffer = 0;
  if(self.readableBytes < sizeof(uint32_t)) {
    return buffer;
  }
  [self _getBytes:&buffer length:sizeof(uint32_t)];
  return buffer;
}

- (uint64_t)read8Bytes {
  uint64_t buffer = 0;
  if(self.readableBytes < sizeof(uint64_t)) {
    return 0;
  }
  [self _getBytes:&buffer length:sizeof(uint64_t)];
  return buffer;
}

- (NSUInteger)readInteger {
  NSUInteger integer = 0;
  if(self.readableBytes < sizeof(NSUInteger)) {
    return integer;
  }
  [self _getBytes:&integer length:sizeof(NSUInteger)];
  return integer;
}

- (void)skipBytes:(NSUInteger)numberOfBytes {
  self.offset += numberOfBytes;
  self.offset = MIN(self.data.length, self.offset);
}

- (BOOL)hasBytesAvailable {
  return (self.offset < self.data.length);
}

- (NSUInteger)readableBytes {
  if(!self.hasBytesAvailable) {
    return 0;
  }
  return (self.data.length - self.offset);
}

- (NSUInteger)_getBytes:(void *)buffer length:(NSUInteger)length {
  NSUInteger maxLength = self.data.length - self.offset;
  length = MIN(maxLength, MAX(0,length));
  [self.data getBytes:buffer range:NSMakeRange(self.offset, length)];
  self.offset += length;
  return length;
}


@end
