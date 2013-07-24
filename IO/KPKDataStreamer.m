//
//  KPKDataStreamer.m
//  MacPass
//
//  Created by Michael Starke on 24.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import "KPKDataStreamer.h"

@interface KPKDataStreamer () {
  NSUInteger _location;
  NSData *_data;
}

@end

@implementation KPKDataStreamer

- (id)initWithData:(NSData *)data {
  self = [super init];
  if(self) {
    _location = 0;
    _data = data;
  }
  return self;
}

- (NSData *)dataWithRange:(NSRange)range {
  return [_data subdataWithRange:range];
}

- (NSData *)dataWithLenght:(NSUInteger)lenght {
  return [_data subdataWithRange:NSMakeRange(_location, lenght)];
  _location += lenght;
}


- (uint8)readByte {
  uint8 buffer;
  [_data getBytes:&buffer range:NSMakeRange(_location, 1)];
  _location++;
  return buffer;
}

- (uint16)read2Bytes {
  uint16 buffer;
  [_data getBytes:&buffer range:NSMakeRange(_location, 2)];
  _location++;
  return buffer;
}

- (uint32)read4Bytes {
  uint32 buffer;
  [_data getBytes:&buffer range:NSMakeRange(_location, 4)];
  _location++;
  return buffer;
}

- (void)skipBytes:(NSUInteger)numberOfBytes {
  _location += numberOfBytes;
}

- (BOOL)endOfData {
  return (_location == [_data length] -1);
}

- (void)reset {
  _location = 0;
}

- (NSUInteger)_getbytes:(void *)buffer lenght:(NSUInteger)lenght {
  if([_data length] < _location + lenght) {
    return 0;
  }
  [_data getBytes:buffer range:NSMakeRange(_location, lenght)];
  return lenght;
}


@end
