//
//  KPKData.m
//  KeePassKit
//
//  Created by Michael Starke on 07.04.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import "KPKData.h"
#import "KPKData_Private.h"
#import "NSData+KPKRandom.h"
#import "NSData+KPKXor.h"

@implementation KPKData

+ (BOOL)supportsSecureCoding {
  return YES;
}

- (instancetype)init {
  self = [self initWithData:nil protect:YES];
  return self;
}

- (instancetype)initWithProtectedData:(NSData *)data {
  self = [self initWithData:data protect:YES];
  return self;
}

- (instancetype)initWithUnprotectedData:(NSData *)data {
  self = [self initWithData:data protect:NO];
  return self;
}

- (instancetype)initWithData:(NSData *)data protect:(BOOL)protect {
  self = [super init];
  if(self) {
    _protect = protect;
    self.data = data; // use custom setter to use encoding
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  NSAssert(aDecoder.allowsKeyedCoding, @"Only keyed coder are supported!");
  self = [self init];
  if(self) {
    self->_protect = [aDecoder decodeBoolForKey:NSStringFromSelector(@selector(protect))];
    self.xorPad = [aDecoder decodeObjectOfClass:NSData.class forKey:NSStringFromSelector(@selector(xorPad))];
    self.internalData = [aDecoder decodeObjectOfClass:NSData.class forKey:NSStringFromSelector(@selector(internalData))];
    self.length = [aDecoder decodeIntegerForKey:NSStringFromSelector(@selector(length))];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  NSAssert(aCoder.allowsKeyedCoding, @"Only keyed coder are supported!");
  [aCoder encodeBool:self.protect forKey:NSStringFromSelector(@selector(protect))];
  [aCoder encodeObject:self.internalData forKey:NSStringFromSelector(@selector(internalData))];
  [aCoder encodeObject:self.xorPad forKey:NSStringFromSelector(@selector(xorPad))];
  [aCoder encodeInteger:self.length forKey:NSStringFromSelector(@selector(length))];
}

- (id)copyWithZone:(NSZone *)zone {
  KPKData *copy = [[KPKData alloc] initWithData:self.data protect:self.protect];
  return copy;
}

- (BOOL)isEqual:(id)object {
  if(![object isKindOfClass:KPKData.class]) {
    return NO;
  }
  return [self isEqualToData:object];
}

- (NSUInteger)hash {
  NSUInteger result = 1;
  NSUInteger prime = 149;
  
  result = prime * result + (self.data).hash;
  result = prime * result + self.protect;
  
  return result;
}

- (BOOL)isEqualToData:(KPKData *)data {
  if(self == data) {
    return YES;
  }
  if(self.protect != data.protect) {
    return NO;
  }
  return [self.data isEqualToData:data.data];
}

- (NSUInteger)length {
  /* data is xored so length is preserved */
  return self.internalData.length;
}

- (void)setProtect:(BOOL)protect {
  if(_protect == protect) {
    return;
  }
  NSData *data = self.data;
  _protect = protect;
  self.data = data;
}

- (void)setData:(NSData *)data {
  if(!data || data.length == 0) {
    self.length = 0;
    self.internalData = nil;
    self.xorPad = nil;
    return;
  }
  /* unprotected data */
  if(!self.protect) {
    self.xorPad = nil;
    self.internalData = data;
    return;
  }
  
  if(data.length > self.xorPad.length ) {
    self.xorPad = [NSData kpk_dataWithRandomBytes:data.length];
  }
  self.length = data.length;
  self.internalData = [data kpk_dataXoredWithKey:self.xorPad];
}

- (NSData *)data {
  if(!self.protect) {
    return self.internalData;
  }
  return [[self.internalData kpk_dataXoredWithKey:self.xorPad] copy];
}

- (void)getBytes:(void *)buffer length:(NSUInteger)length {
  [self.data getBytes:buffer length:length];
}

@end
