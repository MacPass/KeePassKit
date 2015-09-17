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

@interface KPKDataStreamReader () {
  NSUInteger _location;
  NSData *_data;
}

@end

@implementation KPKDataStreamReader

- (id)initWithData:(NSData *)data {
  self = [super init];
  if(self) {
    _location = 0;
    _data = data;
  }
  return self;
}
- (NSUInteger)location {
  return _location;
}

- (NSData *)dataWithLength:(NSUInteger)length {
  // FIXME: test for maxsize
  length = MIN([_data length] - _location, length);
  NSData *data = [_data subdataWithRange:NSMakeRange(_location, length)];
  _location += length;
  return data;
}

- (NSString *)stringWithLength:(NSUInteger)length encoding:(NSStringEncoding)encoding {
  char characters[length];
  [self _getBytes:characters length:length];
  return [NSString stringWithCString:characters encoding:encoding];
}

- (void)readBytes:(void *)buffer length:(NSUInteger)length {
  [self _getBytes:buffer length:length];
}

- (uint8_t)readByte {
  uint8_t buffer;
  [self _getBytes:&buffer length:1];
  return buffer;
}

- (uint16_t)read2Bytes {
  uint16_t buffer;
  [self _getBytes:&buffer length:2];
  return buffer;
}

- (uint32_t)read4Bytes {
  uint32_t buffer;
  [self _getBytes:&buffer length:4];
  return buffer;
}

- (uint64_t)read8Bytes {
  uint64_t buffer;
  [self _getBytes:&buffer length:8];
  return buffer;
}

- (NSUInteger)integer {
  NSUInteger integer = 0;
  [self _getBytes:&integer length:sizeof(NSUInteger)];
  return integer;
}

- (void)skipBytes:(NSUInteger)numberOfBytes {
  _location += numberOfBytes;
  _location = MIN([_data length], _location);
}

- (BOOL)reachedEndOfData {
  return (_location == [_data length]);
}

- (NSUInteger)readableBytes {
  if(self.reachedEndOfData) {
    return 0;
  }
  return ([_data length] - _location);
}

- (void)reset {
  _location = 0;
}

- (NSUInteger)_getBytes:(void *)buffer length:(NSUInteger)length {
  NSUInteger maxLength = [_data length] - _location;
  length = MIN(maxLength, length);
  [_data getBytes:buffer range:NSMakeRange(_location, length)];
  _location += length;
  return length;
}


@end
