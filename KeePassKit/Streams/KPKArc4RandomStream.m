//
//  KPKArc4RandomStream.m
//  KeePassKit
//
//  Created by Qiang Yu on 2/28/10 for KeePass2
//  Copyright 2010 Qiang Yu. All rights reserved.
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

#import "KPKArc4RandomStream.h"
#import <Security/Security.h>
#import <Security/SecRandom.h>

#define ARC_BUFFER_SIZE 0x3FF

@interface KPKArc4RandomStream () {
  uint8_t _state[256];
  uint32_t _i;
  uint32_t _j;
  
  uint8_t _buffer[ARC_BUFFER_SIZE]; //the size must be >= 512
  uint32_t _index;
}
@end

@implementation KPKArc4RandomStream

- (instancetype)init {
  uint8_t buffer[256];
  
  __unused int ret = SecRandomCopyBytes(kSecRandomDefault, sizeof(buffer), buffer);
  NSAssert(ret == 0, @"Unable to copy secure bytes!");

  return [self initWithKeyData:[NSData dataWithBytes:buffer length:sizeof(buffer)]];
}

- (instancetype)initWithKeyData:(NSData*)key {
  
  
  self = [super init];
  if (self) {
    const uint8_t *bytes = key.bytes;
    NSUInteger length = key.length;
    
    _i = 0;
    _j = 0;
    
    uint32_t index = 0;
    for (uint32_t w = 0; w < 256; w++) {
      _state[w] = (uint8_t)(w & 0xff);
    }
    
    int i = 0, j = 0;
    uint8_t t = 0;
    
    for (uint32_t w = 0; w < 256; w++) {
      j += ((_state[w] + bytes[index]));
      j &= 0xff;
      
      t = _state[i];
      _state[i] = _state[j];
      _state[j] = t;
      
      ++index;
      if (index >= length) {
        index = 0;
      }
    }
    
    [self updateState];
    _index = 512; //skip first 512 bytes
  }
  return self;
}

- (void)updateState {
  uint8_t t = 0;
  for (uint32_t w = 0; w < ARC_BUFFER_SIZE; w++) {
    ++_i;
    _i &= 0xff;
    _j += _state[_i];
    _j &= 0xff;
    
    t = _state[_i];
    _state[_i] = _state[_j];
    _state[_j] = (uint8_t) (t & 0xff);
    
    t = (uint8_t) (_state[_i] + _state[_j]);
    _buffer[w] = _state[t & 0xff];
  }
}

- (uint8_t)getByte {
  uint8_t value;
  
  if (_index == 0) {
    [self updateState];
  }
  
  value = _buffer[_index];
  
  _index = (_index + 1) & ARC_BUFFER_SIZE;
  
  return value;
}

@end
