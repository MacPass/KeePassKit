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
#import "KPKBinary_Private.h"
#import "NSData+KPKGzip.h"

@implementation KPKBinary

+ (BOOL)supportsSecureCoding {
  return YES;
}

- (instancetype)initWithName:(NSString *)name data:(NSData *)data {
  self = [super init];
  if(self) {
    _name = [name copy];
    _data = [data copy];
    _protectInMemory = NO;
  }
  return self;
}

- (instancetype)init {
  self = [self initWithName:nil data:nil];
  return self;
}

- (instancetype)initWithName:(NSString *)name string:(NSString *)value compressed:(BOOL)compressed {
  NSData *data = [self _dataForEncodedString:value compressed:compressed];
  self = [self initWithName:name data:data];
  return self;
}

- (instancetype)initWithContentsOfURL:(NSURL *)url {
  if(url) {
    NSError *error = nil;
    NSDictionary *resourceKeys = [url resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];
    if([resourceKeys[ NSURLIsDirectoryKey ] boolValue] == YES ) {
      self = nil;
      return nil; // no valid url
    }
    self = [self initWithName:url.lastPathComponent data:[NSData dataWithContentsOfURL:url options:0 error:&error]];
    return self;
  }
  else {
    self = nil;
    return self;
  }
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  NSString *name = [aDecoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(name))];
  NSData *data = [aDecoder decodeObjectOfClass:[NSData class] forKey:NSStringFromSelector(@selector(data))];
  BOOL protected = [aDecoder decodeBoolForKey:NSStringFromSelector(@selector(protectInMemory))];
  self = [self initWithName:name data:data];
  self.protectInMemory = protected;
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:self.name forKey:NSStringFromSelector(@selector(name))];
  [aCoder encodeObject:self.data forKey:NSStringFromSelector(@selector(data))];
  [aCoder encodeBool:self.protectInMemory forKey:NSStringFromSelector(@selector(protectInMemory))];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  KPKBinary *copy = [[KPKBinary allocWithZone:zone] init];
  if(copy) {
    copy.name = _name;
    copy.data = _data;
    copy.protectInMemory = _protectInMemory;
  }
  return copy;
}

- (BOOL)isEqual:(id)object {
  if(self == object) {
    return YES;
  }
  if(![object isKindOfClass:[KPKBinary class]]) {
    return NO;
  }
  return [self isEqualtoBinary:object];
}

- (BOOL)isEqualtoBinary:(KPKBinary *)binary {
  return [self.name isEqualToString:binary.name] && [self.data isEqualToData:binary.data] && (self.protectInMemory == binary.protectInMemory);
}

- (NSUInteger)hash {
  NSUInteger result = 1;
  NSUInteger prime = 37;
  
  result = prime * result + (self.name).hash;
  result = prime * result + (self.data).hash;
  result = prime * result + self.protectInMemory;
  
  return result;
}

- (BOOL)saveToLocation:(NSURL *)location error:(NSError **)error {
  return [self.data writeToURL:location options:0 error:error];
}

- (NSData *)_dataForEncodedString:(NSString *)string compressed:(BOOL)compressed {
  NSData *data = [[NSData alloc] initWithBase64EncodedString:string options:NSDataBase64DecodingIgnoreUnknownCharacters];
  if(data && compressed) {
    return data.kpk_gzipDeflated;
  }
  return data;
}

- (NSString *)encodedStringUsingCompression:(BOOL)compress {
  if(compress) {
    return [self.data.kpk_gzipDeflated base64EncodedStringWithOptions:0];
  }
  return [self.data base64EncodedStringWithOptions:0];
}

@end
