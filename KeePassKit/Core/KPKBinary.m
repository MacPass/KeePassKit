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

@dynamic protect;
@dynamic data;

+ (BOOL)supportsSecureCoding {
  return YES;
}

- (instancetype)initWithName:(NSString *)name data:(NSData *)data {
  self = [super init];
  if(self) {
    _name = [name copy];
    _internalData = [[KPKData alloc] initWithUnprotectedData:data];
  }
  return self;
}

- (instancetype)init {
  self = [self initWithName:nil data:nil];
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
  NSString *name = [aDecoder decodeObjectOfClass:NSString.class forKey:NSStringFromSelector(@selector(name))];
  NSData *data = [aDecoder decodeObjectOfClass:NSData.class forKey:NSStringFromSelector(@selector(data))];
  BOOL protected = [aDecoder decodeBoolForKey:NSStringFromSelector(@selector(protect))];
  self = [self initWithName:name data:data];
  self.protect = protected;
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:self.name forKey:NSStringFromSelector(@selector(name))];
  [aCoder encodeObject:self.data forKey:NSStringFromSelector(@selector(data))];
  [aCoder encodeBool:self.protect forKey:NSStringFromSelector(@selector(protect))];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  KPKBinary *copy = [[KPKBinary allocWithZone:zone] init];
  if(copy) {
    copy.name = _name;
    copy.internalData = _internalData;
  }
  return copy;
}

- (BOOL)isEqual:(id)object {
  if(self == object) {
    return YES;
  }
  if(![object isKindOfClass:KPKBinary.class]) {
    return NO;
  }
  return [self isEqualtoBinary:object];
}

- (BOOL)isEqualtoBinary:(KPKBinary *)binary {
  return [self.name isEqualToString:binary.name] && [self.data isEqualToData:binary.data] && (self.protect == binary.protect);
}

- (NSUInteger)hash {
  NSUInteger result = 1;
  NSUInteger prime = 37;
  
  result = prime * result + (self.name).hash;
  result = prime * result + (self.data).hash;
  result = prime * result + self.protect;
  
  return result;
}

- (NSData *)data {
  return self.internalData.data;
}

- (void)setData:(NSData *)data {
  self.internalData.data = data;
}

- (BOOL)protect {
  return self.internalData.protect;
}

- (void)setProtect:(BOOL)protect {
  self.internalData.protect = protect;
}

- (BOOL)saveToLocation:(NSURL *)location error:(NSError *__autoreleasing *)error {
  return [self.data writeToURL:location options:0 error:error];
}

@end
