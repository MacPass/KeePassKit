//
//  KPKBinaryData.m
//  KeePassKit
//
//  Created by Michael Starke on 12.07.13.
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


#import "KPKBinary.h"
#import "NSData+Gzip.h"
#import "NSMutableData+Base64.h"

@implementation KPKBinary

- (id)initWithName:(NSString *)name value:(NSString *)value compressed:(BOOL)compressed {
  self = [super init];
  if(self) {
    _name = [name copy];
    _data = [self _dataForEncodedString:value compressed:compressed];
  }
  return self;
}

- (id)initWithContentsOfURL:(NSURL *)url {
  self = [super init];
  if(self) {
    if(url) {
      NSError *error = nil;
      _data = [NSData dataWithContentsOfURL:url options:0 error:&error];
      if(!_data) {
        self = nil;
        return self;
      }
      _name = [url lastPathComponent];
    }
  }
  return self;
}

- (id)copyWithZone:(NSZone *)zone {
  KPKBinary *copy = [[KPKBinary allocWithZone:zone] init];
  if(copy) {
    copy.name = _name;
    copy.data = _data;
  }
  return copy;
}

- (NSData *)_dataForEncodedString:(NSString *)string compressed:(BOOL)compressed {
  NSData *data = [NSMutableData mutableDataWithBase64EncodedData:[string dataUsingEncoding:NSUTF8StringEncoding]];
  if(data && compressed) {
    data = [data gzipInflate];
  }
  return data;
}

- (NSString *)encodedStringUsingCompression:(BOOL)compress {
  NSData *data;
  if(compress) {
    data = [self.data gzipDeflate];
  }
  else {
    data = self.data;
  }
  return [[NSString alloc] initWithData:[NSMutableData mutableDataWithBase64EncodedData:data] encoding:NSUTF8StringEncoding];
}

@end
